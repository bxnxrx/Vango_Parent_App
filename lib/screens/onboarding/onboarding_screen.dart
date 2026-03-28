import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:vango_parent_app/l10n/app_localizations.dart'; // ✅ Added Localization Import
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/services/language_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  Timer? _autoPlayTimer;
  bool _isAutoScrolling = false;

  // ✅ Converted to Dynamic Builder approach to pass AppLocalizations smoothly
  static final List<_Slide> _slides = [
    _Slide(
      titleBuilder: (loc) => loc.onboardingTitle1,
      bodyBuilder: (loc) => loc.onboardingBody1,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=600&q=60',
      buttonLabelBuilder: (loc) => loc.onboardingBtn1,
    ),
    _Slide(
      titleBuilder: (loc) => loc.onboardingTitle2,
      bodyBuilder: (loc) => loc.onboardingBody2,
      imageUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=600&q=60',
      buttonLabelBuilder: (loc) => loc.onboardingBtn2,
    ),
    _Slide(
      titleBuilder: (loc) => loc.onboardingTitle3,
      bodyBuilder: (loc) => loc.onboardingBody3,
      imageUrl:
          'https://images.unsplash.com/photo-1521791055366-0d553872125f?auto=format&fit=crop&w=600&q=60',
      buttonLabelBuilder: (loc) => loc.onboardingBtn3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'onboarding_started');
    _startAutoPlay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final slide in _slides) {
      precacheImage(CachedNetworkImageProvider(slide.imageUrl), context);
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();

    final isLastPage = _currentPage == _slides.length - 1;
    final duration = isLastPage ? 5 : 2;

    _autoPlayTimer = Timer(Duration(seconds: duration), () {
      if (!mounted || !_controller.hasClients) return;

      if (!isLastPage) {
        _isAutoScrolling = true;
        _controller
            .nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            )
            .then((_) {
              if (mounted) _isAutoScrolling = false;
            });
      }
    });
  }

  void _onUserInteraction() {
    _autoPlayTimer?.cancel();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _startAutoPlay();
    });
  }

  String _getLanguageName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.sinhala:
        return 'සිංහල';
      case AppLanguage.tamil:
        return 'தமிழ்';
    }
  }

  Future<void> _markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to save onboarding state',
      );
    } finally {
      if (mounted) {
        widget.onFinished();
      }
    }
  }

  void _goToNextPage() {
    final isLastPage = _currentPage == _slides.length - 1;

    FirebaseAnalytics.instance.logEvent(
      name: 'onboarding_cta_clicked',
      parameters: {
        'slide_index': _currentPage,
        'is_last_page': isLastPage ? 'true' : 'false',
      },
    );

    if (isLastPage) {
      FirebaseAnalytics.instance.logEvent(name: 'onboarding_completed');
      _markOnboardingCompleted();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildDots(bool isDark) {
    final activeColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final inactiveColor = isDark ? AppColors.darkStroke : AppColors.stroke;

    return Semantics(
      label: "Page ${_currentPage + 1} of ${_slides.length}",
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_slides.length, (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(40),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLanguageSelector(bool isDark) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final bgColor = isDark
        ? AppColors.darkSurfaceStrong
        : AppColors.surfaceStrong;
    final borderColor = isDark ? AppColors.darkStroke : AppColors.stroke;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;
    const double selectorWidth = 140.0;

    return Semantics(
      button: true,
      label: "Select Language",
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: PopupMenuButton<AppLanguage>(
          onSelected: (AppLanguage newValue) {
            HapticFeedback.selectionClick();
            LanguageService.instance.setLanguage(newValue);
          },
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          offset: const Offset(0, 50),
          constraints: const BoxConstraints(
            minWidth: selectorWidth,
            maxWidth: selectorWidth,
          ),
          itemBuilder: (context) => AppLanguage.values.map((lang) {
            final isSelected =
                LanguageService.instance.currentLanguage.value == lang;
            return PopupMenuItem<AppLanguage>(
              value: lang,
              child: Center(
                child: Text(
                  _getLanguageName(lang),
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: isSelected ? accentColor : textColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
          child: Container(
            width: selectorWidth,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.language_rounded, color: textColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  _getLanguageName(
                    LanguageService.instance.currentLanguage.value,
                  ),
                  style: AppTypography.label.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(_Slide slide, bool isDark, AppLocalizations loc) {
    final cardColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : AppColors.accent.withValues(alpha: 0.15);
    final isLastPage = _currentPage == _slides.length - 1;

    // Evaluated keys
    final title = slide.titleBuilder(loc);
    final body = slide.bodyBuilder(loc);
    final btnLabel = slide.buttonLabelBuilder(loc);

    return Semantics(
      label: "$title. $body",
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.04, 0.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutQuart,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey(title),
              children: [
                Expanded(
                  flex: 5,
                  child: ExcludeSemantics(
                    child: _SlideImage(
                      imageUrl: slide.imageUrl,
                      isDark: isDark,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: _SlideDetails(
                    title: title,
                    body: body,
                    buttonLabel: btnLabel,
                    isLastPage: isLastPage,
                    isDark: isDark,
                    onNext: _goToNextPage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; // ✅ Added localization instance
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageService.instance.currentLanguage,
      builder: (context, currentLang, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: PopScope(
            canPop: _currentPage == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (_currentPage > 0) {
                _onUserInteraction();
                _controller.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            child: Scaffold(
              backgroundColor: bgColor,
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxWidth = constraints.maxWidth > 600
                        ? 500
                        : double.infinity;

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 20,
                                bottom: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildLanguageSelector(isDark),
                                  Semantics(
                                    button: true,
                                    label: "Skip onboarding",
                                    child: TextButton(
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        FirebaseAnalytics.instance.logEvent(
                                          name: 'onboarding_skip_clicked',
                                          parameters: {
                                            'slide_index': _currentPage,
                                          },
                                        );
                                        Future.delayed(
                                          const Duration(milliseconds: 150),
                                          () => _markOnboardingCompleted(),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: textColor,
                                        overlayColor: textColor.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      child: Text(
                                        loc.onboardingSkip, // ✅ Use Localized Value
                                        style: AppTypography.label.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onPanDown: (_) => _onUserInteraction(),
                                child: PageView.builder(
                                  controller: _controller,
                                  physics: const ClampingScrollPhysics(),
                                  onPageChanged: (index) {
                                    setState(() => _currentPage = index);
                                    FirebaseAnalytics.instance.logEvent(
                                      name: 'onboarding_slide_viewed',
                                      parameters: {'slide_index': index},
                                    );

                                    if (!_isAutoScrolling) {
                                      HapticFeedback.selectionClick();
                                    }

                                    _startAutoPlay();
                                  },
                                  itemCount: _slides.length,
                                  itemBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 24,
                                      top: 8,
                                    ),
                                    child: _buildCard(
                                      _slides[index],
                                      isDark,
                                      loc,
                                    ), // Pass loc here
                                  ),
                                ),
                              ),
                            ),
                            _buildDots(isDark),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Slide {
  const _Slide({
    required this.titleBuilder,
    required this.bodyBuilder,
    required this.imageUrl,
    required this.buttonLabelBuilder,
  });
  final String Function(AppLocalizations) titleBuilder;
  final String Function(AppLocalizations) bodyBuilder;
  final String imageUrl;
  final String Function(AppLocalizations) buttonLabelBuilder;
}

class _SlideImage extends StatelessWidget {
  const _SlideImage({required this.imageUrl, required this.isDark});
  final String imageUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final placeholderColor = isDark
        ? AppColors.darkSurfaceStrong
        : AppColors.surfaceStrong;
    final indicatorColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: placeholderColor,
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: placeholderColor,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          size: 48,
        ),
      ),
    );
  }
}

class _SlideDetails extends StatefulWidget {
  const _SlideDetails({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.isLastPage,
    required this.isDark,
    required this.onNext,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final bool isLastPage;
  final bool isDark;
  final VoidCallback onNext;

  @override
  State<_SlideDetails> createState() => _SlideDetailsState();
}

class _SlideDetailsState extends State<_SlideDetails> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textSecondary = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final buttonBg = widget.isDark ? AppColors.darkAccent : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headline.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: textSecondary,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Semantics(
            button: true,
            label: widget.buttonLabel,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                if (widget.isLastPage) {
                  HapticFeedback.lightImpact();
                } else {
                  HapticFeedback.selectionClick();
                }
                widget.onNext();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedScale(
                scale: _isPressed ? 0.96 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: buttonBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isLastPage
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.buttonLabel,
                        style: AppTypography.title.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
