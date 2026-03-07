import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/child_profile.dart'; // Ensure Enums are imported
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class ChildCard extends StatelessWidget {
  const ChildCard({
    super.key,
    required this.child,
    required this.onToggle,
    required this.onTap,
  });

  final ChildProfile child;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // FIX: Compare to Enums, not strings
    final isPaid = child.paymentStatus == PaymentStatus.paid;
    final isDue = child.paymentStatus == PaymentStatus.due;
    final isOverdue = child.paymentStatus == PaymentStatus.overdue;
    final isComing = child.attendance == AttendanceState.coming;

    Color statusColor;
    if (isPaid) {
      statusColor = AppColors.success;
    } else if (isDue) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.danger;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.stroke),
          // FIX: withOpacity -> withValues
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: child.avatarColor.withValues(alpha: 0.2),
                  child: Text(
                    child.name[0].toUpperCase(),
                    style: TextStyle(
                      color: child.avatarColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid
                        ? 'Paid'
                        : isDue
                        ? 'Due'
                        : 'Overdue',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              child.name,
              style: AppTypography.title.copyWith(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              child.school,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isComing ? 'Going' : 'Not Going',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isComing
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                Switch(
                  value: isComing,
                  onChanged: (val) => onToggle(),
                  activeColor: AppColors.accent,
                  activeTrackColor: AppColors.accentLow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
