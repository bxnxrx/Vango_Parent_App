import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class ChildSelectorWidget extends StatelessWidget {
  final List<ChildProfile> linkedChildren;
  final ChildProfile? selectedChild;
  final Function(ChildProfile) onChildSelected;

  const ChildSelectorWidget({
    super.key,
    required this.linkedChildren,
    required this.selectedChild,
    required this.onChildSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    if (linkedChildren.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: linkedChildren.length,
        itemBuilder: (context, index) {
          final child = linkedChildren[index];
          final isSelected = child.id == selectedChild?.id;

          ImageProvider? avatarImage;
          if (child.imageUrl != null && child.imageUrl!.isNotEmpty) {
            avatarImage = CachedNetworkImageProvider(child.imageUrl!);
          }

          return GestureDetector(
            onTap: () => onChildSelected(child),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? AppColors.accent : Colors.transparent, width: 3),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: child.avatarColor.withValues(alpha: 0.2),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(child.name[0].toUpperCase(), style: TextStyle(color: child.avatarColor, fontSize: 20, fontWeight: FontWeight.bold))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    child.name.split(' ')[0],
                    style: AppTypography.body.copyWith(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? textColor : secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TodayRideWidget extends StatelessWidget {
  final ChildProfile selectedChild;
  final bool isTogglingToday;
  final Function(bool isMorning, bool isAfternoon) onUpdateRide;

  const TodayRideWidget({
    super.key,
    required this.selectedChild,
    required this.isTogglingToday,
    required this.onUpdateRide,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    ImageProvider? currentAvatar;
    if (selectedChild.imageUrl != null && selectedChild.imageUrl!.isNotEmpty) {
      currentAvatar = CachedNetworkImageProvider(selectedChild.imageUrl!);
    }

    bool isMorning = selectedChild.attendance == AttendanceState.both || selectedChild.attendance == AttendanceState.morning;
    bool isAfternoon = selectedChild.attendance == AttendanceState.both || selectedChild.attendance == AttendanceState.afternoon;

    String attendanceText = "Going Both Rides";
    Color attendanceColor = AppColors.success;
    if (selectedChild.attendance == AttendanceState.none) {
      attendanceText = "Not Going Today";
      attendanceColor = AppColors.danger;
    } else if (selectedChild.attendance == AttendanceState.morning) {
      attendanceText = "Morning Ride Only";
      attendanceColor = AppColors.accent;
    } else if (selectedChild.attendance == AttendanceState.afternoon) {
      attendanceText = "Afternoon Ride Only";
      attendanceColor = AppColors.accent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          if (!isDark) BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: selectedChild.avatarColor.withValues(alpha: 0.2),
                backgroundImage: currentAvatar,
                child: currentAvatar == null
                    ? Text(selectedChild.name[0].toUpperCase(), style: TextStyle(color: selectedChild.avatarColor, fontSize: 20, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(attendanceText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: attendanceColor)),
                    const SizedBox(height: 4),
                    Text(
                      'Attendance changes allowed until 9 PM previous day',
                      style: AppTypography.body.copyWith(color: secondaryTextColor, fontSize: 11),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Theme.of(context).dividerColor, height: 1),
          ),
          
          if (isTogglingToday)
            const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)))
          else
            Column(
              children: [
                _buildRideSwitchRow(
                  context: context,
                  title: 'Morning Ride',
                  value: isMorning,
                  onChanged: (val) => onUpdateRide(val, isAfternoon),
                ),
                _buildRideSwitchRow(
                  context: context,
                  title: 'Afternoon Ride',
                  value: isAfternoon,
                  onChanged: (val) => onUpdateRide(isMorning, val),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildRideSwitchRow({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceStrong : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade300,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class AttendanceHistoryWidget extends StatelessWidget {
  final Map<String, dynamic> allPlans;

  const AttendanceHistoryWidget({super.key, required this.allPlans});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final pastKeys = allPlans.keys.where((k) => k.compareTo(todayStr) < 0).toList()
          ..sort((a, b) => b.compareTo(a));

    if (pastKeys.isEmpty) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.history, color: secondaryTextColor, size: 32),
            const SizedBox(height: 12),
            Text('No history records found.', style: AppTypography.body.copyWith(color: secondaryTextColor)),
            Text('Default daily attendance is "Both Rides".', style: AppTypography.body.copyWith(color: secondaryTextColor, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: pastKeys.length,
      itemBuilder: (context, index) {
        String dateStr = pastKeys[index];
        final record = allPlans[dateStr];
        AttendanceState state = record['state'];
        DateTime dateObj = DateTime.parse(dateStr);

        String timeAgo = '';
        if (record['updated_at'] != null) {
          DateTime updatedObj = DateTime.parse(record['updated_at']).toLocal();
          timeAgo = ' • Updated at ${DateFormat('h:mm a').format(updatedObj)}';
        }

        String stateStr = "Both Rides";
        Color stateColor = AppColors.success;

        if (state == AttendanceState.none) {
          stateStr = "Not Going"; stateColor = AppColors.danger; 
        } else if (state == AttendanceState.morning) {
          stateStr = "Morning Only"; stateColor = Colors.teal; 
        } else if (state == AttendanceState.afternoon) {
          stateStr = "Afternoon Only"; stateColor = Colors.deepPurple; 
        } else if (state == AttendanceState.pending) {
          stateStr = "Pending"; stateColor = AppColors.warning; 
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(color: stateColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('MMMM d, yyyy').format(dateObj), style: AppTypography.title.copyWith(fontSize: 15, color: textColor)),
                    const SizedBox(height: 2),
                    Text('Marked $stateStr$timeAgo', style: AppTypography.body.copyWith(fontSize: 12, color: secondaryTextColor)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AttendanceSkeletonWidget extends StatelessWidget {
  const AttendanceSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : AppColors.stroke.withValues(alpha: 0.5),
      highlightColor: isDark ? Colors.grey.shade700 : AppColors.surfaceStrong,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 20, width: 120, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 160, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            const SizedBox(height: 32),
            Container(height: 20, width: 120, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 350, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
          ],
        ),
      ),
    );
  }
}