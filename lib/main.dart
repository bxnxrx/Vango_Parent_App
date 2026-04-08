import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ✅ Enterprise Plugins
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// ✅ Riverpod Import Added
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✨ CallKit & Call Screen Imports
import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';
import 'package:vango_parent_app/screens/call/call_screen.dart';

import 'package:vango_parent_app/screens/app_shell.dart';
import 'package:vango_parent_app/screens/auth/auth_flow.dart';
import 'package:vango_parent_app/screens/onboarding/onboarding_screen.dart';
import 'package:vango_parent_app/screens/splash/animated_splash_screen.dart';

import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_theme.dart';
import 'package:vango_parent_app/services/notification_service.dart';
import 'package:vango_parent_app/services/device_service.dart';
import 'package:vango_parent_app/services/theme_service.dart';
import 'package:vango_parent_app/services/language_service.dart';

// ✅ Required for Localization
import 'package:vango_parent_app/l10n/app_localizations.dart';

// ✨ 1. GLOBAL NAVIGATOR KEY (Required for CallKit to open the Call Screen)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // GLOBAL CRASH HANDLER (Catches all Flutter UI fatal errors)
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

  // ✨ 2. ATTACH THE BACKGROUND HANDLER FROM YOUR NOTIFICATION SERVICE
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
    // ✨ 3. PASS THE NAVIGATOR KEY TO THE SERVICE
    await NotificationService.instance.initialize(navigatorKey);
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

    // ✅ FIX: Check if the app was launched by tapping a call notification
    // (happens when app was completely killed/offline)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && initialMessage.data['type'] == 'incoming_call') {
      debugPrint('📞 App launched from call notification! Will open call screen...');
      final channelName = initialMessage.data['channelName'] ?? '';
      final callerName  = initialMessage.data['callerName']  ?? 'VanGo Driver';
      final agoraToken  = initialMessage.data['agoraToken']  ?? '';

      if (channelName.isNotEmpty) {
        // Delay navigation until after the app is fully built
        Future.delayed(const Duration(seconds: 2), () {
          String safeChannelName = channelName;
          if (safeChannelName.length > 64) {
            safeChannelName = safeChannelName.substring(0, 64);
          }
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => CallScreen(
                channelName: safeChannelName,
                callerName:  callerName,
                agoraToken:  agoraToken,
              ),
            ),
          );
        });
      }
    }

    // ✅ WRAPPED THE APP IN ProviderScope
    runApp(const ProviderScope(child: VanGoApp()));
  } catch (error, stackTrace) {
    // Record startup errors to Crashlytics before falling back to Offline App
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: 'Parent app offline startup crash',
    );
    debugPrint('Parent app offline: $error');
    // ✅ WRAPPED THE FALLBACK APP IN ProviderScope as well
    runApp(ProviderScope(child: ParentOfflineApp(error: error)));
  }
}

enum _AppStage { splash, onboarding, auth, home }

class VanGoApp extends StatefulWidget {
  const VanGoApp({super.key});

  @override
  State<VanGoApp> createState() => _VanGoAppState();
}

