import 'package:flutter/material.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class EmergencyButton extends StatelessWidget {
  final VoidCallback onTap;

  // Removed super.key
  const EmergencyButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      icon: Icon(Icons.shield_moon_outlined),
      label: Text(
        'Emergency',
        style: AppTypography.label.copyWith(color: Colors.white),
      ),
      backgroundColor: AppColors.danger,
      elevation: 6,
    );
  }
}