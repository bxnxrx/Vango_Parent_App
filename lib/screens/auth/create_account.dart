import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:vango_parent_app/screens/auth/otp_screen.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/services/language_service.dart';
import 'package:vango_parent_app/utils/auth_ui_helper.dart';

const Map<AppLanguage, Map<String, String>> _localizedStrings = {
  AppLanguage.english: {
    'title': 'Complete Profile',
    'header': 'Tell us about yourself',
    'subtitle': 'We need a few details to set up your parent account.',
    'section_personal': 'Personal Details',
    'full_name': 'Full Name',
    'full_name_hint': 'e.g. John Doe',
    'mobile': 'Mobile Number',
    'mobile_hint': '7X XXX XXXX',
    'relationship': 'Relationship',
    'rel_parent': 'Parent',
    'rel_guardian': 'Guardian',
    'rel_other': 'Other',
    'rel_hint': 'Select Type',
    'email_opt': 'Email Address (Optional)',
    'email_hint': 'name@example.com',
    'continue_btn': 'Continue',
    'sign_out_title': 'Cancel Setup?',
    'sign_out_body':
        'This will completely delete your account and you will need to register again.',
    'stay': 'Stay',
    'sign_out': 'Delete & Sign Out',
    'err_name_req': 'Full Name is required',
    'err_name_min': 'Name must be at least 3 characters',
    'err_phone_req': 'Mobile Number is required',
    'err_phone_inv': 'Invalid format',
    'err_email_inv': 'Enter a valid email address',
    'err_rel_req': 'Please select your relationship type.',
    'err_form': 'Please check the form for errors.',
    'err_generic': 'Something went wrong.',
  },
  AppLanguage.sinhala: {
    'title': 'පැතිකඩ සම්පූර්ණ කරන්න',
    'header': 'ඔබ ගැන අපට කියන්න',
    'subtitle': 'ඔබගේ ගිණුම සැකසීමට අපට විස්තර කිහිපයක් අවශ්‍යයි.',
    'section_personal': 'පුද්ගලික විස්තර',
    'full_name': 'සම්පූර්ණ නම',
    'full_name_hint': 'උදා: කසුන් පෙරේරා',
    'mobile': 'ජංගම දුරකථන අංකය',
    'mobile_hint': '7X XXX XXXX',
    'relationship': 'සම්බන්ධතාවය',
    'rel_parent': 'දෙමාපියන්',
    'rel_guardian': 'භාරකරු',
    'rel_other': 'වෙනත්',
    'rel_hint': 'වර්ගය තෝරන්න',
    'email_opt': 'විද්‍යුත් තැපෑල (විකල්ප)',
    'email_hint': 'name@example.com',
    'continue_btn': 'ඉදිරියට',
    'sign_out_title': 'අවලංගු කරන්නද?',
    'sign_out_body': 'මෙය ඔබගේ ගිණුම සම්පූර්ණයෙන්ම මකා දමනු ඇත.',
    'stay': 'රැඳී සිටින්න',
    'sign_out': 'මකා ඉවත් වන්න',
    'err_name_req': 'සම්පූර්ණ නම අවශ්‍යයි',
    'err_name_min': 'නම අවම වශයෙන් අකුරු 3ක් විය යුතුය',
    'err_phone_req': 'දුරකථන අංකය අවශ්‍යයි',
    'err_phone_inv': 'වැරදි ආකෘතියකි',
    'err_email_inv': 'නිවැරදි විද්‍යුත් තැපෑලක් ඇතුලත් කරන්න',
    'err_rel_req': 'කරුණාකර සම්බන්ධතා වර්ගය තෝරන්න.',
    'err_form': 'කරුණාකර පෝරමයේ දෝෂ පරීක්ෂා කරන්න.',
    'err_generic': 'දෝෂයක් සිදුවිය.',
  },
  AppLanguage.tamil: {
    'title': 'சுயவிவரத்தை முடிக்கவும்',
    'header': 'உங்களை பற்றி கூறுங்கள்',
    'subtitle': 'உங்கள் கணக்கை அமைக்க சில விவரங்கள் தேவை.',
    'section_personal': 'தனிப்பட்ட விவரங்கள்',
    'full_name': 'முழு பெயர்',
    'full_name_hint': 'எ.கா: ஜான் டோ',
    'mobile': 'கைபேசி எண்',
    'mobile_hint': '7X XXX XXXX',
    'relationship': 'உறவு',
    'rel_parent': 'பெற்றோர்',
    'rel_guardian': 'பாதுகாவலர்',
    'rel_other': 'மற்றவை',
    'rel_hint': 'வகையைத் தேர்ந்தெடுக்கவும்',
    'email_opt': 'மின்னஞ்சல் (விருப்பத்திற்குரியது)',
    'email_hint': 'name@example.com',
    'continue_btn': 'தொடரவும்',
    'sign_out_title': 'ரத்து செய்யவா?',
    'sign_out_body': 'இது உங்கள் கணக்கை முழுமையாக நீக்கிவிடும்.',
    'stay': 'தொடர்க',
    'sign_out': 'நீக்கி வெளியேறு',
    'err_name_req': 'முழு பெயர் தேவை',
    'err_name_min': 'பெயர் குறைந்தது 3 எழுத்துகளைக் கொண்டிருக்க வேண்டும்',
    'err_phone_req': 'தொலைபேசி எண் தேவை',
    'err_phone_inv': 'தவறான வடிவம்',
    'err_email_inv': 'சரியான மின்னஞ்சலை உள்ளிடவும்',
    'err_rel_req': 'உங்கள் உறவு வகையைத் தேர்ந்தெடுக்கவும்.',
    'err_form': 'படிவத்தில் உள்ள பிழைகளை சரிபார்க்கவும்.',
    'err_generic': 'ஏதோ தவறு நடந்துவிட்டது.',
  },
};

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    required this.onProfileCompleted,
    required this.onBack,
  });
  final VoidCallback onProfileCompleted;
  final VoidCallback onBack;
  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _isSubmitPressed = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _emailReadOnly = false;
  bool _phoneReadOnly = false;
  String? _selectedRelationship;
  final List<String> _relationshipTypes = ['Parent', 'Guardian', 'Other'];

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(
      name: 'auth_screen_viewed',
      parameters: {'screen': 'create_account'},
    );
    _autoDetectUser();
  }

  Future<void> _autoDetectUser() async {
    final user = AuthService.instance.currentUser;
    final cachedPhone = await AuthService.instance.getCachedPhone();

    if (mounted) {
      setState(() {
        if (user?.email != null && user!.email!.isNotEmpty) {
          _emailController.text = user.email!;
          _emailReadOnly = true;
        }

        // ✅ PHONE PARSING FIX: Handles both +94 and 94 variations safely
        if (user?.phone != null && user!.phone!.isNotEmpty) {
          String p = user.phone!;
          if (p.startsWith('+94'))
            p = p.substring(3);
          else if (p.startsWith('94') && p.length == 11)
            p = p.substring(2);
          _phoneController.text = p;
          _phoneReadOnly = true;
        } else if (cachedPhone != null && _phoneController.text.isEmpty) {
          String p = cachedPhone;
          if (p.startsWith('+94'))
            p = p.substring(3);
          else if (p.startsWith('94') && p.length == 11)
            p = p.substring(2);
          _phoneController.text = p;
        }
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return _t('err_name_req');
    if (value.trim().length < 3) return _t('err_name_min');
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return _t('err_phone_req');
    final cleanPhone = value.replaceAll(' ', '');
    final phoneRegex = RegExp(r'^[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleanPhone)) return _t('err_phone_inv');
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return _t('err_email_inv');
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      AuthUiHelper.showMessage(context, _t('err_form'), isError: true);
      return;
    }
    if (_selectedRelationship == null) {
      HapticFeedback.heavyImpact();
      AuthUiHelper.showMessage(context, _t('err_rel_req'), isError: true);
      return;
    }

    setState(() => _submitting = true);
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    FirebaseAnalytics.instance.logEvent(
      name: 'auth_attempt',
      parameters: {'method': 'create_account'},
    );

    var phoneInput = _phoneController.text.trim().replaceAll(' ', '');
    phoneInput = '+94$phoneInput';
    final emailInput = _emailController.text.trim();

    if (!_phoneReadOnly) {
      await _verifyPhoneAndSave(phoneInput, emailInput);
      return;
    }

    if (!_emailReadOnly && emailInput.isNotEmpty) {
      await _verifyEmailAndSave(emailInput, phoneInput);
      return;
    }

    await _saveProfile(phoneInput, emailInput);
  }

  Future<void> _verifyPhoneAndSave(String phone, String email) async {
    try {
      await AuthService.instance.linkPhone(phone);
      if (!mounted) return;

      setState(() => _submitting = false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            identifier: phone,
            isEmail: false,
            onVerifyOverride: (code) async {
              await AuthService.instance.verifyLinkedPhone(
                phone: phone,
                token: code,
              );
            },
            onResendOverride: () async {
              await AuthService.instance.linkPhone(phone);
            },
            onVerified: () async {
              Navigator.pop(context);
              await _saveProfile(phone, email);
            },
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _submitting = false);
        FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'Failed to verify phone linked',
        );
        FirebaseAnalytics.instance.logEvent(
          name: 'auth_failure',
          parameters: {
            'method': 'create_account',
            'reason': 'phone_link_failed',
          },
        );
        AuthUiHelper.showMessage(
          context,
          _t(AuthUiHelper.parseErrorKey(e)),
          isError: true,
        );
      }
    }
  }

  Future<void> _verifyEmailAndSave(String email, String phone) async {
    try {
      await AuthService.instance.linkEmail(email);
      if (!mounted) return;

      setState(() => _submitting = false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            identifier: email,
            isEmail: true,
            onVerifyOverride: (code) async {
              await AuthService.instance.verifyLinkedEmail(
                email: email,
                token: code,
              );
            },
            onResendOverride: () async {
              await AuthService.instance.linkEmail(email);
            },
            onVerified: () async {
              Navigator.pop(context);
              await _saveProfile(phone, email);
            },
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _submitting = false);
        FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'Failed to verify email linked',
        );
        FirebaseAnalytics.instance.logEvent(
          name: 'auth_failure',
          parameters: {
            'method': 'create_account',
            'reason': 'email_link_failed',
          },
        );
        AuthUiHelper.showMessage(
          context,
          _t(AuthUiHelper.parseErrorKey(e)),
          isError: true,
        );
      }
    }
  }

  Future<void> _saveProfile(String phone, String email) async {
    setState(() => _submitting = true);
    try {
      await AuthService.instance.saveParentProfile(
        fullName: _fullNameController.text.trim(),
        phone: phone,
        email: email.isEmpty ? null : email,
        relationship: _selectedRelationship,
      );

      await AuthService.instance.markProfileCompleted();
      FirebaseAnalytics.instance.logEvent(
        name: 'auth_success',
        parameters: {'method': 'create_account'},
      );

      if (mounted) widget.onProfileCompleted();
    } catch (e, stackTrace) {
      if (mounted) {
        FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'Failed to save parent profile',
        );
        FirebaseAnalytics.instance.logEvent(
          name: 'auth_failure',
          parameters: {
            'method': 'create_account',
            'reason': 'save_profile_failed',
          },
        );
        AuthUiHelper.showMessage(
          context,
          _t(AuthUiHelper.parseErrorKey(e)),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleCancel() async {
    HapticFeedback.selectionClick();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurfaceStrong : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : Colors.black87;

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              _t('sign_out_title'),
              style: AppTypography.title.copyWith(color: textColor),
            ),
            content: Text(
              _t('sign_out_body'),
              style: AppTypography.body.copyWith(color: textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  _t('stay'),
                  style: AppTypography.label.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  _t('sign_out'),
                  style: AppTypography.label.copyWith(
                    color: Colors.redAccent.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      setState(() => _submitting = true);
      try {
        await AuthService.instance.cancelSignup();
        if (mounted) widget.onBack();
      } catch (e, stackTrace) {
        if (mounted) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stackTrace,
            reason: 'Failed to fully cancel signup',
          );
          AuthUiHelper.showMessage(
            context,
            _t(AuthUiHelper.parseErrorKey(e)),
            isError: true,
          );
          widget.onBack();
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  Widget _buildLanguageSelector(bool isDark) {
    // ✅ COLOR FIX: Passes isDark locally
    final menuBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final selectedTextColor = isDark ? Colors.white : AppColors.accent;
    final unselectedTextColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade700;

    return Semantics(
      button: true,
      label: "Select Language",
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: PopupMenuButton<AppLanguage>(
          onSelected: (AppLanguage newValue) {
            HapticFeedback.selectionClick();
            LanguageService.instance.setLanguage(newValue);
          },
          color: menuBgColor,
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
                    color: isSelected ? selectedTextColor : unselectedTextColor,
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
                    absorbing: _submitting,
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
                                        onPressed: _handleCancel,
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    _buildLanguageSelector(
                                      isDark,
                                    ), // ✅ Pass isDark locally
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
                                      _t('header'),
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
                                          alpha: 0.8,
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
                                        _t('section_personal'),
                                        style: AppTypography.headline.copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      _buildTextField(
                                        controller: _fullNameController,
                                        label: _t('full_name'),
                                        hint: _t('full_name_hint'),
                                        icon: Icons.person_outline_rounded,
                                        autofillHints: const [
                                          AutofillHints.name,
                                        ],
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: _validateName,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildTextField(
                                        controller: _phoneController,
                                        label: _t('mobile'),
                                        hint: _t('mobile_hint'),
                                        icon: Icons.phone_android_rounded,
                                        inputType: TextInputType.phone,
                                        autofillHints: const [
                                          AutofillHints.telephoneNumberNational,
                                        ],
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(9),
                                        ],
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: _validatePhone,
                                        readOnly: _phoneReadOnly,
                                        prefixText: '+94 ',
                                      ),
                                      const SizedBox(height: 20),
                                      _buildDropdown(isDark, accentColor),
                                      const SizedBox(height: 20),
                                      _buildTextField(
                                        controller: _emailController,
                                        label: _t('email_opt'),
                                        hint: _t('email_hint'),
                                        icon: Icons.email_outlined,
                                        inputType: TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: _validateEmail,
                                        readOnly: _emailReadOnly,
                                      ),
                                      const SizedBox(height: 32),
                                      Semantics(
                                        button: true,
                                        label: _submitting
                                            ? "Loading, please wait"
                                            : _t('continue_btn'),
                                        child: Listener(
                                          onPointerDown: (_) {
                                            if (!_submitting)
                                              setState(
                                                () => _isSubmitPressed = true,
                                              );
                                          },
                                          onPointerUp: (_) {
                                            if (!_submitting)
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
                                                onPressed: _submitting
                                                    ? null
                                                    : _handleSubmit,
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
                                                child: _submitting
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
                                          ),
                                        ),
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
        obscureText: isPassword && !isPasswordVisible,
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
              color: readOnly ? Colors.transparent : borderColor,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: readOnly ? Colors.transparent : activeColor,
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

  Widget _buildDropdown(bool isDark, Color activeColor) {
    final borderColor = isDark ? AppColors.darkStroke : Colors.grey.shade300;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final hintColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade500;
    final List<String> localizedTypes = [
      _t('rel_parent'),
      _t('rel_guardian'),
      _t('rel_other'),
    ];

    return Semantics(
      label: _t('relationship'),
      button: true,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedRelationship != null
            ? localizedTypes[_relationshipTypes.indexOf(_selectedRelationship!)]
            : null,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: hintColor),
        dropdownColor: isDark ? AppColors.darkSurfaceStrong : Colors.white,
        borderRadius: BorderRadius.circular(16),
        validator: (val) => val == null ? _t('err_rel_req') : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: AppTypography.body.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: _t('relationship'),
          labelStyle: AppTypography.body.copyWith(color: hintColor),
          hintText: _t('rel_hint'),
          hintStyle: AppTypography.body.copyWith(color: hintColor),
          prefixIcon: Icon(
            Icons.people_outline_rounded,
            color: hintColor,
            size: 22,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
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
        ),
        items: localizedTypes
            .map(
              (displayType) => DropdownMenuItem(
                value: displayType,
                child: Text(displayType),
              ),
            )
            .toList(),
        onChanged: (displayVal) {
          if (displayVal != null)
            setState(
              () => _selectedRelationship =
                  _relationshipTypes[localizedTypes.indexOf(displayVal)],
            );
        },
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
