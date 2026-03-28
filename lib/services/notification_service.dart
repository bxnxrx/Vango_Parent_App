import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

// ✨ NEW: Imports for CallKit and Call Screen
import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';
import 'package:vango_parent_app/screens/call/call_screen.dart'; // 🚨 Adjust this path if your call_screen is elsewhere!

// ---------------------------------------------------------
// ✨ NEW: TOP-LEVEL BACKGROUND HANDLER FOR CALLKIT
// ---------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background Message Received: ${message.messageId}');
  final type = message.data['type'];

  if (type == 'incoming_call') {
    final callerName = message.data['callerName'] ?? 'VanGo Driver';
    final channelName = message.data['channelName'] ?? '';
    final callerId = message.data['callerId'] ?? '';

    CallEvent callEvent = CallEvent(
      sessionId: channelName, 
      callType: 0, // 0 = Audio Call
      callerId: callerId.hashCode, 
      callerName: callerName,
      opponentsIds: {},
      userInfo: {'channelName': channelName},
    );
    
    ConnectycubeFlutterCallKit.showCallNotification(callEvent);
  } else if (type == 'cancel_call') {
    final channelName = message.data['channelName'] ?? '';
    ConnectycubeFlutterCallKit.reportCallEnded(sessionId: channelName);
  }
}

class NotificationService {
  // Singleton pattern
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'vango_notifications_v4';
  
  // ✨ NEW: Navigator key to open the call screen
  late GlobalKey<NavigatorState> navigatorKey; 

  // 1. Initialize the service (✨ Now accepts the navigatorKey)
  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    // Request FCM permissions
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

    // ✨ NEW: Initialize CallKit Action Listeners
    ConnectycubeFlutterCallKit.instance.init(
      onCallAccepted: _onCallAccepted,
      onCallRejected: _onCallRejected,
    );

    // ---------------------------------------------------------
    // FIREBASE LISTENERS
    // ---------------------------------------------------------

    // A. LISTEN FOR FOREGROUND MESSAGES
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground Message Received: ${message.messageId}');

      final data = message.data;
      final type = data['type']?.toString();

      // ✨ NEW: Intercept call signals and route to CallKit
      if (type == 'incoming_call' || type == 'cancel_call') {
        firebaseMessagingBackgroundHandler(message);
        return; // Stop here so it doesn't show a basic notification banner
      }

      final title = message.notification?.title;
      final body = message.notification?.body;

      if (title != null && body != null) {
        final notificationId = message.messageId?.hashCode ?? DateTime.now().millisecond;
        showManualNotification(title, body, notificationId);
      }

      if (type == 'emergency_active') {
        debugPrint('🚨 Emergency started! Pushing red screen...');
      } 
      else if (type == 'emergency_resolved') {
        debugPrint('✅ Emergency resolved! Closing red screen...');
      }
    });

    // B. HANDLE NOTIFICATION TAPS (When app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🚀 App opened via notification tap');
    });

    // C. AUTO-SYNC TOKEN ON REFRESH
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token Refreshed');
    });
  }

  // ✨ NEW: Handle Call Answer
  Future<void> _onCallAccepted(CallEvent callEvent) async {
    final channelName = callEvent.userInfo?['channelName'] as String?;
    final callerName = callEvent.callerName;

    if (channelName != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelName: channelName,
            callerName: callerName,
          ),
        ),
      );
    }
  }

  // ✨ NEW: Handle Call Decline
  Future<void> _onCallRejected(CallEvent callEvent) async {
    ConnectycubeFlutterCallKit.reportCallEnded(sessionId: callEvent.sessionId);
  }

  // 2. Show a notification manually (Used by foreground FCM listener)
  Future<void> showManualNotification(String title, String body, int notificationId) async {
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
      notificationId,
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