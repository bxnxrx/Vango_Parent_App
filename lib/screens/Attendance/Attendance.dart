import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

enum AttendanceState { coming, notComing }

class AttendanceScreen extends StatefulWidget {
  final ChildProfile? child;
  const AttendanceScreen({super.key, this.child});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, bool> _attendancePlan = {};
  late List<DateTime> _nextSevenDays;

  @override
  void initState() {
    super.initState();
    _nextSevenDays = List.generate(7, (index) => DateTime.now().add(Duration(days: index + 1)));
    
    for (var date in _nextSevenDays) {
      _attendancePlan[DateFormat('yyyy-MM-dd').format(date)] = true;
    }
  }

  // UPDATED: Enhanced Calendar UI Configuration
  Future<void> _selectAndMarkMultiDates(BuildContext context) async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.multi,
        
        // --- UI CUSTOMIZATION START ---
        // Colors
        selectedDayHighlightColor: AppColors.accent,
        selectedDayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        todayTextStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
        
        // Header & Controls
        controlsTextStyle: AppTypography.title.copyWith(fontSize: 16),
        weekdayLabelTextStyle: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        centerAlignModePicker: true,
        lastMonthIcon: const Icon(Icons.arrow_back_ios, size: 15, color: AppColors.textSecondary),
        nextMonthIcon: const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.textSecondary),
        
        // Buttons
        okButtonTextStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
        cancelButtonTextStyle: const TextStyle(color: AppColors.textSecondary),
        
        // Layout
        dayBorderRadius: BorderRadius.circular(12),
        // --- UI CUSTOMIZATION END ---
      ),
      dialogSize: const Size(325, 400),
      value: [], 
      borderRadius: BorderRadius.circular(24),
    );

    if (results != null && results.isNotEmpty) {
      List<DateTime> selectedDates = results.whereType<DateTime>().toList();
      _showBulkMarkingDialog(context, selectedDates);
    }
  }

  void _showBulkMarkingDialog(BuildContext context, List<DateTime> dates) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Set Status", style: AppTypography.title),
        content: Text("Mark ${dates.length} days as:"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var date in dates) {
                  _attendancePlan[DateFormat('yyyy-MM-dd').format(date)] = false;
                }
              });
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
              setState(() {
                for (var date in dates) {
                  _attendancePlan[DateFormat('yyyy-MM-dd').format(date)] = true;
                }
              });
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Plan Attendance', style: AppTypography.title.copyWith(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.calendar_month, color: AppColors.accent),
                          onPressed: () => _selectAndMarkMultiDates(context),
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
        ),
      ),
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

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Navigator.canPop(context) ? Icons.arrow_back_ios_new : Icons.menu, color: AppColors.accent, size: 22),
        onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : null,
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
      itemCount: 4,
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