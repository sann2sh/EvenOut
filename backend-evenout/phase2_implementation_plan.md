# Phase 2: The Nudge Engine (FCM Notifications)

This phase introduces push notifications to EvenOut, solving the core problem of awkward debt collection through automated and user-triggered "quirky" nudges.

## Overall Architecture
- **Backend (NestJS)**: Acts as the notification orchestrator. It holds the logic for *when* to send (Cron jobs) and *what* to send (quirky templates). It communicates securely with Firebase using the `firebase-admin` SDK.
- **Frontend (Flutter)**: Acts as the receiver. It requests device permissions, retrieves the FCM device token, sends it to the backend, and listens for incoming push messages.
- **Firebase**: The intermediary broker that routes pushes to iOS/Android devices.

---

## User Review Required

> [!IMPORTANT]
> **Firebase Service Account:** You will need to create a Firebase Project in the Firebase Console and generate a Service Account JSON key for the backend. Do you already have a Firebase project created for EvenOut?

> [!NOTE]
> **Cron Timing:** I propose running the automated background check daily at 10:00 AM. If a user has a debt older than 3 days, they get a quirky nudge. Do you want to adjust this logic (e.g., 5 days, 7 days)?

## Proposed Changes

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

## Verification Plan

### Manual Verification
1. I will set up the backend endpoints.
2. I will guide you on how to test the `POST /nudges/send` endpoint directly from Postman using a dummy FCM token (or a real one if you have a barebones Flutter app running).
3. We will temporarily set the Cron job to run every 1 minute to verify that the automated system accurately queries the database and attempts to send notifications.
