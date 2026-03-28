import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vango_parent_app/services/language_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class CommonLanguageSelector extends StatelessWidget {
  final bool isDark;

  const CommonLanguageSelector({super.key, required this.isDark});

  String _getLanguageName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.sinhala:
        return 'සිංහල';
      case AppLanguage.tamil:
        return 'தமிழ்';
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final selectedTextColor = isDark ? Colors.white : AppColors.accent;
    final unselectedTextColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade700;

    return Semantics(
      button: true,
      label: "Select Language",
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: PopupMenuButton<AppLanguage>(
          onSelected: (AppLanguage newValue) {
            HapticFeedback.selectionClick();
            LanguageService.instance.setLanguage(newValue);
          },
          color: menuBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          offset: const Offset(0, 45),
          itemBuilder: (context) => AppLanguage.values.map((lang) {
            final isSelected =
                LanguageService.instance.currentLanguage.value == lang;
            return PopupMenuItem<AppLanguage>(
              value: lang,
              child: Center(
                child: Text(
                  _getLanguageName(lang),
                  style: AppTypography.body.copyWith(
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getLanguageName(
                    LanguageService.instance.currentLanguage.value,
                  ),
                  style: AppTypography.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
