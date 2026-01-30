import 'package:flutter/material.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class PermissionsSheet extends StatelessWidget {
  const PermissionsSheet({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Almost done', style: AppTypography.display.copyWith(fontSize: 28)),
          const SizedBox(height: 8),
          Text('Enable the required permissions to get real-time pickup updates and driver contact info.', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          const _PermissionTile(icon: Icons.location_on, title: 'Location access', description: 'Used to show your child\'s live bus position and proximity to your home.'),
          const SizedBox(height: 16),
          const _PermissionTile(icon: Icons.notifications_active, title: 'Notifications', description: 'Critical alerts for pickups, delays, and emergency broadcasts.'),
          const SizedBox(height: 16),
          const _PermissionTile(icon: Icons.call, title: 'Phone', description: 'Lets you call the assigned driver directly from the chat screen.'),
          const SizedBox(height: 24),
          GradientButton(label: 'Enable & continue', expanded: true, onPressed: onComplete),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.title),
                  const SizedBox(height: 4),
                  Text(description, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Switch(value: true, onChanged: (_) {}),
          ],
        ),
      ),
    );
  }
}
