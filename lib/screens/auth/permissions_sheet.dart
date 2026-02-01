import 'package:flutter/material.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class PermissionsSheet extends StatefulWidget {
  const PermissionsSheet({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends State<PermissionsSheet> {
  bool _locationApproved = true;
  bool _notificationApproved = true;
  bool _backgroundUpdates = false;

  void _finish() {
    if (!_locationApproved || !_notificationApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location and notifications must stay enabled to continue.')),
      );
      return;
    }
    widget.onComplete();
  }

  Widget _buildToggle({required String title, required String description, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.subtitle),
                const SizedBox(height: 4),
                Text(description, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enable permissions', style: AppTypography.display.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text('We need a few permissions to keep you connected with your driver and child.', style: AppTypography.body),
            const SizedBox(height: 20),
            _buildToggle(
              title: 'Location access',
              description: 'Required to show live van location and pickup ETA.',
              value: _locationApproved,
              onChanged: (value) => setState(() => _locationApproved = value),
            ),
            const SizedBox(height: 12),
            _buildToggle(
              title: 'Push notifications',
              description: 'Alerts for boarding, drop-off, and schedule changes.',
              value: _notificationApproved,
              onChanged: (value) => setState(() => _notificationApproved = value),
            ),
            const SizedBox(height: 12),
            _buildToggle(
              title: 'Background updates',
              description: 'Optional: keep trip status fresh even when the app is closed.',
              value: _backgroundUpdates,
              onChanged: (value) => setState(() => _backgroundUpdates = value),
            ),
            const SizedBox(height: 24),
            GradientButton(label: 'Finish setup', expanded: true, onPressed: _finish),
          ],
        ),
      ),
    );
  }
}
