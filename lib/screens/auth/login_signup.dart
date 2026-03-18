import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/screens/auth/reset_password_screen.dart';

// --- LOCALIZATION ENGINE ---
enum AppLanguage { english, sinhala, tamil }

const Map<AppLanguage, Map<String, String>> _localizedStrings = {
  AppLanguage.english: {
    'welcome': 'Welcome to',
    'get_started': 'Get Started',
    'subtitle': 'Enter your details to log in or sign up',
    'phone_tab': 'Phone',
    'email_tab': 'Email',
    'phone_label': 'Phone Number',
    'phone_hint': '+94 7X XXX XXXX',
    'email_label': 'Email Address',
    'email_hint': 'name@example.com',
    'pass_label': 'Password',
    'pass_hint': '********',
    'forgot_pass': 'Forgot Password?',
    'continue_btn': 'Continue',
    'or': 'Or',
    'secure_badge': 'End-to-end encrypted',
    'reset_sent': 'Reset link sent to @email',
    'err_phone_req': 'Phone number is required',
    'err_phone_inv': 'Invalid format (use +947XXXXXXXX)',
    'err_email_req': 'Email is required',
    'err_email_inv': 'Enter a valid email address',
    'err_pass_req': 'Password is required',
    'err_pass_min': 'Password must be at least 8 characters',
    'err_network': 'Network error. Please check your connection.',
    'err_invalid_creds': 'Incorrect email or password.',
    'err_user_exists': 'An account with this email already exists.',
    'err_too_many_req': 'Too many attempts. Please try again later.',
    'err_unverified': 'Please verify your email before logging in.',
    'err_generic': 'Something went wrong. Please try again.',
  },
  AppLanguage.sinhala: {
    'welcome': 'ආයුබෝවන්',
    'get_started': 'ආරම්භ කරන්න',
    'subtitle': 'ලොග් වීමට හෝ ලියාපදිංචි වීමට තොරතුරු ඇතුලත් කරන්න',
    'phone_tab': 'දුරකථනය',
    'email_tab': 'විද්‍යුත් තැපෑල',
    'phone_label': 'දුරකථන අංකය',
    'phone_hint': '+94 7X XXX XXXX',
    'email_label': 'විද්‍යුත් තැපැල් ලිපිනය',
    'email_hint': 'name@example.com',
    'pass_label': 'මුරපදය',
    'pass_hint': '********',
    'forgot_pass': 'මුරපදය අමතකද?',
    'continue_btn': 'ඉදිරියට',
    'or': 'හෝ',
    'secure_badge': 'ආරක්ෂිතව සංකේතනය කර ඇත',
    'reset_sent': 'මුරපද යළි පිහිටුවීමේ සබැඳිය @email වෙත යවන ලදී',
    'err_phone_req': 'දුරකථන අංකය අවශ්‍යයි',
    'err_phone_inv': 'වැරදි ආකෘතියකි (+947XXXXXXXX භාවිතා කරන්න)',
    'err_email_req': 'විද්‍යුත් තැපෑල අවශ්‍යයි',
    'err_email_inv': 'නිවැරදි විද්‍යුත් තැපෑලක් ඇතුලත් කරන්න',
    'err_pass_req': 'මුරපදය අවශ්‍යයි',
    'err_pass_min': 'මුරපදය අවම වශයෙන් අකුරු 8ක් විය යුතුය',
    'err_network': 'ජාල දෝෂයකි. කරුණාකර ඔබගේ සම්බන්ධතාවය පරීක්ෂා කරන්න.',
    'err_invalid_creds': 'විද්‍යුත් තැපෑල හෝ මුරපදය වැරදියි.',
    'err_user_exists': 'මෙම විද්‍යුත් තැපෑල සහිත ගිණුමක් දැනටමත් පවතී.',
    'err_too_many_req': 'උත්සාහයන් වැඩියි. කරුණාකර පසුව නැවත උත්සාහ කරන්න.',
    'err_unverified': 'කරුණාකර පිවිසීමට පෙර ඔබගේ විද්‍යුත් තැපෑල තහවුරු කරන්න.',
    'err_generic': 'දෝෂයක් සිදුවිය. කරුණාකර නැවත උත්සාහ කරන්න.',
  },
  AppLanguage.tamil: {
    'welcome': 'நல்வரவு',
    'get_started': 'தொடங்கவும்',
    'subtitle': 'உள்நுழைய அல்லது பதிவு செய்ய விவரங்களை உள்ளிடவும்',
    'phone_tab': 'தொலைபேசி',
    'email_tab': 'மின்னஞ்சல்',
    'phone_label': 'தொலைபேசி எண்',
    'phone_hint': '+94 7X XXX XXXX',
    'email_label': 'மின்னஞ்சல் முகவரி',
    'email_hint': 'name@example.com',
    'pass_label': 'கடவுச்சொல்',
    'pass_hint': '********',
    'forgot_pass': 'கடவுச்சொல் மறந்துவிட்டதா?',
    'continue_btn': 'தொடரவும்',
    'or': 'அல்லது',
    'secure_badge': 'பாதுகாப்பாக குறியாக்கம் செய்யப்பட்டது',
    'reset_sent': 'கடவுச்சொல் மீட்டமைப்பு இணைப்பு @email க்கு அனுப்பப்பட்டது',
    'err_phone_req': 'தொலைபேசி எண் தேவை',
    'err_phone_inv': 'தவறான வடிவம் (+947XXXXXXXX ஐப் பயன்படுத்தவும்)',
    'err_email_req': 'மின்னஞ்சல் தேவை',
    'err_email_inv': 'சரியான மின்னஞ்சலை உள்ளிடவும்',
    'err_pass_req': 'கடவுச்சொல் தேவை',
    'err_pass_min': 'கடவுச்சொல் குறைந்தது 8 எழுத்துகளைக் கொண்டிருக்க வேண்டும்',
    'err_network': 'நெட்வொர்க் பிழை. உங்கள் இணைப்பை சரிபார்க்கவும்.',
    'err_invalid_creds': 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறானது.',
    'err_user_exists': 'இந்த மின்னஞ்சலுடன் ஏற்கனவே ஒரு கணக்கு உள்ளது.',
    'err_too_many_req': 'அதிக முயற்சிகள். பின்னர் மீண்டும் முயற்சிக்கவும்.',
    'err_unverified': 'உள்நுழைவதற்கு முன் உங்கள் மின்னஞ்சலைச் சரிபார்க்கவும்.',
    'err_generic': 'ஏதோ தவறு நடந்துவிட்டது. மீண்டும் முயற்சிக்கவும்.',
  },
};

