import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/services/language_service.dart';
import 'package:vango_parent_app/utils/auth_ui_helper.dart'; // ✅ UI Helper

const Map<AppLanguage, Map<String, String>> _localizedStrings = {
  AppLanguage.english: {
    'title': 'Verify Account',
    'subtitle_phone': 'Enter the 6-digit code sent to\n@id',
    'subtitle_email': 'Enter the 6-digit code sent to\n@id',
    'resend_q': "Didn't receive the code? ",
    'resend_in': 'Resend in @sec s',
    'resend_btn': 'Resend Code',
    'verify_btn': 'Verify & Proceed',
    'err_req': 'Please enter all 6 digits',
    'success_resend': 'Verification code resent successfully',
  },
  AppLanguage.sinhala: {
    'title': 'ගිණුම තහවුරු කරන්න',
    'subtitle_phone': '@id වෙත යැවූ ඉලක්කම් 6ක කේතය ඇතුළත් කරන්න',
    'subtitle_email': '@id වෙත යැවූ ඉලක්කම් 6ක කේතය ඇතුළත් කරන්න',
    'resend_q': "කේතය ලැබුණේ නැද්ද? ",
    'resend_in': 'තත්පර @sec කින් නැවත යවන්න',
    'resend_btn': 'නැවත යවන්න',
    'verify_btn': 'තහවුරු කර ඉදිරියට',
    'err_req': 'කරුණාකර ඉලක්කම් 6ම ඇතුළත් කරන්න',
    'success_resend': 'තහවුරු කිරීමේ කේතය සාර්ථකව නැවත යවන ලදී',
  },
  AppLanguage.tamil: {
    'title': 'கணக்கை சரிபார்க்கவும்',
    'subtitle_phone': '@id க்கு அனுப்பப்பட்ட 6 இலக்க குறியீட்டை உள்ளிடவும்',
    'subtitle_email': '@id க்கு அனுப்பப்பட்ட 6 இலக்க குறியீட்டை உள்ளிடவும்',
    'resend_q': "குறியீடு கிடைக்கவில்லையா? ",
    'resend_in': '@sec வினாடிகளில் மீண்டும் அனுப்பு',
    'resend_btn': 'மீண்டும் அனுப்பு',
    'verify_btn': 'சரிபார்த்து தொடரவும்',
    'err_req': 'அனைத்து 6 இலக்கங்களையும் உள்ளிடவும்',
    'success_resend':
        'சரிபார்ப்புக் குறியீடு வெற்றிகரமாக மீண்டும் அனுப்பப்பட்டது',
  },
};

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.identifier,
    this.isEmail = false,
    required this.onVerified,
    required this.onBack,
    this.onVerifyOverride,
    this.onResendOverride,
  });

  final String identifier;
  final bool isEmail;
  final Future<void> Function() onVerified;
  final VoidCallback onBack;
  final Future<void> Function(String code)? onVerifyOverride;
  final Future<void> Function()? onResendOverride;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _digits = 6;
  static const int _countdownSeconds = 60;

  final List<TextEditingController> _controllers = List.generate(
    _digits,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _digits,
    (_) => FocusNode(),
  );

  Timer? _countdown;
  int _secondsLeft = _countdownSeconds;
  bool _isLoading = false;
  bool _resending = false;
  bool _isSubmitPressed = false;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'otp_screen_viewed');
    _startCountdown();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _focusNodes[0].requestFocus();
    });

    for (var node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _t(String key) =>
      _localizedStrings[LanguageService.instance.currentLanguage.value]?[key] ??
      key;

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

  void _startCountdown() {
    _countdown?.cancel();
    setState(() => _secondsLeft = _countdownSeconds);
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleVerify() async {
    if (_isLoading) return;

    final code = _controllers.map((c) => c.text).join();
    if (code.length < _digits) {
      HapticFeedback.lightImpact();
      AuthUiHelper.showMessage(context, _t('err_req'), isError: true);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    try {
      FirebaseAnalytics.instance.logEvent(name: 'otp_verification_attempt');

      if (widget.onVerifyOverride != null) {
        await widget.onVerifyOverride!(code);
      } else {
        await Supabase.instance.client.auth.verifyOTP(
          type: widget.isEmail ? OtpType.email : OtpType.sms,
          token: code,
          email: widget.isEmail ? widget.identifier : null,
          phone: !widget.isEmail ? widget.identifier : null,
        );
      }

      if (mounted) await widget.onVerified();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'OTP Verification Failed',
      );
      AuthUiHelper.showMessage(
        context,
        _t(AuthUiHelper.parseErrorKey(e)),
        isError: true,
      );
      for (var c in _controllers) {
        c.clear();
      }
      if (mounted) _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_secondsLeft > 0 || _resending) return;

    setState(() => _resending = true);
    HapticFeedback.lightImpact();

    try {
      FirebaseAnalytics.instance.logEvent(name: 'otp_resend_attempt');

      if (widget.onResendOverride != null) {
        await widget.onResendOverride!();
      } else {
        if (widget.isEmail) {
          await Supabase.instance.client.auth.signInWithOtp(
            email: widget.identifier,
          );
        } else {
          await Supabase.instance.client.auth.signInWithOtp(
            phone: widget.identifier,
          );
        }
      }

      AuthUiHelper.showMessage(context, _t('success_resend'), isError: false);
      _startCountdown();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'OTP Resend Failed',
      );
      AuthUiHelper.showMessage(
        context,
        _t(AuthUiHelper.parseErrorKey(e)),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Widget _buildLanguageSelector() {
    return Semantics(
      button: true, // ✅ ACCESSIBILITY FIX
      label: 'Select Language',
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: PopupMenuButton<AppLanguage>(
          onSelected: (AppLanguage newValue) {
            HapticFeedback.lightImpact();
            LanguageService.instance.setLanguage(newValue);
            FirebaseAnalytics.instance.logEvent(
              name: 'lang_changed',
              parameters: {'lang': newValue.name},
            );
          },
          color: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          offset: const Offset(0, 45),
          itemBuilder: (context) => AppLanguage.values.map((lang) {
            final isSelected =
                LanguageService.instance.currentLanguage.value == lang;
            return PopupMenuItem<AppLanguage>(
              value: lang,
              child: Center(
                child: Text(
                  _getLanguageName(lang),
                  style: AppTypography.body.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppColors.darkTextSecondary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getLanguageName(
                    LanguageService.instance.currentLanguage.value,
                  ),
                  style: AppTypography.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 16,
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
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageService.instance.currentLanguage,
      builder: (context, currentLang, child) {
        final subKey = widget.isEmail ? 'subtitle_email' : 'subtitle_phone';
        final subText = _t(subKey).replaceAll('@id', widget.identifier);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: bgColor,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: bgColor,
            resizeToAvoidBottomInset: false,
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: CustomPaint(
                painter: _HeaderBackgroundPainter(
                  color: isDark
                      ? AppColors.darkSurfaceStrong
                      : AppColors.accent,
                ),
                child: SafeArea(
                  bottom: false,
                  child: AbsorbPointer(
                    absorbing: _isLoading,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom +
                                MediaQuery.of(context).padding.bottom +
                                32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Semantics(
                                      button: true,
                                      label: 'Back',
                                      child: IconButton(
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          widget.onBack();
                                        },
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    _buildLanguageSelector(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _t('title'),
                                      style: AppTypography.headline.copyWith(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      subText,
                                      style: AppTypography.body.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.08,
                              ),
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.5 : 0.15,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // OTP Boxes
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        _digits,
                                        (index) => _buildOtpBox(
                                          index,
                                          isDark,
                                          accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Resend Logic
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _t('resend_q'),
                                          style: AppTypography.body.copyWith(
                                            color: textSecondary,
                                          ),
                                        ),
                                        Semantics(
                                          button: true,
                                          label: _t('resend_btn'),
                                          child: GestureDetector(
                                            onTap: _handleResend,
                                            child: Text(
                                              _secondsLeft > 0
                                                  ? _t('resend_in').replaceAll(
                                                      '@sec',
                                                      _secondsLeft.toString(),
                                                    )
                                                  : _t('resend_btn'),
                                              style: AppTypography.label
                                                  .copyWith(
                                                    color: _secondsLeft > 0
                                                        ? Colors.grey
                                                        : accentColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),

                                    // Verify Button
                                    Semantics(
                                      button: true,
                                      label: _t('verify_btn'),
                                      child: Listener(
                                        onPointerDown: (_) {
                                          if (!_isLoading)
                                            setState(
                                              () => _isSubmitPressed = true,
                                            );
                                        },
                                        onPointerUp: (_) {
                                          if (!_isLoading)
                                            setState(
                                              () => _isSubmitPressed = false,
                                            );
                                        },
                                        child: AnimatedScale(
                                          scale: _isSubmitPressed ? 0.96 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          curve: Curves.easeInOut,
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _handleVerify,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: accentColor,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                textStyle: AppTypography.title
                                                    .copyWith(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 3,
                                                          ),
                                                    )
                                                  : Text(_t('verify_btn')),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpBox(int index, bool isDark, Color accentColor) {
    final isFocused = _focusNodes[index].hasFocus;
    final hasText = _controllers[index].text.isNotEmpty;

    final unselectedBg = isDark
        ? AppColors.darkBackground
        : Colors.grey.shade100;
    final unselectedBorder = isDark
        ? AppColors.darkStroke
        : Colors.grey.shade300;

    // ✅ ACCESSIBILITY FIX: Wrapped in Semantics
    return Semantics(
      label: "OTP Digit ${index + 1}",
      textField: true,
      child: Container(
        width: 46,
        height: 56,
        decoration: BoxDecoration(
          color: isFocused ? Colors.transparent : unselectedBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused
                ? accentColor
                : (hasText
                      ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
                      : unselectedBorder),
            width: isFocused ? 2 : 1.5,
          ),
        ),
        child: Center(
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            style: AppTypography.headline.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: const InputDecoration(
              counterText: "",
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              if (value.length > 1) {
                final chars = value.split('');
                for (int i = 0; i < _digits; i++) {
                  if (i < chars.length) {
                    _controllers[i].text = chars[i];
                  }
                }
                _focusNodes[_digits - 1].requestFocus();
                if (chars.length == _digits) {
                  _handleVerify();
                }
                return;
              }

              if (value.isNotEmpty && index < _digits - 1) {
                _focusNodes[index + 1].requestFocus();
              }
              if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        ),
      ),
    );
  }
}

class _HeaderBackgroundPainter extends CustomPainter {
  final Color color;
  _HeaderBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.lineTo(0, 370);
    path.quadraticBezierTo(size.width / 2, 450, size.width, 370);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
