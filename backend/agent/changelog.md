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
- Added `test_gemini_api.py` to send `Hello Gemini` through the existing backend Gemini client and print the response.
