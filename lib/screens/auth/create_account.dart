import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/screens/auth/otp_screen.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/utils/auth_ui_helper.dart';
import 'package:vango_parent_app/utils/validators.dart';
import 'package:vango_parent_app/widgets/common_language_selector.dart'; // ✅ NEW
import 'package:vango_parent_app/widgets/common_text_field.dart'; // ✅ NEW

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

  // ✅ State Management Refactor
  final ValueNotifier<bool> _submitting = ValueNotifier(false);
  final ValueNotifier<bool> _isSubmitPressed = ValueNotifier(false);

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

        if (user?.phone != null && user!.phone!.isNotEmpty) {
          String p = user.phone!;
          if (p.startsWith('+94')) {
            p = p.substring(3);
          } else if (p.startsWith('94') && p.length == 11) {
            p = p.substring(2);
          }
          _phoneController.text = p;
          _phoneReadOnly = true;
        } else if (cachedPhone != null && _phoneController.text.isEmpty) {
          String p = cachedPhone;
          if (p.startsWith('+94')) {
            p = p.substring(3);
          } else if (p.startsWith('94') && p.length == 11) {
            p = p.substring(2);
          }
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
    _submitting.dispose();
    _isSubmitPressed.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting.value) return;

    final loc = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      AuthUiHelper.showMessage(context, loc.createErrForm, isError: true);
      return;
    }
    if (_selectedRelationship == null) {
      HapticFeedback.heavyImpact();
      AuthUiHelper.showMessage(context, loc.createErrRelReq, isError: true);
      return;
    }

    _submitting.value = true;
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

      _submitting.value = false;
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
      if (!mounted) return;
      _submitting.value = false;
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to verify phone linked',
      );
      AuthUiHelper.showMessage(
        context,
        AuthUiHelper.parseErrorKey(e),
        isError: true,
      );
    }
  }

  Future<void> _verifyEmailAndSave(String email, String phone) async {
    try {
      await AuthService.instance.linkEmail(email);
      if (!mounted) return;

      _submitting.value = false;
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
      if (!mounted) return;
      _submitting.value = false;
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to verify email linked',
      );
      AuthUiHelper.showMessage(
        context,
        AuthUiHelper.parseErrorKey(e),
        isError: true,
      );
    }
  }

  Future<void> _saveProfile(String phone, String email) async {
    _submitting.value = true;
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
      if (!mounted) return;
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to save parent profile',
      );
      AuthUiHelper.showMessage(
        context,
        AuthUiHelper.parseErrorKey(e),
        isError: true,
      );
    } finally {
      if (mounted) _submitting.value = false;
    }
  }

  Future<void> _handleCancel() async {
    HapticFeedback.selectionClick();

    final loc = AppLocalizations.of(context)!;
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
              loc.createSignOutTitle,
              style: AppTypography.title.copyWith(color: textColor),
            ),
            content: Text(
              loc.createSignOutBody,
              style: AppTypography.body.copyWith(color: textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  loc.createStay,
                  style: AppTypography.label.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  loc.createSignOut,
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
      _submitting.value = true;
      try {
        await AuthService.instance.cancelSignup();
        if (mounted) widget.onBack();
      } catch (e, stackTrace) {
        if (!mounted) return;
        FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'Failed to fully cancel signup',
        );
        AuthUiHelper.showMessage(
          context,
          AuthUiHelper.parseErrorKey(e),
          isError: true,
        );
        widget.onBack();
      } finally {
        if (mounted) _submitting.value = false;
      }
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
                valueListenable: _submitting,
                builder: (context, isSubmitting, _) {
                  return AbsorbPointer(
                    absorbing: isSubmitting,
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
                                      loc.createHeader,
                                      style: AppTypography.headline.copyWith(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc.createSubtitle,
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
                                        loc.createSectionPersonal,
                                        style: AppTypography.headline.copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      CommonTextField(
                                        controller: _fullNameController,
                                        label: loc.createFullName,
                                        hint: loc.createFullNameHint,
                                        icon: Icons.person_outline_rounded,
                                        autofillHints: const [
                                          AutofillHints.name,
                                        ],
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: (val) =>
                                            AppValidators.validateName(
                                              val,
                                              loc,
                                            ), // ✅ Uses Validator
                                      ),
                                      const SizedBox(height: 20),
                                      CommonTextField(
                                        controller: _phoneController,
                                        label: loc.createMobile,
                                        hint: loc.createMobileHint,
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
                                        validator: (val) =>
                                            AppValidators.validatePhone(
                                              val,
                                              loc,
                                            ), // ✅ Uses Validator
                                        readOnly: _phoneReadOnly,
                                        prefixText: '+94 ',
                                      ),
                                      const SizedBox(height: 20),
                                      _buildDropdown(isDark, accentColor, loc),
                                      const SizedBox(height: 20),
                                      CommonTextField(
                                        controller: _emailController,
                                        label: loc.createEmailOpt,
                                        hint: loc.createEmailHint,
                                        icon: Icons.email_outlined,
                                        inputType: TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        isDark: isDark,
                                        activeColor: accentColor,
                                        validator: (val) =>
                                            AppValidators.validateEmail(
                                              val,
                                              loc,
                                              isOptional: true,
                                            ), // ✅ Uses Validator
                                        readOnly: _emailReadOnly,
                                      ),
                                      const SizedBox(height: 32),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isSubmitPressed,
                                        builder: (context, isPressed, _) {
                                          return Semantics(
                                            button: true,
                                            label: isSubmitting
                                                ? "Loading, please wait"
                                                : loc.createContinueBtn,
                                            child: Listener(
                                              onPointerDown: (_) {
                                                if (!isSubmitting)
                                                  _isSubmitPressed.value = true;
                                              },
                                              onPointerUp: (_) {
                                                if (!isSubmitting)
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
                                                    onPressed: isSubmitting
                                                        ? null
                                                        : _handleSubmit,
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
                                                    child: isSubmitting
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
                                                        : Text(
                                                            loc.createContinueBtn,
                                                          ),
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
                              const SizedBox(height: 20),
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

  Widget _buildDropdown(bool isDark, Color activeColor, AppLocalizations loc) {
    final borderColor = isDark ? AppColors.darkStroke : Colors.grey.shade300;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final hintColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade500;

    final List<String> localizedTypes = [
      loc.createRelParent,
      loc.createRelGuardian,
      loc.createRelOther,
    ];

    return Semantics(
      label: loc.createRelationship,
      button: true,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedRelationship != null
            ? localizedTypes[_relationshipTypes.indexOf(_selectedRelationship!)]
            : null,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: hintColor),
        dropdownColor: isDark ? AppColors.darkSurfaceStrong : Colors.white,
        borderRadius: BorderRadius.circular(16),
        validator: (val) => val == null ? loc.createErrRelReq : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: AppTypography.body.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: loc.createRelationship,
          labelStyle: AppTypography.body.copyWith(color: hintColor),
          hintText: loc.createRelHint,
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
          if (displayVal != null) {
            setState(
              () => _selectedRelationship =
                  _relationshipTypes[localizedTypes.indexOf(displayVal)],
            );
          }
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
