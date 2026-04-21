# Changelog

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
