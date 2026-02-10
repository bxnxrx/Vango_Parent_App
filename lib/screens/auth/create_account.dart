import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // Removed _emergencyContactController

  // Dropdown State
  String? _selectedRelationship;
  final List<String> _relationshipTypes = ['Parent', 'Guardian', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadCachedPhone();
  }

  Future<void> _loadCachedPhone() async {
    final cached = await AuthService.instance.getCachedPhone();
    if (cached != null && mounted) {
      _phoneController.text = cached;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    // Removed disposal of _emergencyContactController
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRelationship == null) {
      _showMessage('Please select your relationship type.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final emailInput = _emailController.text.trim();

      // 1. Save Parent Profile
      await AuthService.instance.saveParentProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        // FIX: Send null if empty so backend validation doesn't fail on ""
        email: emailInput.isEmpty ? null : emailInput,
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
                                  ),
                                  const SizedBox(height: 16),

                                  // Mobile Number
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'Mobile Number',
                                    hint: '+94 7X XXX XXXX',
                                    icon: Icons.phone_android_rounded,
                                    inputType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 16),

                                  // Relationship Dropdown
                                  _buildDropdown(),
                                  const SizedBox(height: 16),

                                  // Email
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    hint: 'john@example.com',
                                    icon: Icons.email_outlined,
                                    inputType: TextInputType.emailAddress,
                                    required: false,
                                  ),

                                  // Removed Emergency Contact Field
                                  const SizedBox(height: 32),

                                  // Submit Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: _submitting
                                          ? null
                                          : _submitDetails,
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
    bool required = true,
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
          validator: required
              ? (val) =>
                    (val == null || val.isEmpty) ? '$label is required' : null
              : null,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
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
          validator: (val) => val == null ? 'Required' : null,
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
