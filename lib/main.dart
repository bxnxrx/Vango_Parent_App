import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:vango_parent_app/screens/app_shell.dart';
import 'package:vango_parent_app/screens/auth/auth_flow.dart';
import 'package:vango_parent_app/screens/onboarding/onboarding_screen.dart';
import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vango_parent_app/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  AppConfig.ensure();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  try {
    await AuthService.instance.initialize();
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
    _checkNotificationPermissions();
  }

  // NEW: Helper function to request permissions
  Future<void> _checkNotificationPermissions() async {
    // We initialize the service first
    await NotificationService.instance.initialize();
    // Then we trigger the system popup (Allow/Don't Allow)
    await NotificationService.instance.requestPermissions();
  }

  void _finishOnboarding() {
    if (_stage == _AppStage.onboarding) {
      setState(() => _stage = _AppStage.auth);
    }
  }

Future<void> _completeAuth() async {
    try {
      // 1. Fire off the notification
      await NotificationService.instance.initialize();
      bool granted = await NotificationService.instance.requestPermissions();
      if (granted) {
        await NotificationService.instance.showManualNotification(
          "Welcome to VanGo!", 
          "Account created successfully."
        );
      }
    } catch (e) {
      debugPrint("Notification failed: $e");
    }

    if (!mounted) return;

    // 2. Clear any "Personal Info" or "OTP" screens that might be open
   _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    // 3. Show the green success SnackBar
    _messengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Account created successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    // 4. Switch the UI to the Home screen
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
    final Widget home;

    switch (_stage) {
      case _AppStage.onboarding:
        home = OnboardingScreen(onFinished: _finishOnboarding);
        break;
      case _AppStage.auth:
        home = AuthFlow(onAuthenticated: _completeAuth);
        break;
      case _AppStage.home:
        // FIXED: This now matches the AppShell constructor exactly
        home = AppShell(
          onSignOut: _signOut,
          onAttendancePressed: () {},
          payments_screen: () {},
          Messages_screen: () {},
          home_screen: () {},
        );
        break;
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      title: 'VanGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: home,
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