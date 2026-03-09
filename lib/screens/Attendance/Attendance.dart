import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AttendanceScreen extends StatefulWidget {
  final ChildProfile? child;
  const AttendanceScreen({super.key, this.child});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ParentDataService _dataService = ParentDataService.instance;

  List<ChildProfile> _linkedChildren = [];
  ChildProfile? _selectedChild;

  bool _isLoading = true;
  bool _isTogglingToday = false;

  final Map<String, AttendanceState> _futurePlans = {};
  final Map<String, AttendanceState> _historyPlans = {};
  late List<DateTime> _nextSevenDays;

  @override
  void initState() {
    super.initState();
    _nextSevenDays = List.generate(
      7,
      (index) => DateTime.now().add(Duration(days: index + 1)),
    );
    _fetchLinkedChildren();
  }

  Future<void> _fetchLinkedChildren() async {
    setState(() => _isLoading = true);
    try {
      final childrenList = await _dataService.fetchChildren();
      // Filter ONLY children who have a driver assigned
      _linkedChildren = childrenList
          .where(
            (c) => c.linkedDriverId != null && c.linkedDriverId!.isNotEmpty,
          )
          .toList();

      if (_linkedChildren.isNotEmpty) {
        if (widget.child != null &&
            _linkedChildren.any((c) => c.id == widget.child!.id)) {
          _selectedChild = _linkedChildren.firstWhere(
            (c) => c.id == widget.child!.id,
          );
        } else {
          _selectedChild = _linkedChildren.first;
        }
        await _fetchAttendanceData();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchAttendanceData() async {
    if (_selectedChild == null) return;
    setState(() => _isLoading = true);
    try {
      final plans = await _dataService.fetchFutureAttendance(
        _selectedChild!.id,
      );
      if (mounted) {
        setState(() {
          _futurePlans.clear();
          _historyPlans.clear();

          final today = DateTime.now();
          final todayStr = DateFormat('yyyy-MM-dd').format(today);

          plans.forEach((dateStr, state) {
            if (dateStr.compareTo(todayStr) >= 0) {
              _futurePlans[dateStr] = state;
            } else {
              _historyPlans[dateStr] = state;
            }
          });

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchChild(ChildProfile child) {
    if (_selectedChild?.id == child.id) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedChild = child;
      _futurePlans.clear();
      _historyPlans.clear();
    });
    _fetchAttendanceData();
  }

  Future<void> _toggleToday(bool isComing) async {
    if (_selectedChild == null) return;
    HapticFeedback.selectionClick();
    setState(() => _isTogglingToday = true);

    final newState = isComing
        ? AttendanceState.coming
        : AttendanceState.notComing;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _dataService.updateAttendance(_selectedChild!.id, newState);
      if (mounted) {
        setState(() {
          _selectedChild = _selectedChild!.copyWith(attendance: newState);

          // Update it in the list as well so selector stays in sync
          final index = _linkedChildren.indexWhere(
            (c) => c.id == _selectedChild!.id,
          );
          if (index != -1) {
            _linkedChildren[index] = _selectedChild!;
          }

          _isTogglingToday = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedChild!.name} marked as ${isComing ? 'Going' : 'Not Going'} for today.',
            ),
            backgroundColor: isComing ? AppColors.success : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingToday = false);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to update today\'s status'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _updateFutureDates(
    List<DateTime> dates,
    AttendanceState newState,
  ) async {
    if (_selectedChild == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    final formattedDates = dates
        .map((d) => DateFormat('yyyy-MM-dd').format(d))
        .toList();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _dataService.updateFutureAttendance(
        _selectedChild!.id,
        formattedDates,
        newState,
      );

      setState(() {
        for (var date in formattedDates) {
          _futurePlans[date] = newState;
        }
        _isLoading = false;
      });

      if (mounted) {
        String msg = newState == AttendanceState.coming
            ? 'Going'
            : (newState == AttendanceState.pending ? 'Pending' : 'Not Going');
        Color bgColor = newState == AttendanceState.notComing
            ? AppColors.danger
            : (newState == AttendanceState.pending
                  ? AppColors.warning
                  : AppColors.success);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Marked $msg for ${dates.length} day(s).'),
            backgroundColor: bgColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to save dates'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _selectAndMarkMultiDates(BuildContext context) async {
    if (_selectedChild == null) return;

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.multi,
        selectedDayHighlightColor: AppColors.accent,
        selectedDayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        todayTextStyle: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
        ),
        controlsTextStyle: AppTypography.title.copyWith(fontSize: 16),
        weekdayLabelTextStyle: AppTypography.body.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
        centerAlignModePicker: true,
        lastMonthIcon: const Icon(
          Icons.arrow_back_ios,
          size: 15,
          color: AppColors.textSecondary,
        ),
        nextMonthIcon: const Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: AppColors.textSecondary,
        ),
        okButtonTextStyle: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
        ),
        cancelButtonTextStyle: const TextStyle(color: AppColors.textSecondary),
        dayBorderRadius: BorderRadius.circular(12),
        firstDate: DateTime.now().add(const Duration(days: 1)),
      ),
      dialogSize: const Size(325, 400),
      value: [],
      borderRadius: BorderRadius.circular(24),
    );

    if (results != null && results.isNotEmpty) {
      if (!context.mounted) return;
      List<DateTime> selectedDates = results.whereType<DateTime>().toList();
      _showBulkMarkingDialog(context, selectedDates);
    }
  }

  void _showBulkMarkingDialog(BuildContext context, List<DateTime> dates) {
    // Rule: Can only mark pending if ALL selected dates are > 7 days from today
    final now = DateTime.now();
    bool canMarkPending = dates.every((d) => d.difference(now).inDays >= 7);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Plan Attendance", style: AppTypography.title),
        content: Text("Mark ${dates.length} selected day(s) as:"),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _updateFutureDates(dates, AttendanceState.coming);
                },
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text(
                  "Going",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _updateFutureDates(dates, AttendanceState.notComing);
                },
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text(
                  "Not Going",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: canMarkPending
                      ? AppColors.warning
                      : AppColors.stroke,
                  foregroundColor: canMarkPending
                      ? Colors.white
                      : AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: canMarkPending
                    ? () {
                        Navigator.pop(context);
                        _updateFutureDates(dates, AttendanceState.pending);
                      }
                    : null,
                icon: const Icon(Icons.help_outline, size: 18),
                label: Text(
                  canMarkPending
                      ? "Pending (Not Sure)"
                      : "Pending (Disabled < 7 days)",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _selectedChild == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_linkedChildren.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Attendance', style: AppTypography.title),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.accentLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_bus_filled_outlined,
                    size: 64,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 24),
                Text('No Driver Linked', style: AppTypography.headline),
                const SizedBox(height: 12),
                Text(
                  'To manage daily and future attendance, you must first assign a driver to your child.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Attendance', style: AppTypography.title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildChildSelector(),
          Expanded(
            child: _isLoading && _futurePlans.isEmpty && _historyPlans.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Ride",
                          style: AppTypography.title.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        _buildTodayCard(),

                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Upcoming Planner',
                              style: AppTypography.title.copyWith(fontSize: 18),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _selectAndMarkMultiDates(context),
                              icon: const Icon(
                                Icons.calendar_month,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              label: const Text(
                                'Calendar',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSevenDayPlanner(),

                        const SizedBox(height: 32),
                        Text(
                          'Attendance History',
                          style: AppTypography.title.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        _buildHistoryList(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    if (_linkedChildren.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _linkedChildren.length,
        itemBuilder: (context, index) {
          final child = _linkedChildren[index];
          final isSelected = child.id == _selectedChild?.id;

          ImageProvider? avatarImage;
          if (child.imageUrl != null && child.imageUrl!.isNotEmpty) {
            avatarImage = CachedNetworkImageProvider(child.imageUrl!);
          }

          return GestureDetector(
            onTap: () => _switchChild(child),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: child.avatarColor.withValues(alpha: 0.2),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              child.name[0].toUpperCase(),
                              style: TextStyle(
                                color: child.avatarColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    child.name.split(' ')[0],
                    style: AppTypography.body.copyWith(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
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

  Widget _buildTodayCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedChild!.attendance == AttendanceState.coming
                    ? 'Going to School'
                    : 'Not Going Today',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectedChild!.attendance == AttendanceState.coming
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Driver will be notified immediately.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (_isTogglingToday)
            const SizedBox(
              width: 48,
              height: 48,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            )
          else
            Switch(
              value: _selectedChild!.attendance == AttendanceState.coming,
              activeThumbColor: AppColors.success,
              activeTrackColor: AppColors.success.withValues(alpha: 0.5),
              inactiveThumbColor: AppColors.danger,
              inactiveTrackColor: AppColors.danger.withValues(alpha: 0.2),
              onChanged: _toggleToday,
            ),
        ],
      ),
    );
  }

  Widget _buildSevenDayPlanner() {
    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _nextSevenDays.length,
        itemBuilder: (context, index) {
          DateTime date = _nextSevenDays[index];
          String dateKey = DateFormat('yyyy-MM-dd').format(date);

          AttendanceState dayState =
              _futurePlans[dateKey] ?? AttendanceState.coming;

          Color stateColor = AppColors.success;
          IconData stateIcon = Icons.check_circle;
          if (dayState == AttendanceState.notComing) {
            stateColor = AppColors.danger;
            stateIcon = Icons.cancel;
          } else if (dayState == AttendanceState.pending) {
            stateColor = AppColors.warning;
            stateIcon = Icons.help;
          }

          return GestureDetector(
            onTap: () {
              // Quick toggle cycles: Coming -> Not Coming -> Coming
              // (If it was pending, first tap makes it Coming)
              AttendanceState newState = dayState == AttendanceState.coming
                  ? AttendanceState.notComing
                  : AttendanceState.coming;
              _updateFutureDates([date], newState);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 75,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: stateColor.withValues(alpha: 0.5),
                  width: dayState == AttendanceState.coming ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: AppTypography.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: stateColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: AppTypography.title.copyWith(
                      fontSize: 22,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(stateIcon, size: 20, color: stateColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_historyPlans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.history, color: AppColors.textSecondary, size: 32),
            const SizedBox(height: 12),
            Text(
              'No past exceptions recorded.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Default daily attendance is "Going".',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Sort history newest first
    final sortedKeys = _historyPlans.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        String dateStr = sortedKeys[index];
        AttendanceState state = _historyPlans[dateStr]!;
        DateTime dateObj = DateTime.parse(dateStr);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.stroke.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      (state == AttendanceState.coming
                              ? AppColors.success
                              : (state == AttendanceState.notComing
                                    ? AppColors.danger
                                    : AppColors.warning))
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state == AttendanceState.coming
                      ? Icons.check_circle
                      : (state == AttendanceState.notComing
                            ? Icons.cancel
                            : Icons.help),
                  color: state == AttendanceState.coming
                      ? AppColors.success
                      : (state == AttendanceState.notComing
                            ? AppColors.danger
                            : AppColors.warning),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(dateObj),
                      style: AppTypography.title.copyWith(fontSize: 15),
                    ),
                    Text(
                      state == AttendanceState.coming
                          ? 'Marked as Going'
                          : (state == AttendanceState.notComing
                                ? 'Marked as Not Going'
                                : 'Marked Pending (Converted to Going)'),
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
      },
    );
  }
}
