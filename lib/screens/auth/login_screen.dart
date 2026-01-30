import 'package:flutter/material.dart';

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

  final ValueChanged<String> onContinue;
  final ValueChanged<String> onUseOtp;
  final VoidCallback onCreateAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '+94 7');
  final TextEditingController _passwordController = TextEditingController();
  bool _useOtp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPlaceholderLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider auth coming soon')),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text('Sign in with $label'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Or continue with', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    if (_useOtp) {
      widget.onUseOtp(phone);
    } else {
      widget.onContinue(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back 👋', style: AppTypography.display.copyWith(fontSize: 30)),
          const SizedBox(height: 8),
          Text('Login to track morning rides, payments, and alerts.', style: AppTypography.body),
          const SizedBox(height: 24),
          _buildLabel('Phone number'),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.flag)),
          ),
          const SizedBox(height: 16),
          if (_useOtp)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('You will receive a 4-digit OTP to this number.', style: AppTypography.body.copyWith(fontSize: 14)),
            )
          else ...[
            _buildLabel('Password'),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline)),
            ),
          ],
          const SizedBox(height: 24),
          GradientButton(label: _useOtp ? 'Send OTP' : 'Continue', expanded: true, onPressed: _submit),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildSocialButton(Icons.g_mobiledata, 'Google', () => _showPlaceholderLogin('Google')),
              const SizedBox(height: 12),
              _buildSocialButton(Icons.apple, 'Apple', () => _showPlaceholderLogin('Apple')),
              const SizedBox(height: 12),
              _buildSocialButton(Icons.facebook, 'Facebook', () => _showPlaceholderLogin('Facebook')),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _useOtp = !_useOtp),
            child: Text(_useOtp ? 'Use password instead' : 'Use OTP instead'),
          ),
          TextButton(
            onPressed: widget.onCreateAccount,
            child: const Text('Create a new parent account'),
          ),
        ],
      ),
    );
  }
}
