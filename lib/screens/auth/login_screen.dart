import 'package:flutter/material.dart';

import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onContinue,
    required this.onUseOtp,
    required this.onCreateAccount,
  });

  final void Function(String phone) onContinue;
  final void Function(String phone) onUseOtp;
  final VoidCallback onCreateAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: '+94');

  bool _submitting = false;
  bool _sendingOtpOnly = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || phone.isEmpty) {
      _showMessage('Enter email, password, and phone number.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await AuthService.instance.signInOrSignUp(email, password);
      await AuthService.instance.cachePhone(phone);
      await AuthService.instance.requestPhoneOtp(phone);
      if (!mounted) return;
      widget.onContinue(phone);
    } catch (error) {
      _showMessage('Unable to sign in: $error');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _handleOtpOnly() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Enter your phone number first.');
      return;
    }

    setState(() => _sendingOtpOnly = true);
    try {
      await AuthService.instance.cachePhone(phone);
      await AuthService.instance.requestPhoneOtp(phone);
      if (!mounted) return;
      widget.onUseOtp(phone);
    } catch (error) {
      _showMessage('Unable to send code: $error');
    } finally {
      if (mounted) {
        setState(() => _sendingOtpOnly = false);
      }
    }
  }

  InputDecoration _fieldDecoration(String label, {Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back', style: AppTypography.display.copyWith(fontSize: 32)),
          const SizedBox(height: 8),
          Text('Sign in to manage your child rides', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _fieldDecoration('Email', prefix: const Icon(Icons.alternate_email_outlined)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: _fieldDecoration('Password', prefix: const Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _fieldDecoration('Phone number', prefix: const Icon(Icons.phone_iphone)),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Continue',
            expanded: true,
            onPressed: _submitting ? null : _handleLogin,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _sendingOtpOnly ? null : _handleOtpOnly,
            icon: _sendingOtpOnly
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sms_outlined),
            label: const Text('Send me an OTP'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("New to VanGo?", style: AppTypography.body),
              TextButton(onPressed: widget.onCreateAccount, child: const Text('Create account')),
            ],
          ),
        ],
      ),
    );
  }
}
