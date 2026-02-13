import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/screens/auth/reset_password_screen.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({
    super.key,
    required this.onAuthenticated,
    required this.onOtpRequested,
    required this.onEmailVerificationNeeded,
  });

  final Function(OnboardingStatus) onAuthenticated;
  final Function(String phone) onOtpRequested;
  final Function(String email) onEmailVerificationNeeded;

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  // Mode Toggle (true = Phone, false = Email)
  bool _isPhoneLogin = true;
  bool _isLoading = false;

  // Validation Key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _phoneController = TextEditingController(
    text: '+94',
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- VALIDATORS ---

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces for validation
    final cleanPhone = value.replaceAll(' ', '');
    // Regex: Starts with +94, followed by 9 digits
    final phoneRegex = RegExp(r'^\+94[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Invalid format (use +947XXXXXXXX)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Check for uppercase
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for digits
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for special characters
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  // --- ACTIONS ---

  Future<void> _handlePhoneLogin() async {
    // Run validation before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phone = _phoneController.text.trim().replaceAll(' ', '');

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      widget.onOtpRequested(phone);
    } catch (e) {
      _showMessage('Failed to send code: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailLogin() async {
    // Run validation before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.instance.signInOrSignUp(email, password);

      if (result.requiresEmailVerification) {
        widget.onEmailVerificationNeeded(email);
      } else {
        await _checkStatusAndNotify();
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed') ||
          e.code == 'email_not_confirmed') {
        try {
          await Supabase.instance.client.auth.resend(
            type: OtpType.signup,
            email: email,
          );
        } catch (_) {}
        widget.onEmailVerificationNeeded(email);
      } else {
        _showMessage('Login failed: ${e.message}');
      }
    } catch (e) {
      _showMessage('Login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    // Validate email
    final emailError = _validateEmail(email);
    if (emailError != null) {
      _showMessage(emailError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.requestPasswordReset(email);

      if (!mounted) return;

      // Navigate to the Verification & Reset Screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: email),
        ),
      );
    } catch (e) {
      _showMessage('Failed to send reset link: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialLogin(Future<void> Function() method) async {
    setState(() => _isLoading = true);
    try {
      await method();
      await _checkStatusAndNotify();
    } catch (e) {
      _showMessage('Social login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkStatusAndNotify() async {
    try {
      final status = await AuthService.instance.fetchOnboardingStatus();
      widget.onAuthenticated(status);
    } catch (e) {
      _showMessage('Failed to retrieve account status: $e');
    }
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    const Color vangoBlue = Color(0xFF2D325A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    // 1. BACKGROUND with Clipper
                    ClipPath(
                      clipper: BackgroundClipper(),
                      child: Container(
                        width: double.infinity,
                        height: 450,
                        color: vangoBlue,
                      ),
                    ),

                    // 2. CONTENT
                    SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome to',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'VanGo',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // THE CARD
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 150),
                                    child: Text(
                                      'Get Started',
                                      key: ValueKey<bool>(_isPhoneLogin),
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter your details to log in or sign up',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // TOGGLE BUTTON
                                  Container(
                                    height: 50,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _ToggleTab(
                                            label: 'Phone',
                                            isSelected: _isPhoneLogin,
                                            onTap: () {
                                              setState(() {
                                                _isPhoneLogin = true;
                                              });
                                              // Clear previous validation errors when switching tabs
                                              _formKey.currentState?.reset();
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: _ToggleTab(
                                            label: 'Email',
                                            isSelected: !_isPhoneLogin,
                                            onTap: () {
                                              setState(() {
                                                _isPhoneLogin = false;
                                              });
                                              _formKey.currentState?.reset();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 25),

                                  // INPUT FIELDS
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 150),
                                    child: _isPhoneLogin
                                        ? _buildPhoneInput(vangoBlue)
                                        : _buildEmailInput(vangoBlue),
                                  ),

                                  const SizedBox(height: 20),

                                  // MAIN BUTTON
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : (_isPhoneLogin
                                                ? _handlePhoneLogin
                                                : _handleEmailLogin),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: vangoBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
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
                                              'Continue',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          "Or",
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  Row(
                                    children: [
                                      // Google Button
                                      Expanded(
                                        child: _buildSocialButton(
                                          icon: Image.network(
                                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                                            height: 24,
                                            errorBuilder: (c, o, s) =>
                                                const Icon(
                                                  Icons.g_mobiledata,
                                                  size: 28,
                                                ),
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : () => _handleSocialLogin(
                                                  // Passing all IDs from .env to the Service
                                                  () => AuthService.instance
                                                      .signInWithGoogleNative(
                                                        webClientId: AppConfig
                                                            .googleWebClientId,
                                                      ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildSocialButton(
                                          icon: const Icon(
                                            Icons.apple,
                                            size: 28,
                                            color: Colors.black,
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : (Platform.isIOS
                                                    ? () => _handleSocialLogin(
                                                        AuthService
                                                            .instance
                                                            .signInWithApple,
                                                      )
                                                    : null),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneInput(Color activeColor) {
    return Container(
      key: const ValueKey('PhoneInput'),
      child: _buildTextField(
        controller: _phoneController,
        label: 'Phone Number',
        hint: '+94 7X XXX XXXX',
        icon: Icons.phone_android_rounded,
        inputType: TextInputType.phone,
        activeColor: activeColor,
        validator: _validatePhone,
      ),
    );
  }

  Widget _buildEmailInput(Color activeColor) {
    return Column(
      key: const ValueKey('EmailInput'),
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'name@example.com',
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
          activeColor: activeColor,
          validator: _validateEmail,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '********',
          icon: Icons.lock_outline,
          isPassword: true,
          activeColor: activeColor,
          validator: _validatePassword,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _isLoading ? null : _handleForgotPassword,
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    required Color activeColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: isPassword,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: activeColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 55,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: icon,
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// Custom Clipper to replicate the curved header
class BackgroundClipper extends CustomClipper<Path> {
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