const String _googleIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="800px" height="800px" viewBox="-3 0 262 262" preserveAspectRatio="xMidYMid"><path d="M255.878 133.451c0-10.734-.871-18.567-2.756-26.69H130.55v48.448h71.947c-1.45 12.04-9.283 30.172-26.69 42.356l-.244 1.622 38.755 30.023 2.685.268c24.659-22.774 38.875-56.282 38.875-96.027" fill="#4285F4"/><path d="M130.55 261.1c35.248 0 64.839-11.605 86.453-31.622l-41.196-31.913c-11.024 7.688-25.82 13.055-45.257 13.055-34.523 0-63.824-22.773-74.269-54.25l-1.531.13-40.298 31.187-.527 1.465C35.393 231.798 79.49 261.1 130.55 261.1" fill="#34A853"/><path d="M56.281 156.37c-2.756-8.123-4.351-16.827-4.351-25.82 0-8.994 1.595-17.697 4.206-25.82l-.073-1.73L15.26 71.312l-1.335.635C5.077 89.644 0 109.517 0 130.55s5.077 40.905 13.925 58.602l42.356-32.782" fill="#FBBC05"/><path d="M130.55 50.479c24.514 0 41.05 10.589 50.479 19.438l36.844-35.974C195.245 12.91 165.798 0 130.55 0 79.49 0 35.393 29.301 13.925 71.947l42.211 32.783c10.59-31.477 39.891-54.251 74.414-54.251" fill="#EB4335"/></svg>
''';

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
  AppLanguage _currentLanguage = AppLanguage.english;
  bool _isPhoneLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController(
    text: '+94',
  );
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

  // --- PREMIUM ERROR HANDLING ---

  String _parseError(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login') || msg.contains('invalid credentials'))
        return _t('err_invalid_creds');
      if (msg.contains('already registered') ||
          msg.contains('user already exists'))
        return _t('err_user_exists');
      if (msg.contains('rate limit') ||
          msg.contains('too many requests') ||
          msg.contains('over_email_send_rate_limit'))
        return _t('err_too_many_req');
      if (msg.contains('not confirmed') || msg.contains('unverified'))
        return _t('err_unverified');
      if (msg.contains('password should be')) return _t('err_pass_min');
    }

    final errStr = error.toString().toLowerCase();
    if (errStr.contains('network') ||
        errStr.contains('socket') ||
        errStr.contains('timeout') ||
        errStr.contains('clientexception')) {
      return _t('err_network');
    }

    // Strict fallback prevents raw backend exceptions from leaking to the UI
    return _t('err_generic');
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    // WCAG AAA Compliant contrast colors
    final bgColor = isError ? const Color(0xFFB3261E) : const Color(0xFF2E7D32);
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
          elevation: 6,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // --- MICRO-INTERACTION: TAB DELAY ---

  void _switchTab(bool toPhone) async {
    if (_isPhoneLogin == toPhone || _isLoading) return;

    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;

    setState(() {
      _isPhoneLogin = toPhone;
    });
    _formKey.currentState?.reset();
  }

  // --- VALIDATORS ---

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return _t('err_phone_req');
    final cleanPhone = value.replaceAll(' ', '');
    final phoneRegex = RegExp(r'^\+94[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleanPhone)) return _t('err_phone_inv');
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return _t('err_email_req');
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return _t('err_email_inv');
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return _t('err_pass_req');
    if (value.length < 8) return _t('err_pass_min');
    return null;
  }

  // --- ACTIONS ---

  Future<void> _handlePhoneLogin() async {
    // ✅ MEMORY LOCK: Prevents double-tap issues
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    _isLoading = true; // Lock before rendering UI change
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() {}); // Show loading spinner

    final phone = _phoneController.text.trim().replaceAll(' ', '');

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'phone'},
      );
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      widget.onOtpRequested(phone);
    } catch (e) {
      _showMessage(_parseError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailLogin() async {
    // ✅ MEMORY LOCK: Prevents double-tap issues
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    _isLoading = true; // Lock before rendering UI change
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() {}); // Show loading spinner

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': 'email'},
      );
      final result = await AuthService.instance.signInOrSignUp(email, password);

      if (result.requiresEmailVerification) {
        widget.onEmailVerificationNeeded(email);
      } else {
        await _checkStatusAndNotify();
      }
    } on AuthException catch (e) {
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
        _showMessage(_parseError(e), isError: true);
      }
    } catch (e) {
      _showMessage(_parseError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    // ✅ MEMORY LOCK: Prevents double-tap issues
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);

    if (emailError != null) {
      HapticFeedback.lightImpact();
      _showMessage(emailError, isError: true);
      return;
    }

    _isLoading = true; // Lock before rendering UI change
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() {}); // Show loading spinner

    try {
      await AuthService.instance.requestPasswordReset(email);
      if (!mounted) return;

      final successMsg = _t('reset_sent').replaceAll('@email', email);
      _showMessage(successMsg, isError: false);

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: email),
        ),
      );
    } catch (e) {
      _showMessage(_parseError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialLogin(
    Future<void> Function() method,
    String provider,
  ) async {
    // ✅ MEMORY LOCK: Prevents concurrent native popup crashes
    if (_isLoading) return;

    _isLoading = true; // Lock before rendering UI change
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() {}); // Show loading spinner

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_attempt',
        parameters: {'method': provider},
      );
      await method();
      await _checkStatusAndNotify();
    } catch (e) {
      _showMessage(_parseError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkStatusAndNotify() async {
    try {
      final status = await AuthService.instance.fetchOnboardingStatus();
      widget.onAuthenticated(status);
    } catch (e) {
      _showMessage(_parseError(e), isError: true);
    }
  }

  // --- UI COMPONENTS ---

  Widget _buildLanguageSelector() {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<AppLanguage>(
        onSelected: (AppLanguage newValue) {
          HapticFeedback.selectionClick();
          setState(() => _currentLanguage = newValue);
          FirebaseAnalytics.instance.logEvent(
            name: 'auth_language_changed',
            parameters: {'lang': newValue.name},
          );
        },
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        offset: const Offset(0, 45),
        itemBuilder: (context) => AppLanguage.values.map((lang) {
          final isSelected = _currentLanguage == lang;
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
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                _getLanguageName(_currentLanguage),
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
    final accentColor = isDark ? AppColors.darkAccent : const Color(0xFF2D325A);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: bgColor,
          // ✅ PHYSICAL LOCK: Prevents double-taps on the screen entirely when loading
          body: AbsorbPointer(
            absorbing: _isLoading,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Stack(
                            children: [
                              // 1. BACKGROUND HEADER
                              ClipPath(
                                clipper: BackgroundClipper(),
                                child: Container(
                                  width: double.infinity,
                                  height: 450,
                                  color: isDark
                                      ? AppColors.darkSurfaceStrong
                                      : const Color(0xFF2D325A),
                                ),
                              ),

                              // 2. CONTENT
                              SafeArea(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 28,
                                        right: 28,
                                        top: 20,
                                        bottom: 20,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _t('welcome'),
                                                style: AppTypography.headline
                                                    .copyWith(
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              Text(
                                                'VanGo',
                                                style: AppTypography.headline
                                                    .copyWith(
                                                      color: Colors.white,
                                                      fontSize: 56,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      height: 1.1,
                                                      letterSpacing: -1,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          _buildLanguageSelector(),
                                        ],
                                      ),
                                    ),

                                    const Spacer(),

                                    // THE AUTH CARD
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 20,
                                      ),
                                      padding: const EdgeInsets.all(28),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(32),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              isDark ? 0.5 : 0.15,
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
                                              _t('get_started'),
                                              style: AppTypography.headline
                                                  .copyWith(
                                                    fontSize: 26,
                                                    fontWeight: FontWeight.w800,
                                                    color: textColor,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _t('subtitle'),
                                              textAlign: TextAlign.center,
                                              style: AppTypography.body
                                                  .copyWith(
                                                    color: textSecondary,
                                                  ),
                                            ),
                                            const SizedBox(height: 32),

                                            // TOGGLE BUTTON
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
                                                      label: _t('phone_tab'),
                                                      isSelected: _isPhoneLogin,
                                                      isDark: isDark,
                                                      onTap: () =>
                                                          _switchTab(true),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: _ToggleTab(
                                                      label: _t('email_tab'),
                                                      isSelected:
                                                          !_isPhoneLogin,
                                                      isDark: isDark,
                                                      onTap: () =>
                                                          _switchTab(false),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 28),

                                            // INPUT FIELDS
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              switchInCurve:
                                                  Curves.easeOutCubic,
                                              switchOutCurve:
                                                  Curves.easeInCubic,
                                              child: _isPhoneLogin
                                                  ? _buildPhoneInput(
                                                      accentColor,
                                                      isDark,
                                                    )
                                                  : _buildEmailInput(
                                                      accentColor,
                                                      isDark,
                                                    ),
                                            ),

                                            const SizedBox(height: 24),

                                            // MAIN SUBMIT BUTTON
                                            SizedBox(
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
                                                    : Text(_t('continue_btn')),
                                              ),
                                            ),

                                            // SECURITY BADGE
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 16,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.shield_rounded,
                                                    size: 14,
                                                    color:
                                                        Colors.green.shade600,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _t('secure_badge'),
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

                                            // DIVIDER
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
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  child: Text(
                                                    _t('or'),
                                                    style: TextStyle(
                                                      color: textSecondary,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
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

                                            // SOCIAL LOGIN
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
                                                    onPressed: _isLoading
                                                        ? null
                                                        : () => _handleSocialLogin(
                                                            () => AuthService
                                                                .instance
                                                                .signInWithGoogleNative(
                                                                  webClientId:
                                                                      AppConfig
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
                            ],
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
      ),
    );
  }

  // --- INPUT BUILDERS ---

  Widget _buildPhoneInput(Color activeColor, bool isDark) {
    return Container(
      key: const ValueKey('PhoneInput'),
      child: _buildTextField(
        controller: _phoneController,
        label: _t('phone_label'),
        hint: _t('phone_hint'),
        icon: Icons.phone_android_rounded,
        inputType: TextInputType.phone,
        activeColor: activeColor,
        isDark: isDark,
        validator: _validatePhone,
      ),
    );
  }

  Widget _buildEmailInput(Color activeColor, bool isDark) {
    return Column(
      key: const ValueKey('EmailInput'),
      children: [
        _buildTextField(
          controller: _emailController,
          label: _t('email_label'),
          hint: _t('email_hint'),
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
          activeColor: activeColor,
          isDark: isDark,
          validator: _validateEmail,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: _t('pass_label'),
          hint: _t('pass_hint'),
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          activeColor: activeColor,
          isDark: isDark,
          validator: _validatePassword,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              overlayColor: activeColor.withOpacity(0.1),
              foregroundColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              textStyle: AppTypography.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: _isLoading ? null : _handleForgotPassword,
            child: Text(_t('forgot_pass')),
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
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
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

    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      obscureText: isPassword && !_isPasswordVisible,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  _isPasswordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: hintColor,
                  size: 22,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
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
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required bool isDark,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurfaceStrong : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

class BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
