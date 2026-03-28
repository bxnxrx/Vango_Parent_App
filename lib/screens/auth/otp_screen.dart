import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/services/language_service.dart';
import 'package:vango_parent_app/utils/auth_ui_helper.dart';
import 'package:vango_parent_app/widgets/common_language_selector.dart'; // ✅ NEW

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
    FirebaseAnalytics.instance.logEvent(
      name: 'auth_screen_viewed',
      parameters: {'screen': 'otp_verify'},
    );
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

    final loc = AppLocalizations.of(context)!;
    final code = _controllers.map((c) => c.text).join();

    if (code.length < _digits) {
      HapticFeedback.heavyImpact();
      AuthUiHelper.showMessage(context, loc.otpErrReq, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'otp_verify'},
      );
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
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_success',
        parameters: {'method': 'otp_verify'},
      );
      if (mounted) await widget.onVerified();
    } catch (e, stack) {
      if (!mounted) return;
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'OTP Verification Failed',
      );
      AuthUiHelper.showMessage(
        context,
        AuthUiHelper.parseErrorKey(e),
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

    final loc = AppLocalizations.of(context)!;
    setState(() => _resending = true);
    HapticFeedback.selectionClick();

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'otp_resend'},
      );
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
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_success',
        parameters: {'method': 'otp_resend'},
      );
      if (!mounted) return;
      AuthUiHelper.showMessage(context, loc.otpSuccessResend, isError: false);
      _startCountdown();
    } catch (e, stack) {
      if (!mounted) return;
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'OTP Resend Failed',
      );
      AuthUiHelper.showMessage(
        context,
        AuthUiHelper.parseErrorKey(e),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageService.instance.currentLanguage,
      builder: (context, currentLang, child) {
        final subText = widget.isEmail
            ? loc.otpSubtitleEmail(widget.identifier)
            : loc.otpSubtitlePhone(widget.identifier);

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
                                          HapticFeedback.selectionClick();
                                          widget.onBack();
                                        },
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    CommonLanguageSelector(
                                      isDark: isDark,
                                    ), // ✅ Uses Central Widget
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
                                      loc.otpTitle,
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          loc.otpResendQ,
                                          style: AppTypography.body.copyWith(
                                            color: textSecondary,
                                          ),
                                        ),
                                        Semantics(
                                          button: true,
                                          label: _resending
                                              ? "Loading, please wait"
                                              : loc.otpResendBtn,
                                          child: GestureDetector(
                                            onTap: _handleResend,
                                            child: Text(
                                              _secondsLeft > 0
                                                  ? loc.otpResendIn(
                                                      _secondsLeft.toString(),
                                                    )
                                                  : loc.otpResendBtn,
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
                                    Semantics(
                                      button: true,
                                      label: _isLoading
                                          ? "Loading, please wait"
                                          : loc.otpVerifyBtn,
                                      child: Listener(
                                        onPointerDown: (_) {
                                          if (!_isLoading) {
                                            setState(
                                              () => _isSubmitPressed = true,
                                            );
                                          }
                                        },
                                        onPointerUp: (_) {
                                          if (!_isLoading) {
                                            setState(
                                              () => _isSubmitPressed = false,
                                            );
                                          }
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
                                                  : Text(loc.otpVerifyBtn),
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.length > 1) {
                final chars = digits.split('');
                for (int i = 0; i < _digits; i++) {
                  if (i < chars.length) {
                    _controllers[i].text = chars[i];
                    _controllers[i].selection = const TextSelection.collapsed(
                      offset: 1,
                    );
                  }
                }
                _focusNodes[_digits - 1].requestFocus();
                if (chars.length >= _digits) _handleVerify();
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