class _VanGoAppState extends State<VanGoApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  _AppStage _stage = _AppStage.splash;

  @override
  void initState() {
    super.initState();
    // ✨ Call the listener setup here
    _setupCallKitListeners();
  }

  // ✨ FIX: CORRECT CALLKIT SYNTAX WITH ALL WARNINGS REMOVED ✨
  void _setupCallKitListeners() {
    // ✅ Ensure incoming calls show on lock screen
    ConnectycubeFlutterCallKit.setOnLockScreenVisibility(isVisible: true);

    ConnectycubeFlutterCallKit.instance.init(
      onCallAccepted: (CallEvent event) async {
        debugPrint('✅ Parent tapped ANSWER on the native screen!');

        // ✅ FIX: IMMEDIATELY clean up CallKit state so next calls work
        // CallKit's job is done once the user accepts — the actual call
        // is handled by Agora, NOT CallKit. If we don't clean up here,
        // CallKit thinks the session is still "active" and blocks future calls.
        ConnectycubeFlutterCallKit.reportCallEnded(sessionId: event.sessionId);
        ConnectycubeFlutterCallKit.clearCallData(sessionId: event.sessionId);
        debugPrint('✅ CallKit state cleaned up for accepted call: ${event.sessionId}');

        final rawChannelName = event.userInfo?['channelName'];
        final agoraToken     = event.userInfo?['agoraToken'] as String? ?? '';
        final callerName     = event.callerName;

        if (rawChannelName != null) {
          String safeChannelName = rawChannelName.toString();
          if (safeChannelName.length > 64) {
            safeChannelName = safeChannelName.substring(0, 64);
          }

          Future.delayed(const Duration(milliseconds: 500), () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => CallScreen(
                  channelName: safeChannelName,
                  callerName:  callerName,
                  agoraToken:  agoraToken,
                ),
              ),
            );
          });
        }
      },
      onCallRejected: (CallEvent event) async {
        debugPrint('❌ Parent tapped DECLINE. Cleaning up CallKit state...');
        ConnectycubeFlutterCallKit.reportCallEnded(sessionId: event.sessionId);
        ConnectycubeFlutterCallKit.clearCallData(sessionId: event.sessionId);
        debugPrint('✅ CallKit state cleaned up for session: ${event.sessionId}');

        // ✅ NEW: Notify the driver instantly via Supabase Realtime broadcast
        final channelName = event.userInfo?['channelName'] as String? ?? '';
        if (channelName.isNotEmpty) {
          debugPrint('📡 Sending decline broadcast to driver for channel: $channelName');
          try {
            final channel = Supabase.instance.client.channel('call:$channelName');
            await channel.subscribe();
            await channel.sendBroadcastMessage(
              event: 'declined',
              payload: {'reason': 'parent_declined'},
            );
            // Small delay to ensure message is sent before unsubscribing
            await Future.delayed(const Duration(milliseconds: 500));
            await Supabase.instance.client.removeChannel(channel);
            debugPrint('✅ Decline broadcast sent to driver!');
          } catch (e) {
            debugPrint('⚠️ Failed to send decline broadcast: $e');
          }
        }
      },
    );
  }

  void _onSplashFinished(bool hasSeenOnboarding) {
    setState(() {
      _stage = hasSeenOnboarding ? _AppStage.auth : _AppStage.onboarding;
    });

    FirebaseAnalytics.instance.logEvent(
      name: 'navigation_flow',
      parameters: {'source': 'splash', 'destination': _stage.name},
    );
  }

  void _finishOnboarding() {
    if (_stage == _AppStage.onboarding) {
      setState(() => _stage = _AppStage.auth);

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
    // ✨ Update to use the global key
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    setState(() {
      _stage = _AppStage.home;
    });

    FirebaseAnalytics.instance.logEvent(
      name: 'navigation_flow',
      parameters: {'source': 'auth', 'destination': 'home'},
    );
  }

  void _signOut() {
    if (_stage == _AppStage.home) {
      setState(() => _stage = _AppStage.auth);

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
        // ✨ Add secondary ValueListenableBuilder for the Language
        return ValueListenableBuilder<AppLanguage>(
          valueListenable: LanguageService.instance.currentLanguage,
          builder: (context, currentLang, child) {
            // Map AppLanguage to actual Locale object
            Locale appLocale;
            switch (currentLang) {
              case AppLanguage.sinhala:
                appLocale = const Locale('si');
                break;
              case AppLanguage.tamil:
                appLocale = const Locale('ta');
                break;
              case AppLanguage.english:
              default:
                appLocale = const Locale('en');
                break;
            }

            return MaterialApp(
              navigatorKey: navigatorKey, // ✨ 4. LINK THE GLOBAL KEY HERE
              scaffoldMessengerKey: _messengerKey,
              title: 'VanGo',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: currentThemeMode,

              // ✅ Localization Wiring
              locale: appLocale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,

              home: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: currentScreen,
              ),
            );
          },
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
      runApp(const ProviderScope(child: VanGoApp()));
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
