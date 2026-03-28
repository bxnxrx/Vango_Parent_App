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
import 'package:vango_parent_app/utils/validators.dart'; // ✅ NEW
import 'package:vango_parent_app/widgets/common_language_selector.dart'; // ✅ NEW

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

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitPressed = false;

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
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    final loc = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'password_reset'},
      );

      final otp = _otpController.text.trim();
      final newPassword = _passwordController.text.trim();

      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.recovery,
      );
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      FirebaseAnalytics.instance.logEvent(
        name: 'auth_success',
        parameters: {'method': 'password_reset'},
      );

      if (!mounted) return;
      AuthUiHelper.showMessage(context, loc.resetSuccess, isError: false);

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
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
                                      _buildTextField(
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
                                      _buildTextField(
                                        controller: _passwordController,
                                        label: loc.resetNewPassLabel,
                                        hint: loc.resetNewPassHint,
                                        icon: Icons.lock_outline_rounded,
                                        isPassword: true,
                                        isPasswordVisible: _isPasswordVisible,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                        onToggleVisibility: () => setState(
                                          () => _isPasswordVisible =
                                              !_isPasswordVisible,
                                        ),
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: (val) =>
                                            AppValidators.validateNewPassword(
                                              val,
                                              loc,
                                            ), // ✅ Uses Validator File
                                      ),
                                      const SizedBox(height: 20),
                                      _buildTextField(
                                        controller: _confirmPasswordController,
                                        label: loc.resetConfirmPassLabel,
                                        hint: loc.resetConfirmPassHint,
                                        icon: Icons.lock_reset_rounded,
                                        isPassword: true,
                                        isPasswordVisible:
                                            _isConfirmPasswordVisible,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                        onToggleVisibility: () => setState(
                                          () => _isConfirmPasswordVisible =
                                              !_isConfirmPasswordVisible,
                                        ),
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: (val) {
                                          if (val == null || val.isEmpty)
                                            return loc.resetErrConfirmReq;
                                          if (val != _passwordController.text)
                                            return loc.resetErrPassMismatch;
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      Semantics(
                                        button: true,
                                        label: _isLoading
                                            ? "Loading, please wait"
                                            : loc.resetBtn,
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
                                                    : _handleReset,
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
                                                    : Text(loc.resetBtn),
                                              ),
                                            ),
                                          ),
                                        ),
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
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    required Color activeColor,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    final borderColor = isDark ? AppColors.darkStroke : Colors.grey.shade300;
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
        obscureText: isPassword && !isPasswordVisible,
        autofillHints: autofillHints,
        inputFormatters: inputFormatters,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
        style: AppTypography.body.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.body.copyWith(color: hintColor),
          hintText: hint,
          hintStyle: AppTypography.body.copyWith(color: hintColor),
          prefixIcon: Icon(icon, color: hintColor, size: 22),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: activeColor, width: 2),
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
