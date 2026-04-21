# Push Notification Module Design

This app now has a client-side push notification module built around Firebase Cloud Messaging (FCM).

## Delivery flow

1. The app starts `PushNotificationService` in `lib/main.dart`.
2. The service asks for notification permission, reads the FCM device token, and listens for token refresh.
3. The app posts the token to `POST /notification-devices/register`.
4. The backend stores the token against the nurse user and sends FCM messages when a case/task event happens.
5. If the app is foregrounded, the service shows a local notification and refreshes the in-app notification list.
6. If the app is backgrounded or terminated, the OS delivers the push and reopening the app routes the user into the notification panel.

## Current app files

- `lib/services/notification_service.dart`
  Handles Firebase init, permission requests, foreground display, background handler registration, token refresh, and notification open events.
- `lib/widgets/main_navigation_screen.dart`
  Syncs the current device token to the backend, refreshes `/nurse-notifications`, and opens the notification panel when a push is tapped.
- `android/app/src/main/AndroidManifest.xml`
  Declares `POST_NOTIFICATIONS` and the default notification channel id.
- `android/settings.gradle.kts`
- `android/app/build.gradle.kts`
  Apply the Google services plugin required by Firebase.
- `ios/Runner/Info.plist`
  Enables `remote-notification` background mode.

## Backend contract

Recommended request for `POST /notification-devices/register`:

```json
{
  "user_id": "nurse-app",
  "role": "NURSE",
  "fcm_token": "fcm-token",
  "platform": "android",
  "device_id": "optional-device-id"
}
```

Recommended backend table:

- `user_id`
- `role`
- `platform`
- `fcm_token`
- `device_id`
- `last_seen_at`
- `is_active`

Recommended FCM payload:

```json
{
  "message": {
    "token": "fcm-token",
    "notification": {
      "title": "New treatment plan",
      "body": "Case 2041 has been assigned to you"
    },
    "data": {
      "type": "PLAN_ISSUED_TO_NURSE",
      "case_id": "2041",
      "task_id": "889",
      "patient_id": "555"
    },
    "android": {
      "priority": "high"
    },
    "apns": {
      "headers": {
        "apns-priority": "10"
      }
    }
  }
}
```

## Remaining setup

- Add `android/app/google-services.json`.
- Add `ios/Runner/GoogleService-Info.plist`.
- Replace the placeholder `user_id: default-nurse` with the real authenticated nurse id.
- Implement the backend registration endpoint and FCM sender.
- Run `flutter pub get` to install the new packages.
