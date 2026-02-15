import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class AttendanceScreen extends StatefulWidget {
  final ChildProfile? child;
  const AttendanceScreen({super.key, this.child});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final List<Map<String, dynamic>> _history = [
    {
      'date': 'Oct 26, 2023',
      'status': AttendanceState.coming,
      'time': '06:42 AM',
    },
    {'date': 'Oct 25, 2023', 'status': AttendanceState.notComing, 'time': '--'},
    {
      'date': 'Oct 24, 2023',
      'status': AttendanceState.coming,
      'time': '06:55 AM',
    },
    {
      'date': 'Oct 23, 2023',
      'status': AttendanceState.coming,
      'time': '06:40 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final String displayName = widget.child?.name ?? "All Students";
    final Color displayColor = widget.child?.avatarColor ?? AppColors.accent;

    // We use a Column + AppBar here.
    // IMPORTANT: No Scaffold here because AppShell already provides one!
    return Column(
      children: [
        AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading:
              false, // We control the leading icon manually
          leading: IconButton(
            icon: Icon(
              Navigator.canPop(context) ? Icons.arrow_back_ios_new : Icons.menu,
              color: AppColors.accent,
              size: 22,
            ),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                // This now correctly opens the AppShell's Sidebar
                Scaffold.of(context).openDrawer();
              }
            },
          ),
          title: Text('Attendance History', style: AppTypography.title),
          centerTitle: true,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildChildSummaryCard(displayName, displayColor),
                const SizedBox(height: 24),
                Text(
                  'Recent Logs',
                  style: AppTypography.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return _AttendanceHistoryTile(
                      date: item['date'],
                      status: item['status'],
                      time: item['time'],
                    );
                  },
                ),
                const SizedBox(height: 100), // Space for the bottom nav bar
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildSummaryCard(String name, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.headline.copyWith(fontSize: 20),
                ),
                Text(
                  'Monthly Attendance: 92%',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceHistoryTile extends StatelessWidget {
  final String date;
  final AttendanceState status;
  final String time;
  const _AttendanceHistoryTile({
    required this.date,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPresent = status == AttendanceState.coming;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: isPresent ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: AppTypography.title.copyWith(fontSize: 15)),
                Text(
                  isPresent ? 'Picked up at $time' : 'Marked as Absent',
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
