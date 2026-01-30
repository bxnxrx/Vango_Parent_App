import 'dart:async';

import 'package:flutter/material.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phoneNumber, required this.onVerified, required this.onBack});

  final String phoneNumber;
  final VoidCallback onVerified;
  final VoidCallback onBack;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _digits = 4;
  static const int _countdownSeconds = 60;

  final List<TextEditingController> _controllers = List.generate(_digits, (_) => TextEditingController());
  Timer? _countdown;
  int _secondsLeft = _countdownSeconds;

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

  // Reset the timer that prevents spamming the resend button.
  void _startCountdown() {
    _countdown?.cancel();
    setState(() {
      _secondsLeft = _countdownSeconds;
    });
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft == 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  // Allow the user to request a fresh OTP.
  void _resendCode() {
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP code resent')));
  }

  @override
  Widget build(BuildContext context) {
    // Build a row of one-character inputs for the OTP code.
    final List<Widget> otpFields = [];
    for (final controller in _controllers) {
      otpFields.add(
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            decoration: const InputDecoration(counterText: ''),
          ),
        ),
      );
    }

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
          Text('We sent a 4-digit code to ${widget.phoneNumber}', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: otpFields,
          ),
          const SizedBox(height: 16),
          Text('00:$secondsLabel remaining', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text("Didn't receive code?", style: AppTypography.body),
              TextButton(onPressed: _secondsLeft == 0 ? _resendCode : null, child: const Text('Resend')),
            ],
          ),
          const SizedBox(height: 24),
          GradientButton(label: 'Continue', expanded: true, onPressed: widget.onVerified),
        ],
      ),
    );
  }
}

