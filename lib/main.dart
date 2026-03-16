import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:vango_parent_app/screens/app_shell.dart';
import 'package:vango_parent_app/screens/auth/auth_flow.dart';
import 'package:vango_parent_app/screens/onboarding/onboarding_screen.dart';
import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_theme.dart';
import 'package:vango_parent_app/services/notification_service.dart';
import 'package:vango_parent_app/services/device_service.dart';
import 'package:vango_parent_app/services/theme_service.dart';

// Make sure this path is correct

// --- 1. BACKGROUND MESSAGE HANDLER ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint("📩 Background Message Received: ${message.messageId}");
  // Android automatically displays the notification in the background
  // We DO NOT call local notifications here to avoid duplicates!
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. INITIALIZE FIREBASE
  await Firebase.initializeApp();

  // 3. SET UP HIGH IMPORTANCE CHANNEL
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'vango_notifications_v4', // id: MUST MATCH what you used in NotificationService and AndroidManifest
    'Parent Notifications',
    description: 'Important updates for parents.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // 4. REGISTER FIREBASE HANDLERS
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 5. LOAD ENV & SUPABASE
  await dotenv.load(fileName: ".env");
  AppConfig.ensure();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  try {
    // 6. INITIALIZE SERVICES
    await NotificationService.instance.initialize();
    await AuthService.instance.initialize();

    final deviceService = DeviceService();

    // 7. LISTEN FOR LOGIN / LOGOUT TO SYNC TOKENS
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.initialSession) {
        debugPrint("🔐 Auth state change detected! Syncing Device Data...");
        deviceService.syncDeviceData();
        deviceService.listenForTokenRefreshes();
      }
    });

    // 8. SYNC DEVICE DATA ON STARTUP
    await deviceService.syncDeviceData();

    runApp(const VanGoApp());
  } catch (error, stackTrace) {
    debugPrint('Parent app offline: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(ParentOfflineApp(error: error));
  }
}

enum _AppStage { onboarding, auth, home }

class VanGoApp extends StatefulWidget {
  const VanGoApp({super.key});

  @override
  State<VanGoApp> createState() => _VanGoAppState();
}

class _VanGoAppState extends State<VanGoApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
  _AppStage _stage = _AppStage.onboarding;

  @override
  void initState() {
    super.initState();
    // Notification permissions are now handled inside NotificationService.instance.initialize()
  }

  void _finishOnboarding() {
    if (_stage == _AppStage.onboarding) {
      setState(() => _stage = _AppStage.auth);
    }
  }

  Future<void> _completeAuth() async {
    try {
      // Because we added the onAuthStateChange listener in main(), 
      // the device data will automatically sync. 
      // We don't need manual notifications here since the Node.js webhook sends the push notification!
    } catch (e) {
      debugPrint("Auth completion error: $e");
    }

    if (!mounted) return;

    // 1. Clear any "Personal Info" or "OTP" screens that might be open
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    
    // SnackBar removed! Now relying solely on push notifications.

    // 2. Switch the UI to the Home screen
    setState(() {
      _stage = _AppStage.home;
    });
  }

  void _signOut() {
    if (_stage == _AppStage.home) {
      setState(() => _stage = _AppStage.auth);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final Widget home;

    switch (_stage) {
      case _AppStage.onboarding:
        home = OnboardingScreen(onFinished: _finishOnboarding);
        break;
      case _AppStage.auth:
        home = AuthFlow(onAuthenticated: _completeAuth);
        break;
      case _AppStage.home:
        home = AppShell(
          onSignOut: _signOut,
          onAttendancePressed: () {},
          payments_screen: () {},
          Messages_screen: () {},
          home_screen: () {},
        );
        break;
    }

    // --- WRAP WITH ValueListenableBuilder ---
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          scaffoldMessengerKey: _messengerKey,
          title: 'VanGo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          
          // --- USE THE DYNAMIC THEME MODE ---
          themeMode: currentThemeMode, 
          
          home: home,
        );
      },
    );
  }
}
  
class ParentOfflineApp extends StatelessWidget {
  const ParentOfflineApp({super.key, required this.error});

  final Object error;

  Future<void> _retry(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    try {
      await AuthService.instance.initialize();
      runApp(const VanGoApp());
    } catch (retryError) {
      messenger.showSnackBar(
        SnackBar(content: Text('Still offline: ${retryError.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VanGo Parent (Offline)',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Color(0xFF2E3559)),
                const SizedBox(height: 16),
                const Text(
                  'Backend unavailable',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _retry(context),
                  child: const Text('Retry connection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}