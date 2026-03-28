import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType inputType;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onToggleVisibility;
  final Color activeColor;
  final bool isDark;
  final String? Function(String?)? validator;
  final bool readOnly;
  final String? prefixText;

  const CommonTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.activeColor,
    required this.isDark,
    this.autofillHints,
    this.inputFormatters,
    this.inputType = TextInputType.text,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onToggleVisibility,
    this.validator,
    this.readOnly = false,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkStroke : Colors.grey.shade300;
    final readOnlyBorder = isDark ? Colors.transparent : Colors.grey.shade200;
    final readOnlyBg = isDark ? AppColors.darkBackground : Colors.grey.shade100;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final hintColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade500;

    return Semantics(
      label: label,
      textField: true,
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        textInputAction: isPassword
            ? TextInputAction.done
            : TextInputAction.next,
        obscureText: isPassword && !isPasswordVisible,
        autofillHints: autofillHints,
        inputFormatters: inputFormatters,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
        style: AppTypography.body.copyWith(
          color: readOnly ? hintColor : textColor,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.body.copyWith(color: hintColor),
          hintText: hint,
          hintStyle: AppTypography.body.copyWith(color: hintColor),
          prefixIcon: Icon(icon, color: hintColor, size: 22),
          prefixText: prefixText,
          prefixStyle: AppTypography.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: hintColor,
                    size: 22,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    // ✅ FIXED: Null-aware call operator handles the promotion issue securely
                    onToggleVisibility?.call();
                  },
                )
              : null,
          filled: readOnly,
          fillColor: readOnly
              ? readOnlyBg
              : (isDark ? AppColors.darkSurface : Colors.white),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: readOnly ? readOnlyBorder : borderColor,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: readOnly ? readOnlyBorder : activeColor,
              width: readOnly ? 1.5 : 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
      ),
    );
  }
}
