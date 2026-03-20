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
    'title': 'Create New Password',
    'subtitle':
        'Enter the OTP sent to your email and your new secure password.',
    'otp_label': 'Reset Code (OTP)',
    'otp_hint': '6-digit code',
    'new_pass_label': 'New Password',
    'new_pass_hint': '********',
    'confirm_pass_label': 'Confirm Password',
    'confirm_pass_hint': '********',
    'reset_btn': 'Set New Password',
    'err_otp_req': 'OTP code is required',
    'err_pass_req': 'Password is required',
    'err_pass_len': 'Password must be at least 8 characters',
    'err_pass_up': 'Must contain at least one uppercase letter',
    'err_pass_low': 'Must contain at least one lowercase letter',
    'err_confirm_req': 'Please confirm your password',
    'err_pass_mismatch': 'Passwords do not match',
    'success_reset': 'Password successfully reset! Please log in.',
  },
  AppLanguage.sinhala: {
    'title': 'නව මුරපදයක් සාදන්න',
    'subtitle':
        'ඔබගේ විද්‍යුත් තැපෑලට යැවූ OTP කේතය සහ නව මුරපදය ඇතුළත් කරන්න.',
    'otp_label': 'යළි පිහිටුවීමේ කේතය (OTP)',
    'otp_hint': 'ඉලක්කම් 6ක කේතය',
    'new_pass_label': 'නව මුරපදය',
    'new_pass_hint': '********',
    'confirm_pass_label': 'මුරපදය තහවුරු කරන්න',
    'confirm_pass_hint': '********',
    'reset_btn': 'නව මුරපදය සකසන්න',
    'err_otp_req': 'OTP කේතය අවශ්‍යයි',
    'err_pass_req': 'මුරපදය අවශ්‍යයි',
    'err_pass_len': 'මුරපදය අවම වශයෙන් අකුරු 8ක් විය යුතුය',
    'err_pass_up': 'අවම වශයෙන් එක් කැපිටල් අකුරක් අඩංගු විය යුතුය',
    'err_pass_low': 'අවම වශයෙන් එක් සිම්පල් අකුරක් අඩංගු විය යුතුය',
    'err_confirm_req': 'කරුණාකර ඔබගේ මුරපදය තහවුරු කරන්න',
    'err_pass_mismatch': 'මුරපද නොගැලපේ',
    'success_reset': 'මුරපදය සාර්ථකව යළි පිහිටුවන ලදී! කරුණාකර ලොග් වන්න.',
  },
  AppLanguage.tamil: {
    'title': 'புதிய கடவுச்சொல்லை உருவாக்கு',
    'subtitle':
        'மின்னஞ்சலுக்கு அனுப்பப்பட்ட OTP மற்றும் புதிய கடவுச்சொல்லை உள்ளிடவும்.',
    'otp_label': 'மீட்டமைப்பு குறியீடு (OTP)',
    'otp_hint': '6 இலக்க குறியீடு',
    'new_pass_label': 'புதிய கடவுச்சொல்',
    'new_pass_hint': '********',
    'confirm_pass_label': 'கடவுச்சொல்லை உறுதிப்படுத்தவும்',
    'confirm_pass_hint': '********',
    'reset_btn': 'கடவுச்சொல்லை அமைக்கவும்',
    'err_otp_req': 'OTP குறியீடு தேவை',
    'err_pass_req': 'கடவுச்சொல் தேவை',
    'err_pass_len': 'கடவுச்சொல் குறைந்தது 8 எழுத்துகளைக் கொண்டிருக்க வேண்டும்',
    'err_pass_up': 'குறைந்தது ஒரு பெரிய எழுத்து இருக்க வேண்டும்',
    'err_pass_low': 'குறைந்தது ஒரு சிறிய எழுத்து இருக்க வேண்டும்',
    'err_confirm_req': 'உங்கள் கடவுச்சொல்லை உறுதிப்படுத்தவும்',
    'err_pass_mismatch': 'கடவுச்சொற்கள் பொருந்தவில்லை',
    'success_reset': 'கடவுச்சொல் வெற்றிகரமாக மாற்றப்பட்டது! உள்நுழையவும்.',
  },
};

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
    FirebaseAnalytics.instance.logEvent(name: 'reset_password_viewed');
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return _t('err_pass_req');
    if (value.length < 8) return _t('err_pass_len');
    if (!value.contains(RegExp(r'[A-Z]'))) return _t('err_pass_up');
    if (!value.contains(RegExp(r'[a-z]'))) return _t('err_pass_low');
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return _t('err_confirm_req');
    if (value != _passwordController.text) return _t('err_pass_mismatch');
    return null;
  }

  Future<void> _handleReset() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    try {
      FirebaseAnalytics.instance.logEvent(name: 'password_reset_attempt');

      final otp = _otpController.text.trim();
      final newPassword = _passwordController.text.trim();

      // 1. Verify the OTP
      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.recovery,
      );

      // 2. Update the password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) return;
      AuthUiHelper.showMessage(context, _t('success_reset'), isError: false);

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Password Reset Failed',
      );
      AuthUiHelper.showMessage(
        context,
        _t(AuthUiHelper.parseErrorKey(e)),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                                          HapticFeedback.lightImpact();
                                          Navigator.pop(context);
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
                                      _t('subtitle'),
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

                                      // OTP Field
                                      _buildTextField(
                                        controller: _otpController,
                                        label: _t('otp_label'),
                                        hint: _t('otp_hint'),
                                        icon: Icons.password_rounded,
                                        inputType: TextInputType.number,
                                        autofillHints: const [
                                          AutofillHints.oneTimeCode,
                                        ], // ✅ AUTOFILL ONE TIME CODE
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: (val) =>
                                            val == null || val.isEmpty
                                            ? _t('err_otp_req')
                                            : null,
                                      ),
                                      const SizedBox(height: 20),

                                      // New Password Field
                                      _buildTextField(
                                        controller: _passwordController,
                                        label: _t('new_pass_label'),
                                        hint: _t('new_pass_hint'),
                                        icon: Icons.lock_outline_rounded,
                                        isPassword: true,
                                        isPasswordVisible: _isPasswordVisible,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ], // ✅ AUTOFILL NEW PASSWORD
                                        onToggleVisibility: () {
                                          setState(
                                            () => _isPasswordVisible =
                                                !_isPasswordVisible,
                                          );
                                        },
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: _validatePassword,
                                      ),
                                      const SizedBox(height: 20),

                                      // Confirm Password Field
                                      _buildTextField(
                                        controller: _confirmPasswordController,
                                        label: _t('confirm_pass_label'),
                                        hint: _t('confirm_pass_hint'),
                                        icon: Icons.lock_reset_rounded,
                                        isPassword: true,
                                        isPasswordVisible:
                                            _isConfirmPasswordVisible,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ], // ✅ AUTOFILL NEW PASSWORD
                                        onToggleVisibility: () {
                                          setState(
                                            () => _isConfirmPasswordVisible =
                                                !_isConfirmPasswordVisible,
                                          );
                                        },
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: _validateConfirmPassword,
                                      ),
                                      const SizedBox(height: 32),

                                      // Submit Button
                                      Semantics(
                                        button: true,
                                        label: _t(
                                          'reset_btn',
                                        ), // ✅ ACCESSIBILITY FIX
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
                                                    : Text(_t('reset_btn')),
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

    // ✅ ACCESSIBILITY FIX
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
                    HapticFeedback.lightImpact();
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
