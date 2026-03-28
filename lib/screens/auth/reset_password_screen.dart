import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/utils/auth_ui_helper.dart';
import 'package:vango_parent_app/utils/validators.dart';
import 'package:vango_parent_app/services/auth_service.dart'; // ✅ NEW
import 'package:vango_parent_app/widgets/common_language_selector.dart'; // ✅ NEW
import 'package:vango_parent_app/widgets/common_text_field.dart'; // ✅ NEW
import 'package:vango_parent_app/utils/app_auth_exception.dart'; // ✅ NEW

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});
  final String email;
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // ✅ State Management Refactor
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier(false);
  final ValueNotifier<bool> _isConfirmPasswordVisible = ValueNotifier(false);
  final ValueNotifier<bool> _isSubmitPressed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(
      name: 'auth_screen_viewed',
      parameters: {'screen': 'reset_password'},
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _isLoading.dispose();
    _isPasswordVisible.dispose();
    _isConfirmPasswordVisible.dispose();
    _isSubmitPressed.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_isLoading.value) return;

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    final loc = AppLocalizations.of(context)!;
    _isLoading.value = true;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'password_reset'},
      );

      final otp = _otpController.text.trim();
      final newPassword = _passwordController.text.trim();

      await AuthService.instance.resetPasswordWithOtp(
        widget.email,
        otp,
        newPassword,
      ); // ✅ Pure Service Call

      FirebaseAnalytics.instance.logEvent(
        name: 'auth_success',
        parameters: {'method': 'password_reset'},
      );

      if (!mounted) return;
      AuthUiHelper.showMessage(context, loc.resetSuccess, isError: false);

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AppAuthException catch (e) {
      if (!mounted) return;
      AuthUiHelper.showMessage(context, e.message, isError: true);
    } catch (e, stack) {
      if (!mounted) return;
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Password Reset Failed',
      );
      AuthUiHelper.showMessage(
        context,
        AuthUiHelper.parseErrorKey(e),
        isError: true,
      );
    } finally {
      if (mounted) _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

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
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    CommonLanguageSelector(isDark: isDark),
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
                                      loc.resetTitle,
                                      style: AppTypography.headline.copyWith(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc.resetSubtitle,
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
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.email,
                                        style: AppTypography.headline.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      CommonTextField(
                                        controller: _otpController,
                                        label: loc.resetOtpLabel,
                                        hint: loc.resetOtpHint,
                                        icon: Icons.password_rounded,
                                        inputType: TextInputType.number,
                                        autofillHints: const [
                                          AutofillHints.oneTimeCode,
                                        ],
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(6),
                                        ],
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: (val) =>
                                            val == null || val.isEmpty
                                            ? loc.resetErrOtpReq
                                            : null,
                                      ),
                                      const SizedBox(height: 20),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isPasswordVisible,
                                        builder: (context, isVisible, _) {
                                          return CommonTextField(
                                            controller: _passwordController,
                                            label: loc.resetNewPassLabel,
                                            hint: loc.resetNewPassHint,
                                            icon: Icons.lock_outline_rounded,
                                            isPassword: true,
                                            isPasswordVisible: isVisible,
                                            autofillHints: const [
                                              AutofillHints.newPassword,
                                            ],
                                            onToggleVisibility: () =>
                                                _isPasswordVisible.value =
                                                    !isVisible,
                                            isDark: isDark,
                                            activeColor: accentColor,
                                            validator: (val) =>
                                                AppValidators.validateNewPassword(
                                                  val,
                                                  loc,
                                                ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      ValueListenableBuilder<bool>(
                                        valueListenable:
                                            _isConfirmPasswordVisible,
                                        builder: (context, isVisible, _) {
                                          return CommonTextField(
                                            controller:
                                                _confirmPasswordController,
                                            label: loc.resetConfirmPassLabel,
                                            hint: loc.resetConfirmPassHint,
                                            icon: Icons.lock_reset_rounded,
                                            isPassword: true,
                                            isPasswordVisible: isVisible,
                                            autofillHints: const [
                                              AutofillHints.newPassword,
                                            ],
                                            onToggleVisibility: () =>
                                                _isConfirmPasswordVisible
                                                        .value =
                                                    !isVisible,
                                            isDark: isDark,
                                            activeColor: accentColor,
                                            validator: (val) {
                                              if (val == null || val.isEmpty)
                                                return loc.resetErrConfirmReq;
                                              if (val !=
                                                  _passwordController.text)
                                                return loc.resetErrPassMismatch;
                                              return null;
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isSubmitPressed,
                                        builder: (context, isPressed, _) {
                                          return Semantics(
                                            button: true,
                                            label: isLoading
                                                ? "Loading, please wait"
                                                : loc.resetBtn,
                                            child: Listener(
                                              onPointerDown: (_) {
                                                if (!isLoading)
                                                  _isSubmitPressed.value = true;
                                              },
                                              onPointerUp: (_) {
                                                if (!isLoading)
                                                  _isSubmitPressed.value =
                                                      false;
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
                                                        : _handleReset,
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
                                                                  strokeWidth:
                                                                      3,
                                                                ),
                                                          )
                                                        : Text(loc.resetBtn),
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
