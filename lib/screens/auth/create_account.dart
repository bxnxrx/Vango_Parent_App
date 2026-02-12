import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vango_parent_app/screens/auth/otp_screen.dart';
import 'package:vango_parent_app/services/auth_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    required this.onProfileCompleted,
    required this.onBack,
  });

  final VoidCallback onProfileCompleted;
  final VoidCallback onBack;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // State to lock fields if auto-detected
  bool _emailReadOnly = false;
  bool _phoneReadOnly = false;

  // Dropdown State
  String? _selectedRelationship;
  final List<String> _relationshipTypes = ['Parent', 'Guardian', 'Other'];

  @override
  void initState() {
    super.initState();
    _autoDetectUser();
  }

  Future<void> _autoDetectUser() async {
    final user = AuthService.instance.currentUser;
    final cachedPhone = await AuthService.instance.getCachedPhone();

    if (mounted) {
      setState(() {
        // 1. Auto-fill and Lock Email if present in Auth
        if (user?.email != null && user!.email!.isNotEmpty) {
          _emailController.text = user.email!;
          _emailReadOnly = true;
        }

        // 2. Auto-fill and Lock Phone if present in Auth
        if (user?.phone != null && user!.phone!.isNotEmpty) {
          _phoneController.text = user.phone!;
          _phoneReadOnly = true;
        } else if (cachedPhone != null && _phoneController.text.isEmpty) {
          // Fallback to cached phone
          _phoneController.text = cachedPhone;
        }
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- VALIDATORS ---

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile Number is required';
    }
    final cleanPhone = value.replaceAll(' ', '');
    // Regex: Starts with optional +, followed by 94, then 9 digits
    final phoneRegex = RegExp(r'^\+?94[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Invalid format (use +947XXXXXXXX)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // --- ACTIONS ---

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Please check the form for errors.');
      return;
    }
    if (_selectedRelationship == null) {
      _showMessage('Please select your relationship type.');
      return;
    }

    // Normalize inputs
    var phoneInput = _phoneController.text.trim().replaceAll(' ', '');
    if (!phoneInput.startsWith('+')) {
      phoneInput = '+$phoneInput';
    }
    final emailInput = _emailController.text.trim();

    // SCENARIO 1: User signed up via Email -> Phone is editable -> Must Verify Phone & Link
    if (!_phoneReadOnly) {
      await _verifyPhoneAndSave(phoneInput, emailInput);
      return;
    }

    // SCENARIO 2: User signed up via Phone -> Email is editable -> Must Verify Email & Link
    if (!_emailReadOnly && emailInput.isNotEmpty) {
      await _verifyEmailAndSave(emailInput, phoneInput);
      return;
    }

    // SCENARIO 3: No new verification needed (e.g. Phone Auth, Email empty)
    await _saveProfile(phoneInput, emailInput);
  }

  Future<void> _verifyPhoneAndSave(String phone, String email) async {
    setState(() => _submitting = true);
    try {
      // 1. Send Link OTP to the new phone
      await AuthService.instance.linkPhone(phone);

      if (!mounted) return;
      setState(() => _submitting = false);

      // 2. Navigate to OTP Screen with Custom Linking Logic
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            identifier: phone,
            isEmail: false,
            // Override the verification logic to perform "Phone Change" verification
            onVerifyOverride: (code) async {
              await AuthService.instance.verifyLinkedPhone(
                phone: phone,
                token: code,
              );
            },
            // Override resend to use updateUser logic
            onResendOverride: () async {
              await AuthService.instance.linkPhone(phone);
            },
            onVerified: () async {
              // 3. On success, pop OTP screen and save
              Navigator.pop(context);
              await _saveProfile(phone, email);
            },
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } catch (e) {
      setState(() => _submitting = false);
      _showMessage('Failed to send verification code: $e');
    }
  }

  Future<void> _verifyEmailAndSave(String email, String phone) async {
    setState(() => _submitting = true);
    try {
      // 1. Send Link OTP to the new email
      await AuthService.instance.linkEmail(email);

      if (!mounted) return;
      setState(() => _submitting = false);

      // 2. Navigate to OTP Screen with Custom Linking Logic
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            identifier: email,
            isEmail: true,
            // Override the verification logic to perform "Email Change" verification
            onVerifyOverride: (code) async {
              await AuthService.instance.verifyLinkedEmail(
                email: email,
                token: code,
              );
            },
            // Override resend to use updateUser logic
            onResendOverride: () async {
              await AuthService.instance.linkEmail(email);
            },
            onVerified: () async {
              // 3. On success, pop OTP screen and save
              Navigator.pop(context);
              await _saveProfile(phone, email);
            },
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } catch (e) {
      setState(() => _submitting = false);
      _showMessage('Failed to send verification code: $e');
    }
  }

  Future<void> _saveProfile(String phone, String email) async {
    setState(() => _submitting = true);
    try {
      // 1. Save Parent Profile
      await AuthService.instance.saveParentProfile(
        fullName: _fullNameController.text.trim(),
        phone: phone,
        email: email.isEmpty ? null : email,
        relationship: _selectedRelationship,
      );

      // 2. Mark Complete & Continue
      await AuthService.instance.markProfileCompleted();
      widget.onProfileCompleted();
    } catch (e) {
      _showMessage('Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleCancel() async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sign Out?'),
            content: const Text(
              'Are you sure you want to cancel setup and sign out?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await AuthService.instance.cancelSignup();
      widget.onBack();
    }
  }

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
                    // 1. Blue Curved Background
                    ClipPath(
                      clipper: _BackgroundClipper(),
                      child: Container(
                        width: double.infinity,
                        height: 450,
                        color: vangoBlue,
                      ),
                    ),

                    // 2. Content
                    SafeArea(
                      child: Column(
                        children: [
                          // Custom App Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _handleCancel,
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Complete Profile',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Header Text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Text(
                                  'Tell us about yourself',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'We need a few details to set up your parent account.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // 3. Floating Form Card
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            padding: const EdgeInsets.all(24),
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personal Details',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Full Name
                                  _buildTextField(
                                    controller: _fullNameController,
                                    label: 'Full Name',
                                    hint: 'e.g. John Doe',
                                    icon: Icons.person_outline,
                                    validator: _validateName,
                                  ),
                                  const SizedBox(height: 16),

                                  // Mobile Number
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'Mobile Number',
                                    hint: '+94 7X XXX XXXX',
                                    icon: Icons.phone_android_rounded,
                                    inputType: TextInputType.phone,
                                    validator: _validatePhone,
                                    readOnly: _phoneReadOnly,
                                  ),
                                  const SizedBox(height: 16),

                                  // Relationship Dropdown
                                  _buildDropdown(),
                                  const SizedBox(height: 16),

                                  // Email
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email Address (Optional)',
                                    hint: 'john@example.com',
                                    icon: Icons.email_outlined,
                                    inputType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                    readOnly: _emailReadOnly,
                                  ),

                                  const SizedBox(height: 32),

                                  // Submit Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: _submitting
                                          ? null
                                          : _handleSubmit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: vangoBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _submitting
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D325A),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          validator: validator,
          readOnly: readOnly,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: readOnly ? Colors.grey.shade600 : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: readOnly ? Colors.grey.shade300 : Colors.black,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: readOnly
                    ? Colors.grey.shade300
                    : const Color(0xFF2D325A),
                width: readOnly ? 1 : 2,
              ),
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
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Relationship',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D325A),
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedRelationship,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          validator: (val) =>
              val == null ? 'Please select a relationship' : null,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Select Type',
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.people_outline, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.black, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF2D325A), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
          items: _relationshipTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (val) => setState(() => _selectedRelationship = val),
        ),
      ],
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
