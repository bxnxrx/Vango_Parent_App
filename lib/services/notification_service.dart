import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  // Singleton pattern (so you can access it anywhere using .instance)
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. Initialize the service
  Future<void> initialize() async {
    // Android Setup (Uses the default app icon)
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Setup (Alerts, Sounds, Badges)
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  // 2. Request Permissions (Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      // iOS permission is handled during initialization usually, but this is a safeguard
      return await Permission.notification.request().isGranted;
    } 
    
    if (Platform.isAndroid) {
      // Android 13+ needs explicit permission
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    
    return true; // Older Android versions don't need runtime permission
  }

  // 3. Show a generic notification immediately
  Future<void> showManualNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel', // Channel ID
      'General Notifications', // Channel Name
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformDetails,
    );
  }
}