import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  // Store status for any date (DateKey -> isComing)
  final Map<String, bool> _attendancePlan = {};
  late List<DateTime> _nextSevenDays;

  @override
  void initState() {
    super.initState();
    // Generate the next 7 days for the horizontal strip
    _nextSevenDays = List.generate(7, (index) => DateTime.now().add(Duration(days: index + 1)));
    
    // Default the next 7 days to 'Coming' (true)
    for (var date in _nextSevenDays) {
      _attendancePlan[DateFormat('yyyy-MM-dd').format(date)] = true;
    }
  }

  // 1. Function to open calendar and then ask: Coming or Not Coming?
  Future<void> _selectAndMarkDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              onSurface: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // After selecting date, show a dialog to mark status
      _showMarkingDialog(context, picked);
    }
  }

  // 2. Dialog to specifically mark the chosen date
  void _showMarkingDialog(BuildContext context, DateTime date) {
    String dateKey = DateFormat('yyyy-MM-dd').format(date);
    String formattedDate = DateFormat('MMM dd, yyyy').format(date);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Mark Attendance", style: AppTypography.title),
        content: Text("Is your child coming on $formattedDate?"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _attendancePlan[dateKey] = false); // Mark Not Coming
              Navigator.pop(context);
            },
            child: const Text("Not Coming", style: TextStyle(color: AppColors.danger)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() => _attendancePlan[dateKey] = true); // Mark Coming
              Navigator.pop(context);
            },
            child: const Text("Coming", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = widget.child?.name ?? "All Students";
    final Color displayColor = widget.child?.avatarColor ?? AppColors.accent;

    return Column(
      children: [
        _buildAppBar(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildChildSummaryCard(displayName, displayColor),
                const SizedBox(height: 24),
                
                // Header with the functional Calendar Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Plan Next 7 Days', style: AppTypography.title.copyWith(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: AppColors.accent),
                      onPressed: () => _selectAndMarkDate(context), // Trigger the logic
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                _buildSevenDayPlanner(),
                
                const SizedBox(height: 24),
                Text('Recent Logs', style: AppTypography.title.copyWith(fontSize: 18)),
                const SizedBox(height: 12),
                _buildHistoryList(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSevenDayPlanner() {
    return SizedBox(
      height: 115,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _nextSevenDays.length,
        itemBuilder: (context, index) {
          DateTime date = _nextSevenDays[index];
          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          bool isComing = _attendancePlan[dateKey] ?? false;

          return GestureDetector(
            onTap: () => setState(() => _attendancePlan[dateKey] = !isComing),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 75,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isComing ? AppColors.success.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isComing ? AppColors.success : AppColors.stroke,
                  width: isComing ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: AppTypography.body.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(DateFormat('d').format(date), style: AppTypography.title.copyWith(fontSize: 20)),
                  const SizedBox(height: 8),
                  Icon(
                    isComing ? Icons.check_circle : Icons.cancel,
                    size: 22,
                    color: isComing ? AppColors.success : AppColors.danger,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // UI helpers for AppBar, Summary, and History based on your file
  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(Navigator.canPop(context) ? Icons.arrow_back_ios_new : Icons.menu, color: AppColors.accent, size: 22),
        onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : Scaffold.of(context).openDrawer(),
      ),
      title: Text('Attendance', style: AppTypography.title),
      centerTitle: true,
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
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.headline.copyWith(fontSize: 20)),
                Text('Monthly Attendance: 92%', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4, // Simplified for brevity based on _history list
      itemBuilder: (context, index) {
        return _AttendanceHistoryTile(
          date: 'Oct ${26 - index}, 2023',
          status: index == 1 ? AttendanceState.notComing : AttendanceState.coming,
          time: '06:40 AM',
        );
      },
    );
  }
}

// Re-using the private History Tile from your Attendance.dart
class _AttendanceHistoryTile extends StatelessWidget {
  final String date;
  final AttendanceState status;
  final String time;
  const _AttendanceHistoryTile({required this.date, required this.status, required this.time});

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
          Icon(isPresent ? Icons.check_circle : Icons.cancel, color: isPresent ? AppColors.success : AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: AppTypography.title.copyWith(fontSize: 15)),
                Text(isPresent ? 'Picked up at $time' : 'Marked as Absent', style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}