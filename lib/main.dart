import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:vango_parent_app/screens/app_shell.dart';
import 'package:vango_parent_app/screens/auth/auth_flow.dart';
import 'package:vango_parent_app/screens/onboarding/onboarding_screen.dart';
// ✅ ADD THIS IMPORT (Adjust path if needed)
import 'package:vango_parent_app/screens/splash/animated_splash_screen.dart';

import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_theme.dart';
import 'package:vango_parent_app/services/notification_service.dart';
import 'package:vango_parent_app/services/device_service.dart';
import 'package:vango_parent_app/services/theme_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint("📩 Background Message Received: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'vango_notifications_v4',
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

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await dotenv.load(fileName: ".env");
  AppConfig.ensure();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  try {
    await NotificationService.instance.initialize();
    await AuthService.instance.initialize();

    final deviceService = DeviceService();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.initialSession) {
        debugPrint("🔐 Auth state change detected! Syncing Device Data...");
        deviceService.syncDeviceData();
        deviceService.listenForTokenRefreshes();
      }
    });

    await deviceService.syncDeviceData();

    // ✅ REVERTED: Just run the app! The Splash screen handles the rest.
    runApp(const VanGoApp());
  } catch (error, stackTrace) {
    debugPrint('Parent app offline: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(ParentOfflineApp(error: error));
  }
}

// ✅ ADDED 'splash' TO YOUR STAGES
enum _AppStage { splash, onboarding, auth, home }

class VanGoApp extends StatefulWidget {
  // ✅ REVERTED: No longer need to pass variables here
  const VanGoApp({super.key});

  @override
  State<VanGoApp> createState() => _VanGoAppState();
}

class _VanGoAppState extends State<VanGoApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // ✅ APP STARTS IN SPLASH STAGE
  _AppStage _stage = _AppStage.splash;

  @override
  void initState() {
    super.initState();
  }

  // ✅ NEW: Triggered when the Animated Splash finishes its loading and animations
  void _onSplashFinished(bool hasSeenOnboarding) {
    setState(() {
      _stage = hasSeenOnboarding ? _AppStage.auth : _AppStage.onboarding;
    });
  }

  void _finishOnboarding() {
    if (_stage == _AppStage.onboarding) {
      setState(() => _stage = _AppStage.auth);
    }
  }

  Future<void> _completeAuth() async {
    try {} catch (e) {
      debugPrint("Auth completion error: $e");
    }

    if (!mounted) return;
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
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
  Widget build(BuildContext context) {
    final Widget currentScreen;

    // ✅ Set up the screens with ValueKeys so AnimatedSwitcher knows when they change
    switch (_stage) {
      case _AppStage.splash:
        currentScreen = AnimatedSplashScreen(
          key: const ValueKey('splash'),
          onInitializationComplete: _onSplashFinished,
        );
        break;
      case _AppStage.onboarding:
        currentScreen = OnboardingScreen(
          key: const ValueKey('onboarding'),
          onFinished: _finishOnboarding,
        );
        break;
      case _AppStage.auth:
        currentScreen = AuthFlow(
          key: const ValueKey('auth'),
          onAuthenticated: _completeAuth,
        );
        break;
      case _AppStage.home:
        currentScreen = AppShell(
          key: const ValueKey('home'),
          onSignOut: _signOut,
          onAttendancePressed: () {},
          payments_screen: () {},
          Messages_screen: () {},
          home_screen: () {},
        );
        break;
    }

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
          themeMode: currentThemeMode,

          // ✅ WRAPPED IN ANIMATED SWITCHER FOR PREMIUM CROSS-FADES
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeInCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: currentScreen,
          ),
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
      // ✅ REVERTED: Just run the app
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
