# Changelog

## 2026-04-22 13:34:25 +07:00

### Notification Filter UI

- Moved the notification filter toggle below the `Mark all read` row.
- Replaced text labels with icons:
  eye icon for all notifications,
  eye-slash icon for unread-only notifications.

## 2026-04-22 13:30:50 +07:00

### Notification Filter UI

- Replaced the plain unread text button with a compact segmented-style `All` / `Unread` toggle.
- Added selected-state styling with a white active chip, teal label, and subtle shadow.

## 2026-04-22 13:28:33 +07:00

### Notification Filter

- Added a compact notification panel toggle to show only unread notifications.
- Added local `_notificationsUnreadOnly` state for switching between all notifications and unread-only notifications.
- Updated notification list rendering to use the filtered visible notification list.

## 2026-04-22 13:20:34 +07:00

### Notification Read State

- Added frontend integration for `POST /notifications/{notification_id}/read`.
- Added frontend integration for `POST /notifications/mark-all-read`.
- Added notification id extraction from `notification_id`, `id`, or `doc_id`.
- Added unread detection based on `status == UNREAD`.
- Added card tap behavior to mark a single unread notification as read.
- Updated case-id notification navigation to mark the notification read before opening case detail.
- Added a `Mark all read` action in the notification panel header when unread notifications exist.
- Updated local notification list state after successful read operations so badges/status update without requiring a full refetch.

## 2026-04-22 10:19:17 +07:00

### Assessment Validation UX

- Added assessment-form validation state for required nurse review and SINBAD fields.
- Added enum mismatch detection for nurse review dropdown fields.
- Added red visual highlighting around invalid nurse review fields and SINBAD cards.
- Added field keys and scroll guidance so Submit Assessment scrolls to the first invalid field.
- Updated the Fill-in Answers review section to expand automatically when an invalid nurse-review field needs attention.
- Updated invalid field interactions so selecting or typing into a highlighted field clears its error state.

### Verification

- Attempted `dart format` on touched Dart files, but it timed out in this environment.
- Attempted focused `dart analyze` on touched Dart files, but it timed out in this environment.
- Performed targeted source inspection after the timeout.

## 2026-04-21 15:32:53 +07:00

### Notification Device Registration

- Updated startup FCM token registration to call `POST /notification-devices/register`.
- Updated the registration payload to send:
  `user_id: nurse-app`,
  `role: NURSE`,
  `fcm_token`,
  `platform`,
  `device_id`.
- Added terminal debug logging before the registration call:
  `notification-devices/register payload: ...`.
- Updated `push_notifications.md` to document the new endpoint and payload shape.

### Agent Notes

- Recorded that `agent/changelog.md` and `agent/decision.md` should be updated as part of future development changes in this repo.

## 2026-04-21 15:26:38 +07:00

### Follow-up Analysis Flow

- Updated the follow-up assessment sequence so `/analyze-wound` must complete successfully before `/analyze-healing` is called.
- Added a 1 minute wait after successful `/analyze-wound` before calling `/analyze-healing`.
- Increased the `/analyze-healing` frontend timeout to 3 minutes.
- Updated the loading overlay text to show phase-specific progress:
  `Analyzing wound`,
  `Comparing current wound with previous records`.
- Confirmed that `/analyze-healing` is skipped when `/analyze-wound` fails or does not return the expected AI structure.

### Push Notification Debugging

- Confirmed Android Firebase app id and `google-services.json` package name match:
  `com.foster.foster_ulcer_ai_nurse_app`.
- Added Android core library desugaring required by `flutter_local_notifications`.
- Fixed `flutter_local_notifications` API usage for the resolved newer package version by switching `initialize` and `show` calls to named parameters.
- Fixed Firebase startup timing by making `FirebaseMessaging.instance` initialize only after `Firebase.initializeApp()`.
- Temporarily attempted to comment out push-notification runtime wiring for debugging, then restored it after user requested undo.

### Backend / Gemini Clarification

- Checked backend Gemini client setup and confirmed the backend currently uses the global Gemini Developer API via API key:
  `genai.Client(api_key=...)`.
- Confirmed it is not currently using a regional Vertex AI endpoint.

### Case Detail Page

- Traced the SINBAD score near WIfI to `analysis.classifications.SINBAD.total`.
- Traced treatment plan and task list JSON sources.
- Updated the Case Detail Task List to use only `current_treatment_plan.plan_tasks`.
- Removed task-list fallback usage from:
  record-level `treatment_plan.plan_tasks`,
  record-level `task_list`,
  `current_task_list`.

## 2026-04-20 13:46:48 +07:00

### Push Notification Module

- Designed and implemented the app-side push notification module for background and closed-app delivery.
- Added Firebase dependencies: `firebase_core`, `firebase_messaging`, and `flutter_local_notifications`.
- Added `lib/services/notification_service.dart` to initialize Firebase, request permissions, listen for foreground/background/open events, and manage the FCM token lifecycle.
- Updated `lib/main.dart` to initialize the push notification service before the app starts.
- Updated `lib/widgets/main_navigation_screen.dart` to:
  add push listeners,
  sync the device token to the backend,
  refresh `/nurse-notifications`,
  open the notification panel when a push is tapped.
- Added backend registration endpoint usage: `POST /device-notifications/register`.
- Updated Android setup with:
  Google services Gradle plugin,
  `POST_NOTIFICATIONS` permission,
  default notification channel metadata.
- Updated iOS setup with `remote-notification` background mode.
- Added `push_notifications.md` documenting:
  delivery flow,
  backend payload contract,
  remaining Firebase and backend setup.

### Verification

- Ran `flutter pub get` successfully after adding the new dependencies.
- `flutter analyze` and `dart format` did not complete in this environment because the commands timed out.
