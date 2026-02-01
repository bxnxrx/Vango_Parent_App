import 'package:flutter/material.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool secondary;

  // Standard constructor without excessive const
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    // Basic if-else for styles
    Color textColor;
    if (secondary) {
      textColor = AppColors.textPrimary;
    } else {
      textColor = Colors.white;
    }

    final textStyle = AppTypography.label.copyWith(
      color: textColor,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );

    // Manual box decoration construction
    BoxDecoration decoration;
    if (secondary) {
      decoration = BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.stroke),
      );
    } else {
      decoration = BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.35),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      );
    }

    Widget content = Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: textColor),
            SizedBox(width: 8),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );

    Widget buttonChild = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: content,
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: buttonChild);
    }

    return buttonChild;
  }
}