import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Enterprise Plugins
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final Function(bool hasSeenOnboarding) onInitializationComplete;

  const AnimatedSplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

// Note: Using TickerProviderStateMixin instead of SingleTickerProvider
// because we now have an Entrance and an Exit animation.
class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _exitController;

  final String _brandName = "VanGo";
  late List<Animation<double>> _letterOpacities;
  late List<Animation<Offset>> _letterSlides;

  int _lastHapticIndex = -1;

  @override
  void initState() {
    super.initState();

    // ✅ 3. ENTERPRISE CRASHLYTICS HOOK
    FirebaseCrashlytics.instance.log("Animated Splash Screen Initialized");

    // --- SETUP ENTRANCE ANIMATION (The Cascade) ---
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _letterOpacities = [];
    _letterSlides = [];

    // Create a staggered animation for each letter
    final double step = 0.5 / _brandName.length; // Space out the start times
    for (int i = 0; i < _brandName.length; i++) {
      final double start = i * step;
      final double end =
          start + 0.5; // Each letter takes 50% of the total time to finish

      _letterOpacities.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );

      _letterSlides.add(
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    // THE PREMIUM HAPTIC CASCADE
    _entranceController.addListener(() {
      final double val = _entranceController.value;

      // Trigger haptics perfectly timed to each letter's appearance
      for (int i = 0; i < _brandName.length; i++) {
        final double triggerPoint =
            i * step + 0.1; // 10% into the letter's animation

        if (val >= triggerPoint && _lastHapticIndex < i) {
          _lastHapticIndex = i;

          if (i == _brandName.length - 1) {
            // Final letter gets the heavy lock impact
            HapticFeedback.mediumImpact();
          } else {
            // Sequential light taps for the cascade
            HapticFeedback.lightImpact();
          }
        }
      }
    });

    // --- SETUP EXIT ANIMATION ---
    // ✅ 1. SPLASH TO ONBOARDING TRANSITION POLISH
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Smooth 600ms fade out
    );

    // Start the show
    _entranceController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();

    // ✅ 2. ENTERPRISE ANALYTICS HOOK
    FirebaseAnalytics.instance.logEvent(name: 'splash_started');

    // ✅ 4. FIRST FRAME OPTIMIZATION (Warmup)
    // Run critical tasks in parallel using Future.wait
    late bool hasSeenOnboarding;

    try {
      await Future.wait([
        // Task A: Check memory
        SharedPreferences.getInstance().then((prefs) {
          hasSeenOnboarding = prefs.getBool('onboarding_completed') ?? false;
        }),

        // Task B: Warm up API/Preload Fonts (Dummy delay here, replace with real API ping if needed)
        Future.delayed(const Duration(milliseconds: 200)),
      ]);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Splash Screen Warmup Failed',
      );
      hasSeenOnboarding = false; // Safe fallback
    }

    stopwatch.stop();

    // Ensure the animation has time to fully play and the user absorbs it
    final remainingTime = 2200 - stopwatch.elapsedMilliseconds;
    if (remainingTime > 0) {
      await Future.delayed(Duration(milliseconds: remainingTime));
    }

    if (!mounted) return;

    // ✅ THE EXIT FADE
    // Dissolve the text smoothly BEFORE telling main.dart to switch screens
    await _exitController.forward();

    FirebaseAnalytics.instance.logEvent(name: 'splash_completed');

    // Trigger the cross-fade routing
    widget.onInitializationComplete(hasSeenOnboarding);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Center(
          // Wrap everything in a FadeTransition tied to the EXIT controller
          child: FadeTransition(
            // Reversing the exit controller so 0.0 -> 1.0 fades out
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_brandName.length, (index) {
                // Build each letter individually
                return AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _letterOpacities[index].value,
                      child: SlideTransition(
                        position: _letterSlides[index],
                        child: Text(
                          _brandName[index],
                          style: AppTypography.headline.copyWith(
                            fontSize: 56, // Bold presence
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: 2.0, // Tight, clean spacing
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
