import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ✅ NEW: Enterprise Plugins
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:vango_parent_app/screens/app_shell.dart';
import 'package:vango_parent_app/screens/auth/auth_flow.dart';
import 'package:vango_parent_app/screens/onboarding/onboarding_screen.dart';
import 'package:vango_parent_app/screens/splash/animated_splash_screen.dart';
import 'package:vango_parent_app/screens/messages/messages_screen.dart'; // ✨ ADDED THIS IMPORT

import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_theme.dart';
import 'package:vango_parent_app/services/notification_service.dart';
import 'package:vango_parent_app/services/device_service.dart';
import 'package:vango_parent_app/services/theme_service.dart';
import 'package:vango_parent_app/services/language_service.dart';

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

  // ✅ 1. GLOBAL CRASH HANDLER (Catches all Flutter UI fatal errors)
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

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

  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');

  await dotenv.load(fileName: ".env");
  AppConfig.ensure();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  try {
    await NotificationService.instance.initialize();
    await AuthService.instance.initialize();
    await LanguageService.instance.init();

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

    runApp(const VanGoApp());
  } catch (error, stackTrace) {
    // Record startup errors to Crashlytics before falling back to Offline App
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: 'Parent app offline startup crash',
    );
    debugPrint('Parent app offline: $error');
    runApp(ParentOfflineApp(error: error));
  }
}

enum _AppStage { splash, onboarding, auth, home }

class VanGoApp extends StatefulWidget {
  const VanGoApp({super.key});

  @override
  State<VanGoApp> createState() => _VanGoAppState();
}

class _VanGoAppState extends State<VanGoApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  _AppStage _stage = _AppStage.splash;

  @override
  void initState() {
    super.initState();
    _setupInteractedMessage(); 
    _listenForForegroundMessages(); // ✨ ADDED: Start listening while app is open
  }

  // ✨ ADDED: Manually show Android notifications when the app is running in the foreground
  void _listenForForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground Message Received: ${message.notification?.title}");

      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'vango_notifications_v4', // Matches the channel ID created in main()
              'Parent Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: message.data['type'], // Used if the user taps the foreground banner
        );
      }
    });
  }

  // Listens for notification taps when app is closed or in background
  Future<void> _setupInteractedMessage() async {
    // Terminated State
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Background State
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // Routes the user to the Messages Screen when a chat notification is tapped
  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      final String chatId = message.data['chatId'] ?? '';

      if (chatId.isNotEmpty) {
        // 800ms delay ensures the Supabase session is initialized before routing
        Future.delayed(const Duration(milliseconds: 800), () {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => MessagesScreen(
                // Passing an empty function since there's no drawer when pushed directly over the shell
                onOpenDrawer: () {}, 
              ),
            ),
          );
        });
      }
    }
  }

  void _onSplashFinished(bool hasSeenOnboarding) {
    setState(() {
      _stage = hasSeenOnboarding ? _AppStage.auth : _AppStage.onboarding;
    });

    // ✅ 2. NAVIGATION ANALYTICS (Splash -> Target)
    FirebaseAnalytics.instance.logEvent(
      name: 'navigation_flow',
      parameters: {'source': 'splash', 'destination': _stage.name},
    );
  }

  void _finishOnboarding() {
    if (_stage == _AppStage.onboarding) {
      setState(() => _stage = _AppStage.auth);

      // ✅ 2. NAVIGATION ANALYTICS (Onboarding -> Auth)
      FirebaseAnalytics.instance.logEvent(
        name: 'navigation_flow',
        parameters: {'source': 'onboarding', 'destination': 'auth'},
      );
    }
  }

  Future<void> _completeAuth() async {
    try {
      // Auth logic handled externally
    } catch (e) {
      debugPrint("Auth completion error: $e");
    }

    if (!mounted) return;
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    setState(() {
      _stage = _AppStage.home;
    });

    // ✅ 2. NAVIGATION ANALYTICS (Auth -> Home)
    FirebaseAnalytics.instance.logEvent(
      name: 'navigation_flow',
      parameters: {'source': 'auth', 'destination': 'home'},
    );
  }

  void _signOut() {
    if (_stage == _AppStage.home) {
      setState(() => _stage = _AppStage.auth);

      // ✅ 2. NAVIGATION ANALYTICS (Home -> Auth via Sign Out)
      FirebaseAnalytics.instance.logEvent(
        name: 'navigation_flow',
        parameters: {
          'source': 'home',
          'destination': 'auth',
          'action': 'sign_out',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget currentScreen;

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
          onShowOnboarding: () => setState(() => _stage = _AppStage.onboarding),
          onSignOut: _signOut,
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

          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
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