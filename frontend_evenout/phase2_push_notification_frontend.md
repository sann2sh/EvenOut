
### Frontend (Flutter App)

Even though I am strictly managing the backend code, here is exactly what you will need to build in the Flutter frontend:

#### 1. Firebase Setup
- Go to the Firebase Console -> Add Project -> "EvenOut".
- Register your Android app (download `google-services.json` into `android/app/`).
- Register your iOS app (download `GoogleService-Info.plist` into `ios/Runner/`).

#### 2. Install Packages
```yaml
dependencies:
  firebase_core: ^latest
  firebase_messaging: ^latest
  flutter_local_notifications: ^latest
```

#### 3. Token Registration Flow
On app startup (after a user logs in), run this logic:
1. Request notification permissions: `FirebaseMessaging.instance.requestPermission()`
2. Get the token: `String? token = await FirebaseMessaging.instance.getToken();`
3. Send this token to your backend via the new `PATCH /api/v1/users/fcm-token` API.

#### 4. Handling Notifications
- **Foreground**: Listen to `FirebaseMessaging.onMessage` and display a local popup or snackbar.
- **Background/Terminated**: Define a top-level `@pragma('vm:entry-point')` function for `FirebaseMessaging.onBackgroundMessage` so the OS can display the standard system notification tray.

#### 5. UI Implementation
- On the "Balances" screen, next to any user who owes you money, add a "Nudge" (🔔) button.
- Tapping it calls `POST /api/v1/nudges/send` with the debtor's `user_id`.

---
