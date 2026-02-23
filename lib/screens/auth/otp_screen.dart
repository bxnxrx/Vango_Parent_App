import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Needed for OtpType

import 'package:vango_parent_app/services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.identifier,
    this.isEmail = false,
    required this.onVerified,
    required this.onBack,
    this.onVerifyOverride,
    this.onResendOverride,
  });

  final String identifier;
  final bool isEmail;
  final Future<void> Function() onVerified;
  final VoidCallback onBack;

  // New overrides for custom logic (like Identity Linking)
  final Future<void> Function(String code)? onVerifyOverride;
  final Future<void> Function()? onResendOverride;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // Constants
  static const int _digits = 6;
  static const int _countdownSeconds = 60;
  static const Color _vangoBlue = Color(0xFF2D325A);

  // State
  final List<TextEditingController> _controllers = List.generate(
    _digits,
    (_) => TextEditingController(),
  );
  Timer? _countdown;
  int _secondsLeft = _countdownSeconds;
  bool _isLoading = false;
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
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text.trim()).join();
    if (code.length != _digits) {
      _showMessage('Please enter the full $_digits-digit code.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // If override provided (Linking), use it. Otherwise use default (Login).
      if (widget.onVerifyOverride != null) {
        await widget.onVerifyOverride!(code);
      } else {
        if (widget.isEmail) {
          await AuthService.instance.verifyEmailOtp(
            email: widget.identifier,
            token: code,
          );
        } else {
          await AuthService.instance.verifyPhoneOtp(
            phone: widget.identifier,
            token: code,
          );
        }
      }

      if (!mounted) return;
      await widget.onVerified();
    } catch (error) {
      _showMessage('Verification failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_secondsLeft > 0) return;

    setState(() => _resending = true);
    try {
      if (widget.onResendOverride != null) {
        await widget.onResendOverride!();
      } else {
        if (widget.isEmail) {
          await AuthService.instance.requestEmailOtp(widget.identifier);
        } else {
          await AuthService.instance.requestPhoneOtp(widget.identifier);
        }
      }

      _startCountdown();
      if (!mounted) return;
      _showMessage('Code resent!');
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // 1. Blue Curved Background
              ClipPath(
                clipper: _BackgroundClipper(),
                child: Container(
                  width: double.infinity,
                  height: 500,
                  color: _vangoBlue,
                ),
              ),

              // 2. Content
              SafeArea(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 47,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            GestureDetector(
                              onTap: widget.onBack,
                              child: const Icon(
                                Icons.arrow_circle_left,
                                size: 35,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Flexible(
                              child: Text(
                                'OTP Verification',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // Info Text
                        Text(
                          widget.isEmail
                              ? 'Enter the code sent to your email'
                              : 'Enter the code sent to',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                widget.identifier,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // OTP Inputs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            _digits,
                            (index) => _buildOtpTextField(index),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _vangoBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Verify',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Resend Logic
                        Text(
                          "Don't receive the OTP?",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: (_secondsLeft == 0 && !_resending)
                              ? _resendCode
                              : null,
                          child: _resending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _secondsLeft > 0
                                      ? "Resend OTP - ${_secondsLeft}s"
                                      : "Resend OTP",
                                  style: GoogleFonts.inter(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpTextField(int index) {
    return Container(
      width: 42,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controllers[index],
        onChanged: (value) {
          if (value.isNotEmpty && index < _digits - 1) {
            FocusScope.of(context).nextFocus();
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// Custom Clipper for the background curve
class _BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
