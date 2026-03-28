import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'package:vango_parent_app/utils/validators.dart'; // ✅ NEW
import 'package:vango_parent_app/widgets/common_language_selector.dart'; // ✅ NEW

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
  bool _isPhoneLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isSubmitPressed = false;

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
    super.dispose();
  }

  void _switchTab(bool toPhone) async {
    if (_isPhoneLogin == toPhone || _isLoading) return;
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _isPhoneLogin = toPhone);
    _formKey.currentState?.reset();
  }

  Future<void> _handlePhoneLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    _isLoading = true;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {});

    var phone = _phoneController.text.trim().replaceAll(' ', '');
    phone = '+94$phone';

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'phone'},
      );
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_success',
        parameters: {'method': 'phone', 'step': 'otp_sent'},
      );
      widget.onOtpRequested(phone);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    _isLoading = true;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {});

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'email'},
      );
      final result = await AuthService.instance.signInOrSignUp(email, password);

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
    } on AuthException catch (e, stackTrace) {
      if (!mounted) return;
      if (e.message.toLowerCase().contains('email not confirmed') ||
          e.code == 'email_not_confirmed') {
        try {
          await Supabase.instance.client.auth.resend(
            type: OtpType.signup,
            email: email,
          );
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
    } catch (e, stackTrace) {
      if (!mounted) return;
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Email Auth Exception',
      );
      AuthUiHelper.showMessage(
        context,
        AuthUiHelper.parseErrorKey(e),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_isLoading) return;

    final loc = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final emailError = AppValidators.validateEmail(
      email,
      loc,
    ); // ✅ Uses Validator

    if (emailError != null) {
      HapticFeedback.heavyImpact();
      AuthUiHelper.showMessage(context, emailError, isError: true);
      return;
    }

    _isLoading = true;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {});

    try {
      final res = await Supabase.instance.client
          .from('parents')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (res == null) {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        AuthUiHelper.showMessage(
          context,
          loc.loginErrUserNotFound,
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      await AuthService.instance.requestPasswordReset(email);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialLogin(
    Future<void> Function() method,
    String provider,
  ) async {
    if (_isLoading) return;

    _isLoading = true;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {});

    try {
      await method();
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
      if (mounted) setState(() => _isLoading = false);
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

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageService.instance.currentLanguage,
      builder: (context, currentLang, child) {
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
                                          style: AppTypography.headline
                                              .copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                                fontSize: 24,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        Text(
                                          'VanGo',
                                          style: AppTypography.headline
                                              .copyWith(
                                                color: Colors.white,
                                                fontSize: 56,
                                                fontWeight: FontWeight.bold,
                                                height: 1.1,
                                                letterSpacing: -1,
                                              ),
                                        ),
                                      ],
                                    ),
                                    CommonLanguageSelector(
                                      isDark: isDark,
                                    ), // ✅ Uses Central Widget
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
                                      Container(
                                        height: 52,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkBackground
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _ToggleTab(
                                                label: loc.loginPhoneTab,
                                                isSelected: _isPhoneLogin,
                                                isDark: isDark,
                                                onTap: () => _switchTab(true),
                                              ),
                                            ),
                                            Expanded(
                                              child: _ToggleTab(
                                                label: loc.loginEmailTab,
                                                isSelected: !_isPhoneLogin,
                                                isDark: isDark,
                                                onTap: () => _switchTab(false),
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
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        child: _isPhoneLogin
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
                                      Semantics(
                                        button: true,
                                        label: _isLoading
                                            ? "Loading, please wait"
                                            : loc.loginContinueBtn,
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
                                            scale: _isSubmitPressed
                                                ? 0.96
                                                : 1.0,
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
                                                    : (_isPhoneLogin
                                                          ? _handlePhoneLogin
                                                          : _handleEmailLogin),
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
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                ),
                                                child: _isLoading
                                                    ? const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 3,
                                                            ),
                                                      )
                                                    : Text(
                                                        loc.loginContinueBtn,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
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
                                              style: AppTypography.label
                                                  .copyWith(
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
                                              onPressed: _isLoading
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
                                                onPressed: _isLoading
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
      child: _buildTextField(
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
        validator: (v) =>
            AppValidators.validatePhone(v, loc), // ✅ Uses Validator File
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
        _buildTextField(
          controller: _emailController,
          label: loc.loginEmailLabel,
          hint: loc.loginEmailHint,
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          activeColor: activeColor,
          isDark: isDark,
          validator: (v) =>
              AppValidators.validateEmail(v, loc), // ✅ Uses Validator File
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: loc.loginPassLabel,
          hint: loc.loginPassHint,
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          onToggleVisibility: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
          autofillHints: const [AutofillHints.password],
          activeColor: activeColor,
          isDark: isDark,
          validator: (v) =>
              AppValidators.validatePassword(v, loc), // ✅ Uses Validator File
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
            onPressed: _isLoading ? null : _handleForgotPassword,
            child: Text(loc.loginForgotPass),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    required Color activeColor,
    required bool isDark,
    String? Function(String?)? validator,
    bool readOnly = false,
    String? prefixText,
  }) {
    final borderColor = isDark ? AppColors.darkStroke : Colors.grey.shade300;
    final readOnlyBorder = isDark ? Colors.transparent : Colors.grey.shade200;
    final readOnlyBg = isDark ? AppColors.darkBackground : Colors.grey.shade100;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final hintColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade500;

    return Semantics(
      label: label,
      textField: true,
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        textInputAction: isPassword
            ? TextInputAction.done
            : TextInputAction.next,
        obscureText: isPassword && !_isPasswordVisible,
        autofillHints: autofillHints,
        inputFormatters: inputFormatters,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
        style: AppTypography.body.copyWith(
          color: readOnly ? hintColor : textColor,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.body.copyWith(color: hintColor),
          hintText: hint,
          hintStyle: AppTypography.body.copyWith(color: hintColor),
          prefixIcon: Icon(icon, color: hintColor, size: 22),
          prefixText: prefixText,
          prefixStyle: AppTypography.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: hintColor,
                    size: 22,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    if (onToggleVisibility != null) onToggleVisibility();
                  },
                )
              : null,
          filled: readOnly,
          fillColor: readOnly
              ? readOnlyBg
              : (isDark ? AppColors.darkSurface : Colors.white),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: readOnly ? readOnlyBorder : borderColor,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: readOnly ? readOnlyBorder : activeColor,
              width: readOnly ? 1.5 : 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
      ),
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
