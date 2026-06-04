# Changelog

## 2026-04-21

- Added backend FCM push delivery on top of the existing Firestore notification feed.
- Added device token registration and unregister endpoints:
  - `POST /notification-devices/register`
  - `POST /notification-devices/unregister`
- Added token storage in Firestore `notification_devices`, keyed by a hash of the FCM token.
- Added backend push sending for existing notification events:
  - nurse sends case to doctor
  - doctor sends reviewed plan back to nurse
  - request-close notifies doctor
  - healing analysis ready notifies doctor
- Added automatic deactivation of unregistered FCM tokens after Firebase send failures.
- Preserved the current Firestore notification collections `all_doctor` and `all_nurse` as the source of truth for notification history.
- Changed doctor-side FCM delivery to broadcast to every active device registered with role `DOCTOR`, matching the separate doctor app / nurse app deployment model.
- Changed nurse-side FCM delivery to broadcast to every active device registered with role `NURSE`, matching the separate doctor app / nurse app deployment model.
- Added support for `source` on individual plan tasks.
- Defaulted task `source` to `AI` when tasks are created by `/send-to-doctor`.
- Defaulted task `source` to `Doctor` when tasks are created by `/doctor-review`, while preserving any explicit task source sent by the doctor app.
- Deprecated duplicated task snapshots:
  - `cases/{case_id}.current_task_list`
  - `cases/{case_id}/records/{record_id}.task_list`
- Made `current_treatment_plan.plan_tasks` the case-level task source of truth.
- Made `records/{record_id}.treatment_plan.plan_tasks` the record-level task source of truth.
- Updated `/task_update` to sync task changes into both the case current treatment plan and current record treatment plan, while deleting deprecated task snapshot fields.
- Tightened `/task_update` record sync so `records/{record_id}.treatment_plan.plan_tasks` is rebuilt from the updated task array whenever task status/details are changed.
- Added `test_gemini_api.py` to send `Hello Gemini` through the existing backend Gemini client and print the response.
- Added `test_notification.py` to send a manual FCM test notification to active Android device tokens, with optional `DOCTOR` or `NURSE` role filtering.
- Updated project Markdown documentation (`API.md`, `API_contract.md`, `test.md`, and `workflow.md`) to reflect role-wide FCM broadcasts, notification device registration, task `source`, and `current_treatment_plan.plan_tasks` as the task source of truth.
- Added notification read-state endpoints:
  - `POST /notifications/{notification_id}/read`
  - `POST /notifications/mark-all-read`

## 2026-04-28

- Simplified the preferred `/doctor-review` request contract to use:
  - top-level `analysis`
  - top-level `treatment_plan`
  - optional `ai_result_edit_flag`
  - optional `treatment_plan_edit_flag`
- Kept legacy `payload` support in `/doctor-review` for backward compatibility during client migration.
- Confirmed that doctor add, delete, and reorder of plan tasks only happens through `/doctor-review`.
- Added and documented `order_index` on plan tasks and plan-version task documents.
- Updated project Markdown documentation to reflect the clean `/doctor-review` contract and task ordering rules.

## 2026-05-07

- Added a dedicated no-wound workflow endpoint:
  - `POST /no-wound-assessment`
- Changed the no-wound request contract to take `case_id` in the JSON body instead of the URL path.
- Added backend validation for the no-wound flow:
  - `status` must be `COMPLETED`
  - `flow_type` must be `NO_WOUND_PRESENT`
  - `wound_present` must be `false`
  - `wound_detail` must be `null`
  - required `sinbad` fields: `site`, `ischemia`, `neuropathy`, `infection`, `area`, `depth`
- Added request models for the no-wound workflow, including support for `meta.submitted_at` and `meta.submitted_by_role`.
- Extended `sinbad` payload support to accept optional `total`.
- Implemented no-wound record/case updates without image analysis, wound-detail review, analysis version creation, or plan version creation.
- Changed the no-wound flow to complete immediately without doctor-review notification.
- Set the case and target record to `COMPLETED`, stamped `completed_at`, cleared current analysis/plan pointers, and returned:
  - `status`
  - `case_id`
  - `record_id`
  - `next_status`
- Changed `POST /create_appointment` so it updates only the treatment plan status to `APPOINTMENT` and preserves existing individual task statuses.
