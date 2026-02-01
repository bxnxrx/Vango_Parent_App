import 'package:flutter/material.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.onOpenOnboarding,
    required this.onClose,
  });

  final VoidCallback onOpenOnboarding;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _SettingItem(
        icon: Icons.person_2_outlined,
        title: 'Profile & guardians',
      ),
      const _SettingItem(icon: Icons.child_care, title: 'Children & routes'),
      const _SettingItem(
        icon: Icons.notifications_active_outlined,
        title: 'Notifications',
      ),
      const _SettingItem(icon: Icons.translate_outlined, title: 'Language'),
      const _SettingItem(
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy & safety',
      ),
      _SettingItem(
        icon: Icons.help_outline,
        title: 'Help center',
        onTap: () {},
      ),
      _SettingItem(
        icon: Icons.auto_stories,
        title: 'View onboarding again',
        onTap: onOpenOnboarding,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          onTap: () {
            onClose();
            item.onTap?.call();
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: AppColors.accent, size: 20),
          ),
          title: Text(
            item.title,
            style: AppTypography.title.copyWith(fontSize: 15),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textSecondary,
          ),
        );
      },
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 72, endIndent: 20),
      itemCount: items.length,
    );
  }
}

class _SettingItem {
  const _SettingItem({required this.icon, required this.title, this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
}
