# Decision Record

## 2026-04-21: Add FCM on top of Firestore notifications

### Context

The frontend can already receive Firebase Cloud Messaging notifications. The backend already creates notification documents in shared Firestore collections for doctor and nurse workflows, but it did not send push notifications when those workflow events occurred.

### Decision

Use a hybrid notification design:

- Keep writing notification documents to Firestore for persistence and app-side history.
- Send FCM push immediately after the backend creates the notification document.
- Store FCM device tokens in Firestore with:
  - `user_id`
  - `role`
  - `fcm_token`
  - active/inactive state
- Route push notifications by existing workflow ownership fields:
  - `assigned_doctor` for doctor-targeted push
  - `created_by_nurse` for nurse-targeted push

### Rationale

- Firestore remains the source of truth even if push delivery fails.
- FCM adds background and terminated-app alerts without changing the existing notification feed design.
- Using the existing doctor and nurse IDs avoids introducing a new user-mapping layer in this step.
- Token deactivation on unregistered-device errors prevents repeated failed sends.

### Consequences

- Frontend must register the current device token with the backend after login or token refresh.
- Frontend should unregister or replace tokens on logout, reinstall, or token rotation.
- Shared collections `all_doctor` and `all_nurse` still exist, so this is not yet a per-user inbox model.
- Correct push targeting depends on frontend `user_id` values matching backend workflow IDs such as `DR-001` and `NURSE-001`.

### Follow-up

- Add API documentation for the new token registration endpoints.
- Consider per-user notification queries instead of only shared role feeds.
- Consider unread tracking and delivery/open analytics if notification UX becomes more important.

## 2026-04-21: Broadcast role FCM to separate doctor and nurse apps

### Context

Doctor and nurse clients are separate apps. Notifications should be broadcast by app role instead of by individual clinician identity.

### Decision

- Broadcast doctor-side FCM notifications to every active token registered with role `DOCTOR`.
- Broadcast nurse-side FCM notifications to every active token registered with role `NURSE`.
- Continue storing doctor notification history in the shared `all_doctor` Firestore feed.
- Continue storing nurse notification history in the shared `all_nurse` Firestore feed.

### Rationale

- Separate apps make role-based broadcast practical because doctor tokens and nurse tokens are registered under different roles.
- The doctor workflow expects all doctors using the doctor app to be notified when a case is ready for doctor review.
- The nurse app should receive nurse-side alerts as a whole app role, not as per-user push targeting.
- Removing per-user FCM targeting reduces dependency on `assigned_doctor` and `created_by_nurse` matching device registration user IDs.

### Consequences

- Frontend registration must use the correct role:
  - doctor app registers `role = "DOCTOR"`
  - nurse app registers `role = "NURSE"`
- Any device incorrectly registered as `DOCTOR` will receive doctor broadcasts.
- Any device incorrectly registered as `NURSE` will receive nurse broadcasts.
- Stored Firestore doctor notifications remain shared, not per-doctor.
- Stored Firestore nurse notifications remain shared, not per-nurse.

## 2026-04-21: Use treatment plan tasks as the task source of truth

### Context

Task data was duplicated across multiple Firestore fields:

- `cases/{case_id}.current_treatment_plan.plan_tasks`
- `cases/{case_id}.current_task_list`
- `cases/{case_id}/records/{record_id}.treatment_plan.plan_tasks`
- `cases/{case_id}/records/{record_id}.task_list`
- `cases/{case_id}/records/{record_id}/plan_versions/{plan_id}/tasks/{task_id}`

This caused drift because some routes updated one copy but not the others.

### Decision

- Use `current_treatment_plan.plan_tasks` as the case-level source of truth.
- Use `records/{record_id}.treatment_plan.plan_tasks` as the record-level source of truth.
- Keep plan-version task documents for task subcollection detail/history.
- Deprecate and delete duplicated snapshot fields on new writes:
  - `current_task_list`
  - `task_list`
- Keep `task_list` only as a backward-compatible input/read fallback for older payloads and older Firestore documents.

### Rationale

- A single canonical task list removes sync bugs between `current_task_list` and `current_treatment_plan.plan_tasks`.
- Treatment plans already own `plan_tasks`, so task data belongs under treatment plans.
- Backward-compatible fallback avoids breaking old data immediately.

### Consequences

- Frontend should read tasks from `current_treatment_plan.plan_tasks`.
- Frontend should send tasks under `treatment_plan.plan_tasks`.
- New backend writes will remove deprecated task snapshot fields from current case/record documents.
- Historical Firestore documents may still contain old fields until touched by a new write or cleaned by migration.

## 2026-04-21: Track task source

### Context

The workflow needs to distinguish AI-created tasks from doctor-created or doctor-edited tasks.

### Decision

- Add optional `source` to each task.
- Default task `source` to `AI` when tasks are created by `/send-to-doctor`.
- Default task `source` to `Doctor` when tasks are created by `/doctor-review`.
- Preserve explicit task source values sent by the frontend.

### Consequences

- Existing tasks without `source` can still be read.
- New tasks should include or receive a source value.
- `source` is stored in treatment plan tasks and task subcollection documents.
