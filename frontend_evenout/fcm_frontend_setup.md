

### Backend (NestJS)

#### [NEW] Firebase Service Integration
- Install dependencies: `firebase-admin`, `@nestjs/schedule`
- Create `FirebaseModule` and `FirebaseService` to initialize the Admin SDK using your service account credentials.

#### [MODIFY] Users Module
- Add endpoint `PATCH /users/fcm-token` to allow the Flutter frontend to update the `fcm_token` column in the `users` table whenever the device token refreshes.

#### [NEW] Nudges Module (Phase 2B - User Triggered)
- Create `NudgesController` with `POST /nudges/send`.
- Validates the request (ensures the requester is actually owed money by the target).
- Selects a random, quirky template (e.g., *"Did you forget your wallet in 2012? Pay [Name] Rs. 500!"*).
- Dispatches the push notification via `FirebaseService`.

#### [NEW] Cron / Scheduler Module (Phase 2A - Periodic)
- Create `ScheduleModule` using `@nestjs/schedule`.
- Implement a `@Cron()` job that runs daily.
- It will query the `peer_balances` SQL view. If it finds debts older than a specified threshold, it automatically triggers a reminder notification to the debtor's `fcm_token`.

---
### Frontend (Flutter App)

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

