import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:vango_parent_app/l10n/app_localizations.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/utils/auth_ui_helper.dart'; // ✅ Added import

class OtpBottomSheet extends StatefulWidget {
  final String phone;
  final Future<void> Function() onResend;
  final Future<void> Function(String otp) onVerify;

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
  final FocusNode _focusNode = FocusNode();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
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
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleResend(AppLocalizations l10n) async {
    HapticFeedback.selectionClick();
    setState(() {
      _errorMessage = null;
      _otpController.clear();
    });
    _focusNode.requestFocus();

    await _analytics.logEvent(name: 'otp_resend_clicked');

    try {
      await widget.onResend();

      if (!mounted) return;
      _startTimer();
      // ✅ Replaced ScaffoldMessenger with AuthUiHelper
      AuthUiHelper.showMessage(context, l10n.codeResentSuccess, isError: false);
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
    if (_otpController.text.length != 6 || _isVerifying) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    HapticFeedback.lightImpact();
    _focusNode.unfocus();

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
      _otpController.clear();
      _focusNode.requestFocus();
    }
  }

  Widget _buildOtpBoxes(bool isDark) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_focusNode),
      child: Container(
        color: Colors.transparent,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0,
              child: TextField(
                controller: _otpController,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: const InputDecoration(counterText: ''),
                onChanged: (val) {
                  setState(() {});
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                  if (val.length == 6 && !_isVerifying) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      final l10n = AppLocalizations.of(context);
                      if (l10n != null && mounted) _handleVerify(l10n);
                    });
                  }
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                final text = _otpController.text;
                final isFocused =
                    _focusNode.hasFocus &&
                    (index == text.length || (index == 5 && text.length == 6));
                final hasText = index < text.length;
                final hasError = _errorMessage != null;

                Color borderColor;
                if (hasError) {
                  borderColor = Colors.redAccent;
                } else if (isFocused) {
                  borderColor = AppColors.accent;
                } else if (hasText) {
                  borderColor = isDark
                      ? Colors.white54
                      : AppColors.textSecondary;
                } else {
                  borderColor = isDark ? Colors.white10 : AppColors.stroke;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isFocused
                        ? AppColors.accent.withValues(alpha: 0.05)
                        : (isDark
                              ? const Color(0xFF141414)
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: isFocused || hasError ? 2 : 1.5,
                    ),
                    boxShadow: isFocused && !hasError
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    hasText ? text[index] : '',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.verifyEmergencyContact,
                      style: AppTypography.title.copyWith(
                        fontSize: 20,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.sentCodeTo(widget.phone),
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          _buildOtpBoxes(isDark),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _countdown == 0 ? l10n.resendCode : l10n.resendIn(_countdown),
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: _countdown == 0 && !_isVerifying
                    ? () => _handleResend(l10n)
                    : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  backgroundColor: _countdown == 0
                      ? AppColors.accent.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.resendCode,
                  style: TextStyle(
                    color: _countdown == 0
                        ? AppColors.accent
                        : (isDark ? Colors.white24 : Colors.black26),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: AppColors.accent.withValues(
                  alpha: 0.5,
                ),
              ),
              onPressed: _isVerifying || _otpController.text.length != 6
                  ? null
                  : () => _handleVerify(l10n),
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
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
