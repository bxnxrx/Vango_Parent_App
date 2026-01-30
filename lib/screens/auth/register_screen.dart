import 'package:flutter/material.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onBack, required this.onSubmit});

  final VoidCallback onBack;
  final ValueChanged<String> onSubmit;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _stepTitles = ['Personal', 'Child', 'Driver link'];

  int _step = 0;
  final TextEditingController _childNameController = TextEditingController();

  @override
  void dispose() {
    _childNameController.dispose();
    super.dispose();
  }

  // Shared style helper for field labels.
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  // Wraps a label and a form field together to cut repetition.
  Widget _buildLabeledField({
    required String label,
    required Widget field,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        field,
      ],
    );
  }

  // Small step indicator shown under the header.
  Widget _buildStepIndicator() {
    final items = <Widget>[];
    for (var index = 0; index < _stepTitles.length; index += 1) {
      final isActive = index <= _step;
      final background = isActive ? AppColors.accent : AppColors.surface;
      final textColor = isActive ? Colors.white : AppColors.textSecondary;

      items.add(
        Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: background,
              child: Text(
                '${index + 1}',
                style: AppTypography.label.copyWith(color: textColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _stepTitles[index],
              style: AppTypography.label.copyWith(
                color: isActive ? AppColors.accent : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items,
    );
  }

  // Fields for collecting basic guardian details.
  Widget _buildPersonalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledField(
          label: 'Full name',
          field: const TextField(
            decoration: InputDecoration(prefixIcon: Icon(Icons.person_outline)),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'Email',
          field: const TextField(
            decoration: InputDecoration(prefixIcon: Icon(Icons.alternate_email)),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'Phone number',
          field: const TextField(
            decoration: InputDecoration(prefixIcon: Icon(Icons.phone_android)),
          ),
        ),
      ],
    );
  }

  // Fields about the child who will take the ride.
  Widget _buildChildStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledField(
          label: 'Child name',
          field: TextField(
            controller: _childNameController,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.child_care)),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'School',
          field: const TextField(
            decoration: InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'Pickup location',
          field: const TextField(
            decoration: InputDecoration(prefixIcon: Icon(Icons.location_on_outlined)),
          ),
        ),
      ],
    );
  }

  // Final screen for linking to a driver or referral.
  Widget _buildDriverStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledField(
          label: 'Driver code (optional)',
          field: const TextField(
            decoration: InputDecoration(prefixIcon: Icon(Icons.qr_code_2)),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'How did you hear about us?',
          field: const TextField(
            decoration: InputDecoration(prefixIcon: Icon(Icons.chat_outlined)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    if (_step == 0) {
      return _buildPersonalStep();
    }
    if (_step == 1) {
      return _buildChildStep();
    }
    return _buildDriverStep();
  }

  // Move back one page unless we are already at the start.
  void _goBack() {
    if (_step == 0) {
      return;
    }
    setState(() {
      _step -= 1;
    });
  }

  // Advance to the next step or finish the flow.
  void _goForward() {
    final enteredName = _childNameController.text;
    final childName = enteredName.isEmpty ? 'Your child' : enteredName;

    if (_step == 2) {
      widget.onSubmit(childName);
      return;
    }

    setState(() {
      _step += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStep = _step == 0;
    final isLastStep = _step == 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
              Text('Create parent account', style: AppTypography.display.copyWith(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 16),
          _buildStepIndicator(),
          const SizedBox(height: 24),
          _buildStepContent(),
          const SizedBox(height: 24),
          Row(
            children: [
              if (!isFirstStep)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goBack,
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (!isFirstStep) const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: isLastStep ? 'Submit' : 'Next',
                  expanded: true,
                  onPressed: _goForward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

