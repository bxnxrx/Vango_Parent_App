import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

// TODO: Import your DeviceService if you want to sync tokens automatically on refresh!
// import 'package:vango_parent_app/services/device_service.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'parent_notifications_channel';

  // 1. Initialize the service
  Future<void> initialize() async {
    // Request FCM permissions (Handles both iOS and Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    }

    // Android Setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Setup
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // CREATE HIGH IMPORTANCE CHANNEL FOR ANDROID
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      'Parent Notifications',
      description: 'Important updates for parents',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // ---------------------------------------------------------
    // FIREBASE LISTENERS
    // ---------------------------------------------------------

    // A. LISTEN FOR FOREGROUND MESSAGES
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground Message Received: ${message.messageId}');

      final title = message.notification?.title;
      final body = message.notification?.body;

      if (title != null && body != null) {
        showManualNotification(title, body);
      }
    });

    // B. HANDLE NOTIFICATION TAPS (When app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🚀 App opened via notification tap');
      // You can handle routing here if you want to send parents to specific screens
    });

    // C. AUTO-SYNC TOKEN ON REFRESH
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token Refreshed');
      // Call your sync function here so the database always has the latest token!
      // await DeviceService().syncDeviceData(); 
    });
  }

  // 2. Show a notification manually (Used by foreground FCM listener)
  Future<void> showManualNotification(String title, String body) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      'Parent Notifications',
      channelDescription: 'Important updates for parents',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // Unique ID so notifications don't overwrite each other
      title,
      body,
      platformDetails,
    );
  }

  // 3. Get FCM Token (Used by your DeviceService)
  Future<String?> getToken() async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            debugPrint('⚠️ Still no APNS token. Likely on an iOS Simulator.');
          }
        }
      }

      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }
}