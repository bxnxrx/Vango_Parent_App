import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class OtpBottomSheet extends StatefulWidget {
  final String phone;
  final String initialOtp;
  final Future<String> Function() onResend;

  const OtpBottomSheet({
    super.key,
    required this.phone,
    required this.initialOtp,
    required this.onResend,
  });

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  final TextEditingController _otpController = TextEditingController();
  late String _currentOtp;
  bool _isVerifying = false;
  String? _errorMessage;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.initialOtp;
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _countdown = 60;
      _errorMessage = null;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _resendCode() async {
    HapticFeedback.selectionClick();
    setState(() => _errorMessage = null);
    try {
      String newOtp = await widget.onResend();
      setState(() => _currentOtp = newOtp);
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code resent successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to resend code');
    }
  }

  Future<void> _verify() async {
    if (_otpController.text.length != 6) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (_otpController.text.trim() == _currentOtp) {
      Navigator.pop(context, true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Invalid code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Emergency Contact',
            style: AppTypography.title.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to ${widget.phone}',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            autofillHints: const [AutofillHints.oneTimeCode],
            onChanged: (val) {
              if (val.length == 6 && !_isVerifying) _verify();
            },
            decoration: InputDecoration(
              labelText: '6-Digit SMS Code',
              prefixIcon: const Icon(Icons.security),
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _countdown == 0 ? _resendCode : null,
                child: Text(
                  _countdown == 0 ? 'Resend Code' : 'Resend in ${_countdown}s',
                  style: TextStyle(
                    color: _countdown == 0
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isVerifying ? null : _verify,
              child: _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Confirm Code'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
