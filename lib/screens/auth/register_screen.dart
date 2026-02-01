import 'package:flutter/material.dart';

import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class ParentRegistrationResult {
  const ParentRegistrationResult({required this.phone, required this.childName});

  final String phone;
  final String childName;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onBack, required this.onSubmit});

  final VoidCallback onBack;
  final ValueChanged<ParentRegistrationResult> onSubmit;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _stepTitles = ['Personal', 'Child', 'Driver link'];

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
        _buildLabeledField(label: 'Full name', controller: _fullNameController, icon: Icons.person_outline),
        const SizedBox(height: 16),
        _buildLabeledField(label: 'Email address', controller: _emailController, icon: Icons.alternate_email, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildLabeledField(label: 'Password', controller: _passwordController, icon: Icons.lock_outline, obscure: true),
        const SizedBox(height: 16),
        _buildLabeledField(label: 'Phone number', controller: _phoneController, icon: Icons.phone_android, keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _buildChildStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _buildLabeledField(label: 'Driver invite code (optional)', controller: _driverCodeController, icon: Icons.qr_code_2),
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

  bool _validatePersonal() {
    if (_fullNameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      _showMessage('Fill your name, email, password, and phone number.');
      return false;
    }
    return true;
  }

  bool _validateChild() {
    if (_childNameController.text.trim().isEmpty || _schoolController.text.trim().isEmpty || _pickupController.text.trim().isEmpty) {
      _showMessage('Tell us about your child, school, and pickup location.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final childName = _childNameController.text.trim().isEmpty ? 'Your child' : _childNameController.text.trim();

    setState(() => _submitting = true);
    try {
      await AuthService.instance.signInOrSignUp(_emailController.text.trim(), _passwordController.text.trim());
      await AuthService.instance.saveParentProfile(fullName: _fullNameController.text.trim(), phone: phone);
      final childId = await AuthService.instance.createChild(
        childName: _childNameController.text.trim(),
        school: _schoolController.text.trim(),
        pickupLocation: _pickupController.text.trim(),
      );

      final driverCode = _driverCodeController.text.trim();
      if (driverCode.isNotEmpty) {
        await AuthService.instance.linkDriver(code: driverCode, childId: childId);
      }

      await AuthService.instance.cachePhone(phone);
      await AuthService.instance.requestPhoneOtp(phone);

      if (!mounted) return;
      widget.onSubmit(ParentRegistrationResult(phone: phone, childName: childName));
    } catch (error) {
      _showMessage('Unable to submit details: $error');
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

    if (_step == 0 && !_validatePersonal()) {
      return;
    }
    if (_step == 1 && !_validateChild()) {
      return;
    }

    if (_step == 2) {
      _submit();
      return;
    }

    setState(() => _step += 1);
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
              Text('Create parent account', style: AppTypography.display.copyWith(fontSize: 24)),
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

