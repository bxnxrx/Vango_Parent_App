import 'dart:async';

import 'package:flutter/material.dart';

import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phoneNumber, required this.onVerified, required this.onBack});

  final String phoneNumber;
  final Future<void> Function() onVerified;
  final VoidCallback onBack;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _digits = 6;
  static const int _countdownSeconds = 60;

  final List<TextEditingController> _controllers = List.generate(_digits, (_) => TextEditingController());
  Timer? _countdown;
  int _secondsLeft = _countdownSeconds;
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown?.cancel();
    setState(() => _secondsLeft = _countdownSeconds);
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    final code = _controllers.map((controller) => controller.text.trim()).join();
    if (code.length != _digits) {
      _showMessage('Enter the $_digits-digit code.');
      return;
    }

    setState(() => _verifying = true);
    try {
      await AuthService.instance.verifyPhoneOtp(phone: widget.phoneNumber, token: code);
      if (!mounted) return;
      await widget.onVerified();
    } catch (error) {
      _showMessage('Verification failed: $error');
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _resending = true);
    try {
      await AuthService.instance.requestPhoneOtp(widget.phoneNumber);
      _startCountdown();
      if (!mounted) return;
      _showMessage('OTP resent');
    } catch (error) {
      _showMessage('Unable to resend: $error');
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String secondsLabel = _secondsLeft.toString().padLeft(2, '0');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
          const SizedBox(height: 8),
          Text('Check your phone', style: AppTypography.display.copyWith(fontSize: 28)),
          const SizedBox(height: 8),
          Text('We sent a code to ${widget.phoneNumber}', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_digits, (index) {
              return SizedBox(
                width: 50,
                child: TextField(
                  controller: _controllers[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  onChanged: (value) {
                    if (value.length == 1 && index < _digits - 1) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                  decoration: const InputDecoration(counterText: ''),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text('00:$secondsLabel remaining', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text("Didn't receive code?", style: AppTypography.body),
              TextButton(
                onPressed: _secondsLeft == 0 && !_resending ? _resendCode : null,
                child: _resending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Resend'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: _verifying ? 'Verifying...' : 'Continue',
            expanded: true,
            onPressed: _verifying ? null : _verify,
          ),
        ],
      ),
    );
  }
}

