import 'package:flutter/material.dart';

import 'package:vango_parent_app/screens/auth/login_screen.dart';
import 'package:vango_parent_app/screens/auth/otp_screen.dart';
import 'package:vango_parent_app/screens/auth/permissions_sheet.dart';
import 'package:vango_parent_app/screens/auth/register_screen.dart';
import 'package:vango_parent_app/theme/app_colors.dart';

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  // 0 = login, 1 = register, 2 = otp
  int _screenIndex = 0;
  String _phoneNumber = '+94';

  void _moveToLogin() {
    setState(() => _screenIndex = 0);
  }

  void _moveToRegister() {
    setState(() => _screenIndex = 1);
  }

  void _moveToOtp(String phone) {
    setState(() {
      _phoneNumber = phone;
      _screenIndex = 2;
    });
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
        onContinue: _moveToOtp,
        onUseOtp: _moveToOtp,
        onCreateAccount: _moveToRegister,
      );
    }

    if (_screenIndex == 1) {
      return RegisterScreen(
        key: const ValueKey('register'),
        onBack: _moveToLogin,
        onSubmit: (childName) {
          _moveToOtp('+94 77 123 4567');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome $childName! Confirm OTP to finish.')),
          );
        },
      );
    }

    return OtpScreen(
      key: ValueKey('otp-$_phoneNumber'),
      phoneNumber: _phoneNumber,
      onVerified: _openPermissionsSheet,
      onBack: _moveToLogin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showLoginShortcut = _screenIndex != 0;

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
