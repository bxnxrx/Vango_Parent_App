import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/screens/auth/reset_password_screen.dart';
import 'package:vango_parent_app/services/language_service.dart';
import 'package:vango_parent_app/utils/auth_ui_helper.dart';
import 'package:vango_parent_app/utils/validators.dart';
import 'package:vango_parent_app/widgets/common_language_selector.dart';
import 'package:vango_parent_app/widgets/common_text_field.dart'; // ✅ NEW
import 'package:vango_parent_app/utils/app_auth_exception.dart'; // ✅ NEW

const String _googleIconSvg =
    '''<svg xmlns="http://www.w3.org/2000/svg" width="800px" height="800px" viewBox="-3 0 262 262" preserveAspectRatio="xMidYMid"><path d="M255.878 133.451c0-10.734-.871-18.567-2.756-26.69H130.55v48.448h71.947c-1.45 12.04-9.283 30.172-26.69 42.356l-.244 1.622 38.755 30.023 2.685.268c24.659-22.774 38.875-56.282 38.875-96.027" fill="#4285F4"/><path d="M130.55 261.1c35.248 0 64.839-11.605 86.453-31.622l-41.196-31.913c-11.024 7.688-25.82 13.055-45.257 13.055-34.523 0-63.824-22.773-74.269-54.25l-1.531.13-40.298 31.187-.527 1.465C35.393 231.798 79.49 261.1 130.55 261.1" fill="#34A853"/><path d="M56.281 156.37c-2.756-8.123-4.351-16.827-4.351-25.82 0-8.994 1.595-17.697 4.206-25.82l-.073-1.73L15.26 71.312l-1.335.635C5.077 89.644 0 109.517 0 130.55s5.077 40.905 13.925 58.602l42.356-32.782" fill="#FBBC05"/><path d="M130.55 50.479c24.514 0 41.05 10.589 50.479 19.438l36.844-35.974C195.245 12.91 165.798 0 130.55 0 79.49 0 35.393 29.301 13.925 71.947l42.211 32.783c10.59-31.477 39.891-54.251 74.414-54.251" fill="#EB4335"/></svg>''';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({
    super.key,
    required this.onAuthenticated,
    required this.onOtpRequested,
    required this.onEmailVerificationNeeded,
  });

  final Function(OnboardingStatus) onAuthenticated;
  final Function(String phone) onOtpRequested;
  final Function(String email) onEmailVerificationNeeded;

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final ValueNotifier<bool> _isPhoneLogin = ValueNotifier(true);
  final ValueNotifier<bool> _isLoading = ValueNotifier(
    false,
  ); // ✅ State Management Refactor
  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier(false);
  final ValueNotifier<bool> _isSubmitPressed = ValueNotifier(false);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'auth_screen_viewed');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _isPhoneLogin.dispose();
    _isLoading.dispose();
    _isPasswordVisible.dispose();
    _isSubmitPressed.dispose();
    super.dispose();
  }

  void _switchTab(bool toPhone) async {
    if (_isPhoneLogin.value == toPhone || _isLoading.value) return;
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _isPhoneLogin.value = toPhone;
    _formKey.currentState?.reset();
  }

  Future<void> _handlePhoneLogin() async {
    if (_isLoading.value) return;
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    _isLoading.value = true;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    var phone = _phoneController.text.trim().replaceAll(' ', '');
    phone = '+94$phone';

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'phone'},
      );

      await AuthService.instance.signInWithPhone(phone); // ✅ Pure Service Call

      FirebaseAnalytics.instance.logEvent(
        name: 'auth_success',
        parameters: {'method': 'phone', 'step': 'otp_sent'},
      );
      widget.onOtpRequested(phone);
    } on AppAuthException catch (e) {
      if (!mounted) return;
      AuthUiHelper.showMessage(
        context,
        e.message,
        isError: true,
      ); // ✅ Typed Error
    } catch (e, stackTrace) {
      if (!mounted) return;
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Phone Auth Failed',
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

  Future<void> _handleEmailLogin() async {
    if (_isLoading.value) return;
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    _isLoading.value = true;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'email'},
      );

      final result = await AuthService.instance.signInOrSignUp(
        email,
        password,
      ); // ✅ Pure Service Call

      if (result.requiresEmailVerification) {
        FirebaseAnalytics.instance.logEvent(
          name: 'auth_success',
          parameters: {'method': 'email', 'step': 'verification_sent'},
        );
        widget.onEmailVerificationNeeded(email);
      } else {
        FirebaseAnalytics.instance.logEvent(
          name: 'auth_success',
          parameters: {'method': 'email', 'step': 'logged_in'},
        );
        await _checkStatusAndNotify();
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('email not confirmed') ||
          errorMessage.contains('email_not_confirmed')) {
        try {
          await AuthService.instance.resendEmailSignupOtp(
            email,
          ); // ✅ Pure Service Call
        } catch (_) {}
        widget.onEmailVerificationNeeded(email);
      } else {
        FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'Email Auth Failed',
        );
        AuthUiHelper.showMessage(
          context,
          AuthUiHelper.parseErrorKey(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) _isLoading.value = false;
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_isLoading.value) return;

    final loc = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final emailError = AppValidators.validateEmail(email, loc);

    if (emailError != null) {
      HapticFeedback.heavyImpact();
      AuthUiHelper.showMessage(context, emailError, isError: true);
      return;
    }

    _isLoading.value = true;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    try {
      final exists = await AuthService.instance.checkUserExists(
        email,
      ); // ✅ Pure Service Call

      if (!exists) {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        AuthUiHelper.showMessage(
          context,
          loc.loginErrUserNotFound,
          isError: true,
        );
        _isLoading.value = false;
        return;
      }

      await AuthService.instance.requestPasswordReset(
        email,
      ); // ✅ Pure Service Call
      if (!mounted) return;

      AuthUiHelper.showMessage(
        context,
        loc.loginResetSent(email),
        isError: false,
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: email),
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Forgot Password Request Failed',
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

  Future<void> _handleSocialLogin(
    Future<void> Function() method,
    String provider,
  ) async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    try {
      await method(); // ✅ Pure Service Call
      await _checkStatusAndNotify();
    } catch (e, stackTrace) {
      if (!mounted) return;
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Social Auth Failed',
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

  Future<void> _checkStatusAndNotify() async {
    try {
      final status = await AuthService.instance.fetchOnboardingStatus();
      if (!mounted) return;
      widget.onAuthenticated(status);
    } catch (e, stackTrace) {
      if (!mounted) return;
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Auth Status Check Failed',
      );
      AuthUiHelper.showMessage(
        context,
        AuthUiHelper.parseErrorKey(e),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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

    return ValueListenableBuilder<bool>(
      valueListenable: _isLoading,
      builder: (context, isLoading, _) {
        return Scaffold(
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
                child: AbsorbPointer(
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
                              padding: const EdgeInsets.only(
                                left: 28,
                                right: 28,
                                top: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.loginWelcome,
                                        style: AppTypography.headline.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'VanGo',
                                        style: AppTypography.headline.copyWith(
                                          color: Colors.white,
                                          fontSize: 56,
                                          fontWeight: FontWeight.bold,
                                          height: 1.1,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  CommonLanguageSelector(isDark: isDark),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.08,
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      loc.loginGetStarted,
                                      style: AppTypography.headline.copyWith(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc.loginSubtitle,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.body.copyWith(
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: _isPhoneLogin,
                                      builder: (context, isPhone, _) {
                                        return Column(
                                          children: [
                                            Container(
                                              height: 52,
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppColors.darkBackground
                                                    : Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: _ToggleTab(
                                                      label: loc.loginPhoneTab,
                                                      isSelected: isPhone,
                                                      isDark: isDark,
                                                      onTap: () =>
                                                          _switchTab(true),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: _ToggleTab(
                                                      label: loc.loginEmailTab,
                                                      isSelected: !isPhone,
                                                      isDark: isDark,
                                                      onTap: () =>
                                                          _switchTab(false),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 28),
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              child: isPhone
                                                  ? _buildPhoneInput(
                                                      accentColor,
                                                      isDark,
                                                      loc,
                                                    )
                                                  : _buildEmailInput(
                                                      accentColor,
                                                      isDark,
                                                      loc,
                                                    ),
                                            ),
                                            const SizedBox(height: 24),
                                            ValueListenableBuilder<bool>(
                                              valueListenable: _isSubmitPressed,
                                              builder: (context, isPressed, _) {
                                                return Listener(
                                                  onPointerDown: (_) {
                                                    if (!isLoading)
                                                      _isSubmitPressed.value =
                                                          true;
                                                  },
                                                  onPointerUp: (_) {
                                                    if (!isLoading)
                                                      _isSubmitPressed.value =
                                                          false;
                                                  },
                                                  child: AnimatedScale(
                                                    scale: isPressed
                                                        ? 0.96
                                                        : 1.0,
                                                    duration: const Duration(
                                                      milliseconds: 150,
                                                    ),
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      height: 56,
                                                      child: ElevatedButton(
                                                        onPressed: isLoading
                                                            ? null
                                                            : (isPhone
                                                                  ? _handlePhoneLogin
                                                                  : _handleEmailLogin),
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
                                                                    FontWeight
                                                                        .bold,
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
                                                                child: CircularProgressIndicator(
                                                                  color: Colors
                                                                      .white,
                                                                  strokeWidth:
                                                                      3,
                                                                ),
                                                              )
                                                            : Text(
                                                                loc.loginContinueBtn,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.shield_rounded,
                                            size: 14,
                                            color: Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            loc.loginSecureBadge,
                                            style: AppTypography.label.copyWith(
                                              color: textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: isDark
                                                ? AppColors.darkStroke
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            loc.loginOr,
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: isDark
                                                ? AppColors.darkStroke
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildSocialButton(
                                            icon: SvgPicture.string(
                                              _googleIconSvg,
                                              height: 24,
                                              width: 24,
                                            ),
                                            isDark: isDark,
                                            label: "Google",
                                            onPressed: isLoading
                                                ? null
                                                : () => _handleSocialLogin(
                                                    () => AuthService.instance
                                                        .signInWithGoogleNative(
                                                          webClientId: AppConfig
                                                              .googleWebClientId,
                                                        ),
                                                    'google',
                                                  ),
                                          ),
                                        ),
                                        if (Platform.isIOS) ...[
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildSocialButton(
                                              icon: Icon(
                                                Icons.apple,
                                                size: 28,
                                                color: textColor,
                                              ),
                                              isDark: isDark,
                                              label: "Apple",
                                              onPressed: isLoading
                                                  ? null
                                                  : () => _handleSocialLogin(
                                                      AuthService
                                                          .instance
                                                          .signInWithApple,
                                                      'apple',
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
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

  Widget _buildPhoneInput(
    Color activeColor,
    bool isDark,
    AppLocalizations loc,
  ) {
    return Container(
      key: const ValueKey('PhoneInput'),
      child: CommonTextField(
        controller: _phoneController,
        label: loc.loginPhoneLabel,
        hint: loc.loginPhoneHint,
        icon: Icons.phone_android_rounded,
        inputType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        activeColor: activeColor,
        isDark: isDark,
        validator: (v) => AppValidators.validatePhone(v, loc),
        prefixText: '+94 ',
      ),
    );
  }

  Widget _buildEmailInput(
    Color activeColor,
    bool isDark,
    AppLocalizations loc,
  ) {
    return Column(
      key: const ValueKey('EmailInput'),
      children: [
        CommonTextField(
          controller: _emailController,
          label: loc.loginEmailLabel,
          hint: loc.loginEmailHint,
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          activeColor: activeColor,
          isDark: isDark,
          validator: (v) => AppValidators.validateEmail(v, loc),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<bool>(
          valueListenable: _isPasswordVisible,
          builder: (context, isVisible, _) {
            return CommonTextField(
              controller: _passwordController,
              label: loc.loginPassLabel,
              hint: loc.loginPassHint,
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              isPasswordVisible: isVisible,
              onToggleVisibility: () =>
                  _isPasswordVisible.value = !_isPasswordVisible.value,
              autofillHints: const [AutofillHints.password],
              activeColor: activeColor,
              isDark: isDark,
              validator: (v) => AppValidators.validatePassword(v, loc),
            );
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              overlayColor: activeColor.withValues(alpha: 0.1),
              foregroundColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              textStyle: AppTypography.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: _isLoading.value ? null : _handleForgotPassword,
            child: Text(loc.loginForgotPass),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required bool isDark,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Semantics(
      button: true,
      label: "Login with $label",
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDark ? AppColors.darkStroke : Colors.grey.shade300,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: isDark
                ? AppColors.darkSurfaceStrong
                : Colors.transparent,
          ),
          child: icon,
        ),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurfaceStrong : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600),
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
