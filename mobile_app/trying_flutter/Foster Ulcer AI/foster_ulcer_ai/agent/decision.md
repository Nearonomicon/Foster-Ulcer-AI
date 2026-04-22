# Development Decisions

## 2026-04-22 13:34:25 +07:00

### Notification Filter UI

- We decided the notification filter toggle should sit below the `Mark all read` action instead of sharing the title row.
- We decided to use icons instead of text for the filter:
  eye for all notifications,
  eye-slash for unread-only notifications.

## 2026-04-22 13:30:50 +07:00

### Notification Filter UI

- We decided the unread filter should look like a segmented toggle instead of a plain text button.
- We decided the active filter should be visually obvious through chip styling rather than text color only.

## 2026-04-22 13:28:33 +07:00

### Notification Filter

- We decided the notification panel should include a small toggle for unread-only viewing.
- We decided the unread filter should be local UI state and not require a new backend query.

## 2026-04-22 13:20:34 +07:00

### Notification Read State

- We decided unread notifications should be marked read when the nurse taps the notification card.
- We decided case-detail navigation from a notification should mark that notification read first.
- We decided the notification panel should include a `Mark all read` action when unread notifications exist.
- We decided the app should optimistically update local notification state after successful backend read calls instead of requiring a refetch.
- We decided to support multiple backend id field names for notification records: `notification_id`, `id`, and `doc_id`.

## 2026-04-22 10:19:17 +07:00

### Assessment Validation UX

- We decided Submit Assessment should guide the nurse to the exact missing or invalid input instead of only showing a snackbar.
- We decided invalid nurse review fields and SINBAD cards should be highlighted in red.
- We decided the Fill-in Answers review section should expand automatically when a nurse-review field inside it is invalid.
- We decided enum mismatches from AI/transcription prefill should be treated as actionable validation errors and require the nurse to choose a valid option.
- We decided the submit payload should remain unchanged; this work only improves client-side validation and guidance.

## 2026-04-21 15:32:53 +07:00

### Notification Device Registration

- We decided the mobile app should register FCM tokens on startup and token refresh using `POST /notification-devices/register`.
- We decided the app should send `fcm_token` instead of the previous `device_token` field.
- We decided the app should identify this client as `user_id: nurse-app` and `role: NURSE` until a fuller authenticated nurse identity is wired in.
- We decided to print the outgoing registration payload in the Flutter terminal to make push-notification debugging easier.

### Agent Notes

- We decided future development changes should update both `agent/changelog.md` and `agent/decision.md`.

## 2026-04-21 15:26:38 +07:00

### Follow-up Analysis

- We decided the follow-up flow should remain sequential:
  `/analyze-wound` first,
  then `/analyze-healing`.
- We decided `/analyze-healing` should only run after `/analyze-wound` succeeds and returns valid parsed AI output.
- We decided to wait 1 minute between successful `/analyze-wound` and `/analyze-healing`.
- We decided to allow `/analyze-healing` up to 3 minutes before timing out on the Flutter side.
- We decided to show user-facing progress text for each major phase instead of a generic `Analyzing...` message.

### Push Notification Debugging

- We decided to keep push notification code enabled after briefly testing a comment-out approach.
- We decided `google-services.json` should stay local and be gitignored in normal development.
- We decided Android Firebase package id must match the Gradle `applicationId`.
- We decided manual Android Firebase BoM and Analytics dependencies are not required for the Flutter push-notification setup.
- We decided the app should initialize push notifications after `runApp()` so Firebase setup cannot block first render.

### Gemini API

- We confirmed the backend currently uses the global Gemini Developer API, not Vertex AI regional endpoints.
- We decided the current `RESOURCE_EXHAUSTED` issue should be treated as backend quota/rate/concurrency pressure, not a Flutter sequencing bug.
- We identified retry, queueing, or migration to Vertex AI regional endpoints as future backend improvements.

### Case Detail Data Sources

- We decided the Case Detail Task List should use only `current_treatment_plan.plan_tasks`.
- We decided not to use record-level `task_list`, record-level `treatment_plan.plan_tasks`, or `current_task_list` as fallbacks for the visible Task List.
- We confirmed the SINBAD score pill near WIfI is sourced from `analysis.classifications.SINBAD.total`.

## 2026-04-20 13:46:48 +07:00

### Push Notifications

- We decided to use Firebase Cloud Messaging for push delivery when the app is backgrounded or terminated.
- We decided to keep the existing `/nurse-notifications` REST flow as the in-app notification source of truth, with push acting as the delivery trigger.
- We decided to show foreground messages through `flutter_local_notifications` so the user still sees an alert while actively using the app.
- We decided to register each device with the backend through `POST /device-notifications/register`.
- We decided that each push payload should include routing metadata such as `type`, `case_id`, `task_id`, and `patient_id`.
- We decided that tapping a push should reopen the app into the existing notifications panel first, instead of introducing a new deep-link destination immediately.
- We decided to add platform support on both Android and iOS now, even if Firebase credential files are added later.
- We decided to fail safely if Firebase is not configured yet, so the app can still launch without crashing during development.
- We decided to use a placeholder nurse identifier for token registration until a real authenticated user/session model is wired into the app.

### Deferred Work

- We have not yet added `android/app/google-services.json`.
- We have not yet added `ios/Runner/GoogleService-Info.plist`.
- We have not yet implemented the backend token-registration endpoint and outbound FCM sender.
- We have not yet replace the placeholder nurse id with the real logged-in nurse id.
- We have not yet add direct deep-link routing into case/task detail pages from push taps.
