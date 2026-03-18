import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  final String _brandName = "VanGo";
  late List<Animation<double>> _letterOpacities;
  late List<Animation<Offset>> _letterSlides;
  late List<Animation<double>> _letterBlurs;

  int _lastHapticIndex = -1;

  @override
  void initState() {
    super.initState();

    FirebaseCrashlytics.instance.log("Animated Splash Screen Initialized");

    // --- SETUP ENTRANCE ANIMATION ---
    _entranceController = AnimationController(
      vsync: this,
      // The entrance remains incredibly fast and snappy
      duration: const Duration(milliseconds: 800),
    );

    _letterOpacities = [];
    _letterSlides = [];
    _letterBlurs = [];

    final double step = 0.25 / _brandName.length;

    for (int i = 0; i < _brandName.length; i++) {
      final double start = i * step;
      final double end = start + 0.75;

      _letterOpacities.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );

      _letterSlides.add(
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOutExpo),
          ),
        ),
      );

      _letterBlurs.add(
        Tween<double>(begin: 5.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end - 0.2, curve: Curves.easeOutQuart),
          ),
        ),
      );
    }

    // --- THE HAPTIC SWEEP ---
    _entranceController.addListener(() {
      final double val = _entranceController.value;

      for (int i = 0; i < _brandName.length; i++) {
        final double triggerPoint = i * step + 0.05;

        if (val >= triggerPoint && _lastHapticIndex < i) {
          _lastHapticIndex = i;

          if (i == _brandName.length - 1) {
            HapticFeedback.lightImpact();
          } else {
            HapticFeedback.selectionClick();
          }
        }
      }
    });

    _entranceController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();
    FirebaseAnalytics.instance.logEvent(name: 'splash_started');

    late bool hasSeenOnboarding;

    try {
      await Future.wait([
        SharedPreferences.getInstance().then((prefs) {
          hasSeenOnboarding = prefs.getBool('onboarding_completed') ?? false;
        }),
        Future.delayed(const Duration(milliseconds: 100)),
      ]);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Splash Screen Warmup Failed',
      );
      hasSeenOnboarding = false;
    }

    stopwatch.stop();

    // ✅ ENTERPRISE PREMIUM REST TIMING
    // 800ms for animation to finish + 800ms of resting time = 1600ms total.
    // This gives the logo exactly enough time to "settle" before transitioning.
    final remainingTime = 1600 - stopwatch.elapsedMilliseconds;
    if (remainingTime > 0) {
      await Future.delayed(Duration(milliseconds: remainingTime));
    }

    if (!mounted) return;

    FirebaseAnalytics.instance.logEvent(name: 'splash_completed');
    widget.onInitializationComplete(hasSeenOnboarding);
  }

  @override
  void dispose() {
    _entranceController.dispose();
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_brandName.length, (index) {
              return AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _letterBlurs[index].value,
                      sigmaY: _letterBlurs[index].value,
                    ),
                    child: Opacity(
                      opacity: _letterOpacities[index].value,
                      child: SlideTransition(
                        position: _letterSlides[index],
                        child: Text(
                          _brandName[index],
                          style: AppTypography.headline.copyWith(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: 1.5,
                          ),
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
    );
  }
}
