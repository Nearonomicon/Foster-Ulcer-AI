# Changelog

## 2026-04-23 14:02:00 +07:00

### Wound Photo Preview Before Fill-in

- Changed wound camera capture flow so taking or browsing a wound photo no longer calls `/analyze-fillin` immediately.
- Added a full-screen wound photo preview on the camera page with `Retake` and `Use Photo` actions.
- Added confirmation handling so `/analyze-fillin` runs only after the user accepts the selected photo.
- Added retake logic to resume the live wound camera stream after dismissing the preview.
- Discard unconfirmed wound photos when leaving the camera page.

## 2026-04-23 13:39:00 +07:00

### Loading Overlay AI Label

- Changed loading overlay title text from `GEMINI CLOUD` to `AI`.
- Updated all current analysis/loading flows that reuse `_analysisTitle` to show `AI` instead of `GEMINI`.

## 2026-04-23 13:34:17 +07:00

### Appointment and Close Success Navigation

- Added a shared success handler that shows a success message and opens the dashboard Cases tab.
- Updated successful Create Appointment flow to navigate to the refreshed case list after showing the appointment success message.
- Updated successful Request Close flow to navigate to the refreshed case list after showing the close-request success message.
- Ensured Request Close navigation includes the `REQUEST_CLOSE` case-status filter so the updated case remains visible.
- Attempted `dart format` on touched Dart files, but it timed out in this environment.

## 2026-04-23 13:10:00 +07:00

### Shorebird Remote Updates

- Installed and configured Shorebird for remote app upgrades when needed.
- Added `shorebird.yaml` with the app id used by Shorebird update services.
- Left Shorebird automatic background updates enabled by default.

## 2026-04-23 10:43:52 +07:00

### Launcher Logo Source Update

- Switched launcher icon source from `pic/app_logo.png` to `pic/app_logo_bg.png`.
- Verified `pic/app_logo_bg.png` is `1024x1024`.
- Regenerated Android launcher mipmap PNGs from `pic/app_logo_bg.png`.
- Regenerated iOS AppIcon PNGs from `pic/app_logo_bg.png`.

## 2026-04-23 10:21:58 +07:00

### App Name and Launcher Logo

- Changed Android app display label to `AI DFU (Midwife)` using `@string/app_name`.
- Added `android/app/src/main/res/values/strings.xml` with the new app name.
- Updated iOS display name and bundle name to `AI DFU (Midwife)`.
- Updated macOS product name and Windows metadata product/display strings to `AI DFU (Midwife)`.
- Generated Android launcher icon mipmap PNGs from `pic/app_logo.png` on a white background.
- Generated iOS AppIcon PNGs from `pic/app_logo.png` on a white background.

## 2026-04-22 15:52:42 +07:00

### Assessment Prefill Visibility

- Verified `/analyze-fillin` still writes extracted values into `_reviewed` before opening Wound Assessment.
- Verified text-field controllers are refreshed with `_applyPrefillControllersFromReviewed()` before navigation.
- Verified SINBAD area is recalculated from extracted wound size before navigation.
- Updated the skipped-preview flow to auto-expand `Fill-in Answers (Review)` so prefilled fields are visible immediately on Wound Assessment.

## 2026-04-22 15:51:00 +07:00

### Skip AI Extraction Dev Preview

- Updated successful `/analyze-fillin` photo flow to navigate directly to the Wound Assessment page.
- Kept the AI extraction data parsing and prefill behavior unchanged.
- Kept `response_view` available for non-fill-in fallback/debug flows.

## 2026-04-22 15:46:24 +07:00

### Notification Bell Count Badge

- Replaced the bell red dot with a compact unread-count badge.
- Badge appears only when unread notifications exist.
- Badge shows exact unread count up to `9`, then `9+`.
- Preserved existing notification fetching and read/unread update behavior.

## 2026-04-22 15:45:36 +07:00

### Notification Bell Badge

- Updated the bell notification red dot to show only when at least one notification has `status == UNREAD`.
- Preserved the existing notification list, read/unread update behavior, and panel UI.

## 2026-04-22 15:38:04 +07:00

### Compact Notification Cards

- Reduced in-app notification card padding, border radius, shadow, icon size, and spacing.
- Reduced notification list padding and separator spacing.
- Limited notification body preview to two lines.
- Reduced metadata pill icon/text sizes and padding.
- Preserved existing notification data mapping, read/unread behavior, case navigation, and filter behavior.

## 2026-04-22 15:27:37 +07:00

### Notification Visibility Fix

- Fixed the redesigned notification card layout by keeping the status stripe inside an intrinsic-height row.
- Updated notification panel external entry points to reset back to the all-notifications view when opened from the bell, push snackbar, or push tap.
- Kept the unread-only eye-slash toggle behavior inside the panel.
- Added a clearer empty state for unread-only mode: `No unread notifications.`
- Attempted `dart format lib/widgets/main_navigation_screen.dart`, but it timed out in this environment.

## 2026-04-22 15:23:46 +07:00

### Notification Card Redesign

- Extracted notification card rendering into `_buildNotificationCard`.
- Redesigned in-app notification cards with:
  a left read-status stripe,
  stronger unread border/shadow,
  gradient icon badge,
  notification type eyebrow,
  compact status chip,
  body text panel,
  colored metadata pills,
  timestamp footer with clock icon.
- Preserved existing card behaviors:
  tap to mark read,
  case-id pill opens case detail,
  unread status updates locally.

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
