# Changelog

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
