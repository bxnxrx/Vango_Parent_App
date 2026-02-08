import 'package:flutter/material.dart';

import 'package:vango_parent_app/screens/auth/link_driver_screen.dart';
import 'package:vango_parent_app/screens/auth/login_screen.dart';
import 'package:vango_parent_app/screens/auth/phone_login_screen.dart';
import 'package:vango_parent_app/screens/auth/otp_screen.dart';
import 'package:vango_parent_app/screens/auth/permissions_sheet.dart';
import 'package:vango_parent_app/screens/auth/register_screen.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  // 0 = login, 1 = register, 2 = phone login, 3 = otp, 4 = link driver
  int _screenIndex = 0;
  String _phoneNumber = '+94';
  String? _preferredChildId;
  String? _pendingDriverCode;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _moveToLogin() {
    setState(() => _screenIndex = 0);
  }

  void _moveToRegister() {
    setState(() => _screenIndex = 1);
  }

  void _moveToPhoneLogin() {
    setState(() => _screenIndex = 2);
  }

  void _moveToOtp(String phone, {String? childId}) {
    setState(() {
      _phoneNumber = phone;
      _preferredChildId = childId;
      _screenIndex = 3;
    });
  }

  void _moveToOtpFromLogin(String phone) => _moveToOtp(phone);

  Future<void> _handleLoginCompleted(String _) async {
    try {
      final status = await AuthService.instance.fetchOnboardingStatus();
      if (!mounted) return;

      if (status.ready) {
        _openPermissionsSheet();
        return;
      }

      if (!status.phoneComplete) {
        setState(() => _screenIndex = 2);
        _showMessage('Add and verify your phone number to continue.');
        return;
      }

      if (!status.profileComplete) {
        setState(() => _screenIndex = 1);
        _showMessage('Finish your profile details to continue.');
        return;
      }

      if (!status.linkComplete) {
        setState(() => _screenIndex = 4);
        return;
      }

      setState(() => _screenIndex = 0);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Login successful but status check failed: $error');
      setState(() => _screenIndex = 0);
    }
  }

  void _openPermissionsSheet() {
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

  Widget _buildBody() {
    if (_screenIndex == 0) {
      return LoginScreen(
        key: const ValueKey('login'),
        onContinue: _handleLoginCompleted,
        onUsePhoneLogin: _moveToPhoneLogin,
        onCreateAccount: _moveToRegister,
      );
    }

    if (_screenIndex == 1) {
      return RegisterScreen(
        key: const ValueKey('register'),
        onBack: _moveToLogin,
        onSubmit: (result) {
          _pendingDriverCode = result.driverCode;
          _moveToOtp(result.phone, childId: result.childId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome ${result.childName}! Confirm OTP to finish.')),
          );
        },
        onCancel: () {
          _pendingDriverCode = null;
          _preferredChildId = null;
          _moveToLogin();
        },
        onUsePhoneSignup: _moveToPhoneLogin,
      );
    }

    if (_screenIndex == 2) {
      return PhoneLoginScreen(
        key: const ValueKey('phone-login'),
        onBack: _moveToLogin,
        onCodeSent: _moveToOtpFromLogin,
      );
    }

    if (_screenIndex == 3) {
      return OtpScreen(
        key: ValueKey('otp-$_phoneNumber'),
        phoneNumber: _phoneNumber,
        onVerified: _handleOtpVerified,
        onBack: _moveToLogin,
      );
    }

    return LinkDriverScreen(
      key: const ValueKey('link-driver'),
      preferredChildId: _preferredChildId,
      initialCode: _pendingDriverCode,
      onBack: () => setState(() => _screenIndex = 0),
      onLinked: () {
        _preferredChildId = null;
        _pendingDriverCode = null;
        _openPermissionsSheet();
      },
    );
  }

  Future<void> _handleOtpVerified() async {
    try {
      final status = await AuthService.instance.markPhoneVerified();
      if (!mounted) return;

      if (status.ready) {
        _pendingDriverCode = null;
        _openPermissionsSheet();
        return;
      }

      if (status.phase == OnboardingPhase.link) {
        setState(() => _screenIndex = 4);
        return;
      }

      if (status.phase == OnboardingPhase.profile) {
        setState(() => _screenIndex = 1);
        _showMessage('Finish your profile details to continue.');
        return;
      }

      setState(() => _screenIndex = 0);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Phone verification saved but status check failed: $error');
      setState(() => _screenIndex = 4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLoginShortcut = _screenIndex != 0 && _screenIndex != 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sign in to EduRide'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          if (showLoginShortcut)
            TextButton(onPressed: _moveToLogin, child: const Text('Login')),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
    );
  }
}
