import 'package:flutter/material.dart';

import 'package:vango_parent_app/screens/auth/email_otp_screen.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class ParentRegistrationResult {
  const ParentRegistrationResult({
    required this.phone,
    required this.childName,
    required this.childId,
    this.driverCode,
  });

  final String phone;
  final String childName;
  final String childId;
  final String? driverCode;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onBack,
    required this.onSubmit,
    required this.onCancel,
    required this.onUsePhoneSignup,
  });

  final VoidCallback onBack;
  final ValueChanged<ParentRegistrationResult> onSubmit;
  final VoidCallback onCancel;
  final VoidCallback onUsePhoneSignup;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _stepTitles = ['Account', 'Details', 'Driver link'];

  int _step = 0;
  bool _submitting = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: '+94');
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _driverCodeController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _childNameController.dispose();
    _schoolController.dispose();
    _pickupController.dispose();
    _driverCodeController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
    );
  }

  Widget _buildLabeledField({required String label, required TextEditingController controller, IconData? icon, bool obscure = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_stepTitles.length, (index) {
        final isActive = index <= _step;
        return Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isActive ? AppColors.accent : AppColors.surface,
              child: Text('${index + 1}', style: AppTypography.label.copyWith(color: isActive ? Colors.white : AppColors.textSecondary)),
            ),
            const SizedBox(height: 6),
            Text(
              _stepTitles[index],
              style: AppTypography.label.copyWith(color: isActive ? AppColors.accent : AppColors.textSecondary, fontSize: 12),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPersonalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledField(
          label: 'Email address',
          controller: _emailController,
          icon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'Create password',
          controller: _passwordController,
          icon: Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            const SizedBox(width: 8),
            Text('Or continue with', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _submitting ? null : _handleGoogleSignup,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFB3E5FC), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                  height: 24,
                  errorBuilder: (c, o, s) => const Icon(Icons.g_mobiledata, size: 28),
                ),
                const SizedBox(width: 12),
                const Text('Continue with Google'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _submitting ? null : widget.onUsePhoneSignup,
            child: const Text('Use mobile number instead'),
          ),
        ),
      ],
    );
  }

  Widget _buildChildStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledField(label: 'Full name', controller: _fullNameController, icon: Icons.person_outline),
        const SizedBox(height: 16),
        _buildLabeledField(label: 'Phone number', controller: _phoneController, icon: Icons.phone_android, keyboardType: TextInputType.phone),
        const SizedBox(height: 24),
        _buildLabeledField(label: 'Child name', controller: _childNameController, icon: Icons.child_care),
        const SizedBox(height: 16),
        _buildLabeledField(label: 'School', controller: _schoolController, icon: Icons.school_outlined),
        const SizedBox(height: 16),
        _buildLabeledField(label: 'Pickup location', controller: _pickupController, icon: Icons.location_on_outlined),
      ],
    );
  }

  Widget _buildDriverStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledField(label: 'Driver invite code', controller: _driverCodeController, icon: Icons.qr_code_2),
        const SizedBox(height: 8),
        Text(
          'Ask your driver for the 8-character code. You\'ll confirm it after OTP verification.',
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _buildLabeledField(label: 'How did you hear about us?', controller: _referralController, icon: Icons.chat_outlined),
      ],
    );
  }

  Widget _buildStepContent() {
    if (_step == 0) {
      return _buildPersonalStep();
    }
    if (_step == 1) {
      return _buildChildStep();
    }
    return _buildDriverStep();
  }

  bool _validateAccount() {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showMessage('Enter your email and choose a password.');
      return false;
    }
    return true;
  }

  bool _validateDetails() {
    if (_fullNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _childNameController.text.trim().isEmpty ||
        _schoolController.text.trim().isEmpty ||
        _pickupController.text.trim().isEmpty) {
      _showMessage('Fill in your name, phone, child, school and pickup.');
      return false;
    }
    return true;
  }

  bool _accountCreated = false;

  Future<void> _submit() async {
    if (!_accountCreated) {
      _showMessage('Account setup incomplete. Go back and enter your email and password.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final phone = _phoneController.text.trim();
      final childName = _childNameController.text.trim().isEmpty
          ? 'Your child'
          : _childNameController.text.trim();
      final driverCode = _driverCodeController.text.trim();

      await AuthService.instance.saveParentProfile(fullName: _fullNameController.text.trim(), phone: phone);
      final childId = await AuthService.instance.createChild(
        childName: _childNameController.text.trim(),
        school: _schoolController.text.trim(),
        pickupLocation: _pickupController.text.trim(),
      );

      await AuthService.instance.markProfileCompleted();

      await AuthService.instance.cachePhone(phone);
      await AuthService.instance.requestPhoneOtp(phone);

      if (!mounted) return;
      widget.onSubmit(ParentRegistrationResult(
        phone: phone,
        childName: childName,
        childId: childId,
        driverCode: driverCode.isEmpty ? null : driverCode,
      ));
    } catch (error) {
      _showMessage('Unable to submit details: $error');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _confirmAndCancelSignup() async {
    if (_submitting) return;

    final shouldCancel = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Cancel signup?'),
              content: const Text(
                'This will delete your partially created account and any related data. You can start again later.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Keep editing'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete & exit'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldCancel) return;

    setState(() => _submitting = true);
    try {
      await AuthService.instance.cancelSignup();
      if (!mounted) return;
      widget.onCancel();
      _showMessage('Signup cancelled and data removed.');
    } catch (error) {
      _showMessage('Unable to cancel signup: $error');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _goBack() {
    if (_step == 0 || _submitting) {
      widget.onBack();
      return;
    }
    setState(() => _step -= 1);
  }

  void _goForward() {
    if (_submitting) {
      return;
    }

    if (_step == 0) {
      if (!_validateAccount()) {
        return;
      }
      _completeAccountSetup();
      return;
    }

    if (_step == 1 && !_validateDetails()) {
      return;
    }

    if (_step == 2) {
      if (_driverCodeController.text.trim().isEmpty) {
        _showMessage('Enter your driver code to continue.');
        return;
      }
      _submit();
      return;
    }

    setState(() => _step += 1);
  }

  Future<void> _completeAccountSetup() async {
    setState(() => _submitting = true);
    try {
      final authResult = await AuthService.instance.signInOrSignUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (authResult.requiresEmailVerification) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }

      await AuthService.instance.markEmailVerified();

      if (!mounted) return;
      setState(() {
        _accountCreated = true;
        _step = 1;
      });
    } catch (error) {
      _showMessage('Unable to create account: $error');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => _submitting = true);
    try {
      await AuthService.instance.signInWithGoogleNative(
        webClientId: AppConfig.googleWebClientId,
        iosClientId: AppConfig.googleIosClientId,
        androidClientId: AppConfig.googleAndroidClientId,
      );

      final status = await AuthService.instance.fetchOnboardingStatus();

      if (!mounted) return;

      // If profile is already complete, just signal completion and let outer flow
      // decide next navigation. Otherwise, move user into details step to
      // collect required parent/child information.
      setState(() {
        _accountCreated = true;
        _step = status.phase == OnboardingPhase.completed ? 2 : 1;
      });
    } catch (error) {
      _showMessage('Google sign-in failed: $error');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStep = _step == 0;
    final isLastStep = _step == 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Create parent account',
                  style: AppTypography.display.copyWith(fontSize: 24),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _confirmAndCancelSignup,
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStepIndicator(),
          const SizedBox(height: 24),
          _buildStepContent(),
          const SizedBox(height: 24),
          Row(
            children: [
              if (!isFirstStep)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : _goBack,
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (!isFirstStep) const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: _submitting
                      ? 'Submitting...'
                      : isLastStep
                          ? 'Submit'
                          : 'Next',
                  expanded: true,
                  onPressed: _submitting ? null : _goForward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

