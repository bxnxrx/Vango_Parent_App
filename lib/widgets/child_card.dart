import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class ChildCard extends StatelessWidget {
  final ChildProfile child;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const ChildCard({
    Key? key,
    required this.child,
    required this.onToggle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Converting switch expression to normal if-else statements (Student style)
    String paymentLabel;
    if (child.paymentStatus == PaymentStatus.overdue) {
      paymentLabel = 'Overdue';
    } else if (child.paymentStatus == PaymentStatus.due) {
      paymentLabel = 'Due soon';
    } else {
      paymentLabel = 'Paid';
    }

    Color paymentColor;
    if (child.paymentStatus == PaymentStatus.overdue) {
      paymentColor = AppColors.danger;
    } else if (child.paymentStatus == PaymentStatus.due) {
      paymentColor = AppColors.warning;
    } else {
      paymentColor = AppColors.success;
    }

    String attendanceLabel;
    if (child.attendance == AttendanceState.coming) {
      attendanceLabel = 'Coming';
    } else {
      attendanceLabel = 'Not coming';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.stroke.withOpacity(0.6)),
          boxShadow: AppShadows.subtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: child.avatarColor,
              child: Text(
                child.name.substring(0, 1),
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 12),
            Text(child.name, style: AppTypography.title),
            Text(
              child.school,
              style: AppTypography.body.copyWith(fontSize: 14),
            ),
            SizedBox(height: 12),

            // Inline Badge Container manually
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                '${child.pickupTime} pickup',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),

            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onToggle,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          child.attendance == AttendanceState.coming
                          ? AppColors.accent.withOpacity(0.1)
                          : AppColors.danger.withOpacity(0.1),
                      padding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      attendanceLabel,
                      style: AppTypography.label.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),

                // Another inline badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: paymentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    paymentLabel,
                    style: AppTypography.label.copyWith(
                      color: paymentColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}