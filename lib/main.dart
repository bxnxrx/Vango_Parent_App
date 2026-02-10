import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:vango_parent_app/screens/app_shell.dart';
import 'package:vango_parent_app/screens/auth/auth_flow.dart';
import 'package:vango_parent_app/screens/onboarding/onboarding_screen.dart';
import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

// Keeps track of the user's current step inside the app.
enum _AppStage { onboarding, auth, home }

class VanGoApp extends StatefulWidget {
  const VanGoApp({super.key});

  @override
  State<VanGoApp> createState() => _VanGoAppState();
}

class _VanGoAppState extends State<VanGoApp> {
  _AppStage _stage = _AppStage.onboarding;

  // Move from onboarding screens to the auth flow.
  void _finishOnboarding() {
    if (_stage == _AppStage.onboarding) {
      setState(() => _stage = _AppStage.auth);
    }
  }

  // Unlock the main app once sign-in is done.
  void _completeAuth() {
    if (_stage == _AppStage.auth) {
      setState(() => _stage = _AppStage.home);
    }
  }

  // Reset everything when the user wants to revisit onboarding.
  void _showOnboardingAgain() {
    setState(() => _stage = _AppStage.onboarding);
  }

  // Drop back to auth when the user signs out.
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
        home = AppShell(
          onShowOnboarding: _showOnboardingAgain,
          onSignOut: _signOut,
        );
        break;
    }

    return MaterialApp(
      title: 'VanGo Parent',
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
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
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


