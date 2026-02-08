import 'dart:async';

import 'package:flutter/material.dart';

import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({
    super.key,
    required this.email,
    this.onVerified,
  });

  final String email;
  final VoidCallback? onVerified;

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (code.length < 4) {
      _showMessage('Enter the 6-digit code from your email.');
      return;
    }

    setState(() => _verifying = true);
    try {
      await AuthService.instance.verifyEmailOtp(
        email: widget.email,
        token: code,
      );

      if (!mounted) return;
      _showMessage('Email verified successfully.');
      widget.onVerified?.call();
      Navigator.of(context).pop();
    } catch (error) {
      _showMessage('Unable to verify code: $error');
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0) return;

    setState(() => _resending = true);
    try {
      await AuthService.instance.requestEmailOtp(widget.email);
      if (!mounted) return;
      _showMessage('A new code has been sent to your email.');
      setState(() => _secondsRemaining = 60);
      _startTimer();
    } catch (error) {
      _showMessage('Unable to resend code: $error');
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsRemaining == 0 && !_resending;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify your email'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check your inbox',
                style: AppTypography.display.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ve sent a 6-digit code to ${widget.email}. Enter it below to verify your email address.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'Verification code',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: _verifying ? 'Verifying...' : 'Confirm',
                expanded: true,
                onPressed: _verifying ? null : _handleVerify,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _secondsRemaining > 0
                        ? 'You can resend a code in $_secondsRemaining s'
                        : 'Didn\'t receive the code?',
                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: canResend ? _handleResend : null,
                    child: _resending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
