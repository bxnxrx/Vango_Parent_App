import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/utils/auth_ui_helper.dart';
import 'package:vango_parent_app/services/auth_service.dart'; // ✅ NEW
import 'package:vango_parent_app/widgets/common_language_selector.dart';
import 'package:vango_parent_app/utils/app_auth_exception.dart'; // ✅ NEW

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

  // ✅ State Management Refactor
  final ValueNotifier<int> _secondsLeft = ValueNotifier(_countdownSeconds);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<bool> _resending = ValueNotifier(false);
  final ValueNotifier<bool> _isSubmitPressed = ValueNotifier(false);

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
      node.addListener(() => setState(() {})); // Focus visual updates
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
    _secondsLeft.dispose();
    _isLoading.dispose();
    _resending.dispose();
    _isSubmitPressed.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown?.cancel();
    _secondsLeft.value = _countdownSeconds;
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft.value > 0) {
        _secondsLeft.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    if (_isLoading.value) return;

    final loc = AppLocalizations.of(context)!;
    final code = _controllers.map((c) => c.text).join();

    if (code.length < _digits) {
      HapticFeedback.heavyImpact();
      AuthUiHelper.showMessage(context, loc.otpErrReq, isError: true);
      return;
    }

    _isLoading.value = true;
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
        await AuthService.instance.verifyAuthOtp(
          // ✅ Pure Service Call
          isEmail: widget.isEmail,
          identifier: widget.identifier,
          token: code,
        );
      }

      FirebaseAnalytics.instance.logEvent(
        name: 'auth_success',
        parameters: {'method': 'otp_verify'},
      );
      if (mounted) await widget.onVerified();
    } on AppAuthException catch (e) {
      if (!mounted) return;
      AuthUiHelper.showMessage(context, e.message, isError: true);
      _clearOtp();
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
      _clearOtp();
    } finally {
      if (mounted) _isLoading.value = false;
    }
  }

  void _clearOtp() {
    for (var c in _controllers) {
      c.clear();
    }
    if (mounted) _focusNodes[0].requestFocus();
  }

  Future<void> _handleResend() async {
    if (_secondsLeft.value > 0 || _resending.value) return;

    final loc = AppLocalizations.of(context)!;
    _resending.value = true;
    HapticFeedback.selectionClick();

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'otp_resend'},
      );

      if (widget.onResendOverride != null) {
        await widget.onResendOverride!();
      } else {
        await AuthService.instance.resendAuthOtp(
          // ✅ Pure Service Call
          isEmail: widget.isEmail,
          identifier: widget.identifier,
        );
      }

      FirebaseAnalytics.instance.logEvent(
        name: 'auth_success',
        parameters: {'method': 'otp_resend'},
      );
      if (!mounted) return;
      AuthUiHelper.showMessage(context, loc.otpSuccessResend, isError: false);
      _startCountdown();
    } on AppAuthException catch (e) {
      if (!mounted) return;
      AuthUiHelper.showMessage(context, e.message, isError: true);
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
      if (mounted) _resending.value = false;
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
              color: isDark ? AppColors.darkSurfaceStrong : AppColors.accent,
            ),
            child: SafeArea(
              bottom: false,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isLoading,
                builder: (context, isLoading, _) {
                  return AbsorbPointer(
                    absorbing: isLoading,
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
                                        ValueListenableBuilder<bool>(
                                          valueListenable: _resending,
                                          builder: (context, resending, _) {
                                            return ValueListenableBuilder<int>(
                                              valueListenable: _secondsLeft,
                                              builder: (context, secondsLeft, _) {
                                                return Semantics(
                                                  button: true,
                                                  label: resending
                                                      ? "Loading, please wait"
                                                      : loc.otpResendBtn,
                                                  child: GestureDetector(
                                                    onTap: _handleResend,
                                                    child: Text(
                                                      secondsLeft > 0
                                                          ? loc.otpResendIn(
                                                              secondsLeft
                                                                  .toString(),
                                                            )
                                                          : loc.otpResendBtn,
                                                      style: AppTypography.label
                                                          .copyWith(
                                                            color:
                                                                secondsLeft > 0
                                                                ? Colors.grey
                                                                : accentColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: _isSubmitPressed,
                                      builder: (context, isPressed, _) {
                                        return Semantics(
                                          button: true,
                                          label: isLoading
                                              ? "Loading, please wait"
                                              : loc.otpVerifyBtn,
                                          child: Listener(
                                            onPointerDown: (_) {
                                              if (!isLoading)
                                                _isSubmitPressed.value = true;
                                            },
                                            onPointerUp: (_) {
                                              if (!isLoading)
                                                _isSubmitPressed.value = false;
                                            },
                                            child: AnimatedScale(
                                              scale: isPressed ? 0.96 : 1.0,
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              curve: Curves.easeInOut,
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: 56,
                                                child: ElevatedButton(
                                                  onPressed: isLoading
                                                      ? null
                                                      : _handleVerify,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        accentColor,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    textStyle: AppTypography
                                                        .title
                                                        .copyWith(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                  ),
                                                  child: isLoading
                                                      ? const SizedBox(
                                                          width: 24,
                                                          height: 24,
                                                          child:
                                                              CircularProgressIndicator(
                                                                color: Colors
                                                                    .white,
                                                                strokeWidth: 3,
                                                              ),
                                                        )
                                                      : Text(loc.otpVerifyBtn),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
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
              if (value.isNotEmpty && index < _digits - 1)
                _focusNodes[index + 1].requestFocus();
              if (value.isEmpty && index > 0)
                _focusNodes[index - 1].requestFocus();
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
