# Development Decisions

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
