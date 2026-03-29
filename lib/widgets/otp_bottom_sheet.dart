import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class OtpBottomSheet extends StatefulWidget {
  final String phone;
  final Future<void> Function() onResend; // ✅ Changed to Future<void>
  final Future<void> Function(String otp) onVerify; // ✅ Changed to Future<void>

  const OtpBottomSheet({
    super.key,
    required this.phone,
    required this.onResend,
    required this.onVerify,
  });

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;
  int _countdown = 60;
  Timer? _timer;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _analytics.logEvent(name: 'otp_sheet_opened');
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

  Future<void> _handleResend(AppLocalizations l10n) async {
    HapticFeedback.selectionClick();
    setState(() => _errorMessage = null);

    await _analytics.logEvent(name: 'otp_resend_clicked');

    try {
      await widget.onResend();

      if (!mounted) return;
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.codeResentSuccess),
          backgroundColor: Colors.green.shade800,
        ),
      );
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Failed to resend OTP code',
      );
      if (!mounted) return;
      setState(() => _errorMessage = l10n.failedToResendCode);
    }
  }

  Future<void> _handleVerify(AppLocalizations l10n) async {
    // ✅ UI Lock: Prevents double verification
    if (_otpController.text.length != 6 || _isVerifying) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    HapticFeedback.lightImpact();

    try {
      await widget.onVerify(_otpController.text.trim());

      if (!mounted) return;
      await _analytics.logEvent(name: 'otp_verification_success');
      Navigator.pop(context, true);
    } catch (e, stack) {
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      await _analytics.logEvent(name: 'otp_verification_failed');
      setState(() {
        _isVerifying = false;
        _errorMessage = l10n.invalidCodeTryAgain;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.verifyEmergencyContact,
            style: AppTypography.title.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sentCodeTo(widget.phone),
            style: AppTypography.body.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            onChanged: (val) {
              if (val.length == 6 && !_isVerifying) {
                _handleVerify(l10n);
              }
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF141414),
              labelText: l10n.sixDigitSmsCode,
              labelStyle: const TextStyle(
                color: Colors.white54,
                letterSpacing: 0,
                fontSize: 14,
              ),
              counterText: "",
              prefixIcon: const Icon(Icons.security, color: AppColors.accent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
              ),
              errorText: _errorMessage,
              errorStyle: const TextStyle(
                color: Colors.redAccent,
                letterSpacing: 0,
                fontSize: 13,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _countdown == 0 ? () => _handleResend(l10n) : null,
                child: Text(
                  _countdown == 0 ? l10n.resendCode : l10n.resendIn(_countdown),
                  style: TextStyle(
                    color: _countdown == 0 ? AppColors.accent : Colors.white30,
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
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isVerifying ? null : () => _handleVerify(l10n),
              child: _isVerifying
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      l10n.confirmCodeBtn,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
