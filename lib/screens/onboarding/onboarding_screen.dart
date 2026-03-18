import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

// --- LOCALIZATION ENGINE ---
enum AppLanguage { english, sinhala, tamil }

const Map<AppLanguage, Map<String, String>> _localizedStrings = {
  AppLanguage.english: {
    'skip': 'Skip',
    'title_1': 'Track every ride',
    'body_1':
        'Live GPS, ETA predictions, and safety checks keep you in control.',
    'btn_1': "Let's go!",
    'title_2': 'Mark attendance instantly',
    'body_2': 'Smart toggles sync with the driver and optimize the route.',
    'btn_2': 'Set attendance',
    'title_3': 'Payments & finder in one app',
    'body_3': 'Pay van fees, discover new drivers, and chat securely.',
    'btn_3': 'Get started',
  },
  AppLanguage.sinhala: {
    'skip': 'මඟ හරින්න',
    'title_1': 'සෑම ගමනක්ම නිරීක්ෂණය කරන්න',
    'body_1':
        'සජීවී GPS, ETA අනාවැකි සහ ආරක්ෂක පරීක්ෂාවන් මඟින් ඔබව දැනුවත් කරයි.',
    'btn_1': "අපි යමු!",
    'title_2': 'පැමිණීම ක්ෂණිකව සටහන් කරන්න',
    'body_2': 'රියදුරු සමඟ සමමුහුර්ත වී ගමන් මාර්ගය ප්‍රශස්ත කරයි.',
    'btn_2': 'පැමිණීම සටහන් කරන්න',
    'title_3': 'ගෙවීම් සහ සෙවුම් එකම යෙදුමකින්',
    'body_3': 'ගාස්තු ගෙවන්න, නව රියදුරන් සොයන්න, සහ ආරක්ෂිතව කතාබස් කරන්න.',
    'btn_3': 'ආරම්භ කරන්න',
  },
  AppLanguage.tamil: {
    'skip': 'தவிர்',
    'title_1': 'ஒவ்வொரு பயணத்தையும் கண்காணிக்கவும்',
    'body_1':
        'நேரலை GPS, ETA கணிப்புகள் மற்றும் பாதுகாப்பு சோதனைகள் உங்களை கட்டுப்பாட்டில் வைக்கும்.',
    'btn_1': "போகலாம்!",
    'title_2': 'வருகையை உடனடியாக குறிக்கவும்',
    'body_2': 'ஓட்டுநருடன் ஒத்திசைக்கப்பட்டு பயண வழியை மேம்படுத்துகிறது.',
    'btn_2': 'வருகையை அமைக்கவும்',
    'title_3': 'கொடுப்பனவுகள் மற்றும் தேடல் ஒரே செயலியில்',
    'body_3':
        'கட்டணம் செலுத்துங்கள், புதிய ஓட்டுநர்களைக் கண்டறியுங்கள், பாதுகாப்பாக அரட்டையடிக்கவும்.',
    'btn_3': 'தொடங்கவும்',
  },
};

class _Analytics {
  static void logEvent(String eventName, {Map<String, dynamic>? properties}) {
    debugPrint('📈 [ANALYTICS] Event: $eventName | Props: $properties');
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  AppLanguage _currentLanguage = AppLanguage.english;

  Timer? _autoPlayTimer;
  bool _isAutoScrolling = false;

  static const List<_Slide> _slides = [
    _Slide(
      titleKey: 'title_1',
      bodyKey: 'body_1',
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=600&q=60',
      buttonLabelKey: 'btn_1',
    ),
    _Slide(
      titleKey: 'title_2',
      bodyKey: 'body_2',
      imageUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=600&q=60',
      buttonLabelKey: 'btn_2',
    ),
    _Slide(
      titleKey: 'title_3',
      bodyKey: 'body_3',
      imageUrl:
          'https://images.unsplash.com/photo-1521791055366-0d553872125f?auto=format&fit=crop&w=600&q=60',
      buttonLabelKey: 'btn_3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _Analytics.logEvent('onboarding_started');
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
              duration: const Duration(milliseconds: 600),
              // ✅ iOS POLISH: Softer, more controlled ease curve
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

  String _t(String key) => _localizedStrings[_currentLanguage]?[key] ?? key;

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
      debugPrint('💾 [PERSISTENCE] Onboarding marked as completed.');
    } catch (e) {
      debugPrint('❌ [ERROR] Failed to save onboarding state: $e');
    } finally {
      if (mounted) {
        widget.onFinished();
      }
    }
  }

  void _goToNextPage() {
    final isLastPage = _currentPage == _slides.length - 1;

    _Analytics.logEvent(
      'onboarding_cta_clicked',
      properties: {'slide_index': _currentPage, 'is_last_page': isLastPage},
    );

    if (isLastPage) {
      _Analytics.logEvent('onboarding_completed');
      // ✅ TRIGGER PERSISTENCE HERE
      _markOnboardingCompleted();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 400),
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
            duration: const Duration(milliseconds: 300),
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
      label: "Select Language. Currently ${_getLanguageName(_currentLanguage)}",
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: PopupMenuButton<AppLanguage>(
          onSelected: (AppLanguage newValue) {
            HapticFeedback.selectionClick();
            setState(() => _currentLanguage = newValue);
            _Analytics.logEvent(
              'language_changed',
              properties: {'language': newValue.name},
            );
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
            final isSelected = _currentLanguage == lang;
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
                  _getLanguageName(_currentLanguage),
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

  Widget _buildCard(_Slide slide, bool isDark) {
    final cardColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.5)
        : AppColors.accent.withOpacity(0.15);
    final isLastPage = _currentPage == _slides.length - 1;

    return Semantics(
      label: "${_t(slide.titleKey)}. ${_t(slide.bodyKey)}",
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
            duration: const Duration(milliseconds: 500),
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
              key: ValueKey(slide.titleKey),
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
                    title: _t(slide.titleKey),
                    body: _t(slide.bodyKey),
                    buttonLabel: _t(slide.buttonLabelKey),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: _currentPage == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentPage > 0) {
            _onUserInteraction();
            _controller.previousPage(
              duration: const Duration(milliseconds: 400),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLanguageSelector(isDark),
                              Semantics(
                                button: true,
                                label: "Skip onboarding",
                                child: TextButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _Analytics.logEvent(
                                      'onboarding_skip_clicked',
                                      properties: {'slide_index': _currentPage},
                                    );
                                    Future.delayed(
                                      const Duration(milliseconds: 150),
                                      () {
                                        // ✅ TRIGGER PERSISTENCE HERE ON SKIP TOO
                                        _markOnboardingCompleted();
                                      },
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: textColor,
                                    overlayColor: textColor.withOpacity(0.1),
                                  ),
                                  child: Text(
                                    _t('skip'),
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
                              // ✅ iOS POLISH: ClampingScrollPhysics stops the exaggerated over-scroll bounce
                              physics: const ClampingScrollPhysics(),
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                                _Analytics.logEvent(
                                  'onboarding_slide_viewed',
                                  properties: {'slide_index': index},
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
                                child: _buildCard(_slides[index], isDark),
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
  }
}

class _Slide {
  const _Slide({
    required this.titleKey,
    required this.bodyKey,
    required this.imageUrl,
    required this.buttonLabelKey,
  });

  final String titleKey;
  final String bodyKey;
  final String imageUrl;
  final String buttonLabelKey;
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
                  HapticFeedback.mediumImpact();
                } else {
                  HapticFeedback.lightImpact();
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
