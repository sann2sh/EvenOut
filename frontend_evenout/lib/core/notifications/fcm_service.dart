import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend_evenout/features/user/data/user_repository.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` here as well.
  print('Handling a background message: ${message.messageId}');
}

class FcmService {
  static final FcmService instance = FcmService._internal();

  factory FcmService() => instance;

  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize(UserRepository userRepository) async {
    if (_isInitialized) return;

    // 1. Request permission (iOS & web)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      print('User declined or has not accepted permission');
      return;
    }

    // 2. Setup local notifications for foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
        
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle foreground tap
        if (details.payload != null) {
          print('Notification tapped with payload: ${details.payload}');
          // TODO: handle routing if needed
        }
      },
    );

    // Create a high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/launcher_icon',
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 5. Get Token and Sync to Backend
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await userRepository.updateMe(fcmToken: token);
      }
      
      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token Refreshed: $newToken');
        await userRepository.updateMe(fcmToken: newToken);
      });
    } catch (e) {
      print('Failed to get or update FCM token: $e');
    }

    _isInitialized = true;
  }
}
