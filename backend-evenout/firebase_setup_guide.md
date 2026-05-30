# Firebase Setup Guide for EvenOut Push Notifications

This guide explains how to create a Firebase project, configure it for both your Flutter app and NestJS backend, and test push notifications.

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project**.
3. Enter the project name as **EvenOut** and click **Continue**.
4. (Optional) Disable Google Analytics for now, or keep it enabled and choose a Google Analytics account. Click **Create project**.
5. Wait for the project to provision and click **Continue**.

## 2. Set Up the Backend Service Account (NestJS)

To let your backend send push notifications, it needs administrative access to your Firebase project.

1. On the Firebase Console dashboard, click the **Settings (gear) icon** next to "Project Overview" in the left sidebar and select **Project settings**.
2. Go to the **Service accounts** tab.
3. Make sure **Node.js** is selected.
4. Click **Generate new private key**, then click **Generate key** in the warning dialog.
5. A JSON file will be downloaded (e.g., `evenout-firebase-adminsdk-...json`).
6. Rename this file to `firebase-service-account.json`.
7. Move `firebase-service-account.json` into the root folder of your `backend-evenout` project. 
   *(Note: The file is ignored in Git so your credentials stay safe.)*
8. In your `.env` file, add the path to the service account file:
   ```env
   FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
   ```

## 3. Set Up the Frontend (Flutter)

To receive push notifications on mobile devices, you need to register Android and iOS apps in your Firebase project.

### Android Setup
1. In the Firebase Console **Project Overview**, click the **Android icon** to add an app.
2. Enter your Android package name (e.g., `com.example.evenout`). You can find this in `android/app/build.gradle` under `applicationId`.
3. Click **Register app**.
4. Download the `google-services.json` file.
5. Place it in the `android/app/` directory of your Flutter project.
6. Click **Next** until you finish the setup.

### iOS Setup (Optional but recommended)
1. In the Firebase Console, click **Add app** and select **iOS**.
2. Enter your iOS bundle ID (found in Xcode).
3. Register the app.
4. Download the `GoogleService-Info.plist` file.
5. Open `ios/Runner.xcworkspace` in Xcode, drag and drop the `GoogleService-Info.plist` into the Runner directory.

### Flutter Firebase Packages
In your Flutter app, add the required dependencies to your `pubspec.yaml`:
```bash
flutter pub add firebase_core
flutter pub add firebase_messaging
flutter pub add flutter_local_notifications
```
Then follow the token registration and background message handling logic defined in the phase 2 plan.

## 4. Test the Integration

1. Start your NestJS backend:
   ```bash
   npm run start:dev
   ```
2. Verify that you see `Firebase Admin initialized successfully.` in the server logs.
3. Update a user's FCM token using the new endpoint:
   - **Method**: `PATCH`
   - **URL**: `http://localhost:3000/api/v1/users/fcm-token` *(adjust prefix based on your setup)*
   - **Body**:
     ```json
     {
       "fcm_token": "dummy_token_from_flutter_or_device"
     }
     ```
4. Test the user-triggered nudge:
   - **Method**: `POST`
   - **URL**: `http://localhost:3000/api/v1/nudges/send`
   - **Body**:
     ```json
     {
       "debtor_id": "the_uuid_of_the_user_who_owes_you"
     }
     ```
5. If successful, your terminal will log `Successfully sent message...` and the device will receive the push notification!
