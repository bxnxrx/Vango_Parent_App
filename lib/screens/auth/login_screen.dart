import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vango_parent_app/screens/auth/email_otp_screen.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onContinue,
    required this.onUsePhoneLogin,
    required this.onCreateAccount,
  });

  final ValueChanged<String> onContinue;
  final VoidCallback onUsePhoneLogin;
  final VoidCallback onCreateAccount;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _submitting = false;
  bool _signingInWithSocial = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email address first.');
      return;
    }

    try {
      await AuthService.instance.requestPasswordReset(email);
      _showMessage('Password reset email sent. Check your inbox.');
    } catch (error) {
      _showMessage('Unable to send reset email: $error');
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter email and password.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final authResult = await AuthService.instance.signInOrSignUp(email, password);
      if (authResult.requiresEmailVerification) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(email: email),
          ),
        );
      }

      await AuthService.instance.markEmailVerified();
      if (!mounted) return;
      widget.onContinue('');
    } on AuthException catch (error) {
      if (error.message.toLowerCase().contains('email not confirmed') ||
          error.code == 'email_not_confirmed') {
        try {
          await Supabase.instance.client.auth.resend(
            type: OtpType.signup,
            email: email,
          );
        } catch (_) {
          // Swallow resend errors; user can still try code entry.
        }
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EmailOtpScreen(email: email),
            ),
          );
        }
      } else {
        _showMessage('Unable to sign in: ${error.message}');
      }
    } catch (error) {
      _showMessage('Unable to sign in: $error');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _handleOtpOnly() async {
    widget.onUsePhoneLogin();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _signingInWithSocial = true);
    try {
      await AuthService.instance.signInWithGoogleNative(
        webClientId: AppConfig.googleWebClientId,
        iosClientId: AppConfig.googleIosClientId,
        androidClientId: AppConfig.googleAndroidClientId,
      );
      if (!mounted) return;
      _showMessage('Signed in with Google. Now verify your phone.');
      // Move into the phone-based flow so the user can complete
      // OTP verification and onboarding, reusing the same path as
      // the "Use phone number instead" action.
      widget.onUsePhoneLogin();
    } catch (error) {
      _showMessage('Google sign-in failed: $error');
    } finally {
      if (mounted) {
        setState(() => _signingInWithSocial = false);
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _signingInWithSocial = true);
    try {
      await AuthService.instance.signInWithApple();
      if (!mounted) return;
      _showMessage('Signed in with Apple. Now verify your phone.');
      widget.onUsePhoneLogin();
    } catch (error) {
      _showMessage('Apple sign-in failed: $error');
    } finally {
      if (mounted) {
        setState(() => _signingInWithSocial = false);
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
            decoration: _fieldDecoration('Email', prefix: const Icon(Icons.alternate_email)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: _fieldDecoration('Password', prefix: const Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _submitting ? null : _handlePasswordReset,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: _submitting ? 'Logging in...' : 'Log In',
            expanded: true,
            onPressed: _submitting ? null : _handleLogin,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _handleOtpOnly,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.sms_outlined),
            label: const Text('Use phone number instead'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              const SizedBox(width: 8),
              Text('Or continue with', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _signingInWithSocial || _submitting ? null : _handleGoogleLogin,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFB3E5FC), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                    height: 24,
                    errorBuilder: (c, o, s) => const Icon(Icons.g_mobiledata, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _signingInWithSocial ? 'Connecting...' : 'Continue with Google',
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (Platform.isIOS) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signingInWithSocial || _submitting ? null : _handleAppleLogin,
                icon: const Icon(Icons.apple, size: 22),
                label: Text(
                  _signingInWithSocial ? 'Connecting...' : 'Continue with Apple',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('New to VanGo?', style: AppTypography.body),
              TextButton(onPressed: widget.onCreateAccount, child: const Text('Create account')),
            ],
          ),
        ],
      ),
    );
  }
}
