import 'package:flutter/material.dart';

import 'package:vango_parent_app/screens/auth/login_signup.dart';
import 'package:vango_parent_app/screens/auth/create_account.dart';
import 'package:vango_parent_app/screens/auth/otp_screen.dart';
import 'package:vango_parent_app/screens/auth/permissions_sheet.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

enum AuthPage { login, otp, emailOtp, createAccount }

class _AuthFlowState extends State<AuthFlow> {
  AuthPage _page = AuthPage.login;

  // State to pass between pages
  String _phoneNumber = '';
  String _email = '';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Navigation Helpers ---

  void _goToLogin() => setState(() => _page = AuthPage.login);

  void _goToOtp(String phone) {
    setState(() {
      _phoneNumber = phone;
      _page = AuthPage.otp;
    });
  }

  void _goToEmailOtp(String email) {
    setState(() {
      _email = email;
      _page = AuthPage.emailOtp;
    });
  }

  void _goToCreateAccount() => setState(() => _page = AuthPage.createAccount);

  // --- Logic ---

  Future<void> _handleAuthenticated(OnboardingStatus status) async {
    // ROBUST CHECK:
    // We check both status.profileComplete (from users_meta) AND status.parent.profileComplete.
    // This prevents the loop if the meta table update is slightly delayed but the profile exists.
    final bool isProfileDone =
        status.profileComplete || (status.parent?.profileComplete ?? false);

    if (!isProfileDone) {
      // If profile is not complete, go to Create Account page
      _goToCreateAccount();
    } else {
      // If profile is complete, finish auth flow
      _openPermissionsOrFinish();
    }
  }

  void _openPermissionsOrFinish() {
    // Show permissions sheet before letting them in completely
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return PermissionsSheet(
          onComplete: () {
            Navigator.of(context).pop();
            widget.onAuthenticated();
          },
        );
      },
    );
  }

  // Handles logic after Phone OTP is verified
  Future<void> _onPhoneVerified() async {
    try {
      final status = await AuthService.instance.markPhoneVerified();
      await _handleAuthenticated(status);
    } catch (e) {
      _showMessage('Verification saved but status check failed: $e');
    }
  }

  // Handles logic after Email OTP is verified
  Future<void> _onEmailVerified() async {
    try {
      final status = await AuthService.instance.fetchOnboardingStatus();
      await _handleAuthenticated(status);
    } catch (e) {
      _showMessage('Verification saved but status check failed: $e');
    }
  }

  // --- Render ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentPage(),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_page) {
      case AuthPage.login:
        return LoginSignupScreen(
          key: const ValueKey('login'),
          onAuthenticated: _handleAuthenticated,
          onOtpRequested: _goToOtp,
          onEmailVerificationNeeded: _goToEmailOtp,
        );

      case AuthPage.otp:
        // Use the unified OtpScreen for Phone
        return OtpScreen(
          key: const ValueKey('otp'),
          identifier: _phoneNumber, // Correctly uses identifier
          isEmail: false, // Explicitly set for Phone
          onVerified: _onPhoneVerified,
          onBack: _goToLogin,
        );

      case AuthPage.emailOtp:
        // Use the unified OtpScreen for Email
        return OtpScreen(
          key: const ValueKey('emailOtp'),
          identifier: _email, // Correctly uses identifier
          isEmail: true, // Explicitly set for Email
          onVerified: _onEmailVerified,
          onBack: _goToLogin,
        );

      case AuthPage.createAccount:
        return CreateAccountScreen(
          key: const ValueKey('createAccount'),
          onProfileCompleted: _openPermissionsOrFinish,
          onBack: _goToLogin,
        );
    }
  }
}
