import 'package:flutter/material.dart';

import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({
    super.key,
    required this.onBack,
    required this.onCodeSent,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onCodeSent;

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '+94');
  bool _sendingCode = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleSendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Enter your phone number.');
      return;
    }

    setState(() => _sendingCode = true);
    try {
      await AuthService.instance.cachePhone(phone);
      await AuthService.instance.requestPhoneOtp(phone);
      if (!mounted) return;
      widget.onCodeSent(phone);
    } catch (error) {
      _showMessage('Unable to send code: $error');
    } finally {
      if (mounted) {
        setState(() => _sendingCode = false);
      }
    }
  }

  InputDecoration _fieldDecoration(String labelText, {Widget? prefix}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Log in with phone'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone login',
                style: AppTypography.display.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your phone number and we\'ll send you a one-time code to log in.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _fieldDecoration(
                  'Phone number',
                  prefix: const Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: _sendingCode ? 'Sending code...' : 'Send code',
                expanded: true,
                onPressed: _sendingCode ? null : _handleSendCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
