import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

// Import our new ViewModel and Components
import 'package:vango_parent_app/viewmodels/attendance_viewmodel.dart';
import 'package:vango_parent_app/screens/Attendance/widgets/attendance_components.dart';

class AttendanceScreen extends StatefulWidget {
  final ChildProfile? child;
  const AttendanceScreen({super.key, this.child});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final AttendanceViewModel _viewModel;

  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    _viewModel = AttendanceViewModel();
    _viewModel.init(widget.child);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _handleUpdateResult(
    AttendanceUpdateResult result, [
    String? successMessage,
  ]) {
    if (result.success) {
      _showSuccessAnimation(successMessage ?? result.message);
      _selectedDays.clear();
    } else if (result.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved offline. Will sync when internet is restored.'),
          backgroundColor: AppColors.warning,
        ),
      );
      _selectedDays.clear();
    } else if (result.isDeadlinePassed) {
      _showCallDriverDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showCallDriverDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor = Theme.of(ctx).textTheme.bodyLarge?.color;
        final secondaryTextColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary;

        return AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Theme.of(ctx).dividerColor),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock_clock, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                "Deadline Passed",
                style: AppTypography.title.copyWith(color: textColor),
              ),
            ],
          ),
          content: Text(
            "Attendance changes are allowed until 9 PM the previous day to ensure driver routing stability.\n\nFor urgent last-minute changes, please contact the driver directly.",
            style: AppTypography.body.copyWith(
              height: 1.5,
              color: secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final phone = await ParentDataService.instance
                    .getDriverPhoneForChild(_viewModel.selectedChild!.id);
                if (phone != null && phone.isNotEmpty) {
                  final Uri launchUri = Uri(scheme: 'tel', path: phone);
                  await launchUrl(launchUri);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Driver phone number not found.'),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.call, color: Colors.white),
              label: const Text(
                "Call Driver",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessAnimation(String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'Success!',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  void _quickMarkNextWeek(AttendanceState state) async {
    HapticFeedback.selectionClick();
    DateTime nextMonday = DateTime.now();
    while (nextMonday.weekday != DateTime.monday) {
      nextMonday = nextMonday.add(const Duration(days: 1));
    }

    List<DateTime> nextWeekDays = [];
    for (int i = 0; i < 5; i++) {
      DateTime d = nextMonday.add(Duration(days: i));
      String ds = DateFormat('yyyy-MM-dd').format(d);
      bool isHoliday =
          _viewModel.slHolidays.contains(ds) ||
          _viewModel.backupHolidays.containsKey(ds);
      if (!isHoliday) nextWeekDays.add(d);
    }

    if (nextWeekDays.isNotEmpty) {
      final result = await _viewModel.updateFutureDates(nextWeekDays, state);
      _handleUpdateResult(
        result,
        'Status updated for ${nextWeekDays.length} day(s).',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Next week is entirely school holidays!'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _showRecurringSetup() {
    int selectedWeekday = DateTime.monday;
    AttendanceState selectedState = AttendanceState.none;
    final List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor = Theme.of(ctx).textTheme.bodyLarge?.color;
        final secondaryTextColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Set Weekly Recurring",
                    style: AppTypography.headline.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Applies to the next 4 weeks (max 30 days limit). Automatically skips holidays.",
                    style: AppTypography.body.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Select Day",
                    style: AppTypography.title.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(5, (index) {
                      int dayInt = index + 1;
                      bool isSelected = selectedWeekday == dayInt;
                      return ChoiceChip(
                        label: Text(weekdays[index]),
                        selected: isSelected,
                        selectedColor: AppColors.accent.withValues(alpha: 0.2),
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceStrong
                            : AppColors.surfaceStrong,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.transparent,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.accent : textColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (val) =>
                            setModalState(() => selectedWeekday = dayInt),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    "Set Status",
                    style: AppTypography.title.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      RadioListTile<AttendanceState>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Morning Only',
                          style: TextStyle(color: textColor),
                        ),
                        value: AttendanceState.morning,
                        groupValue: selectedState,
                        activeColor: AppColors.accent,
                        onChanged: (val) =>
                            setModalState(() => selectedState = val!),
                      ),
                      RadioListTile<AttendanceState>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Afternoon Only',
                          style: TextStyle(color: textColor),
                        ),
                        value: AttendanceState.afternoon,
                        groupValue: selectedState,
                        activeColor: AppColors.accent,
                        onChanged: (val) =>
                            setModalState(() => selectedState = val!),
                      ),
                      RadioListTile<AttendanceState>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Not Going',
                          style: TextStyle(color: textColor),
                        ),
                        value: AttendanceState.none,
                        groupValue: selectedState,
                        activeColor: AppColors.accent,
                        onChanged: (val) =>
                            setModalState(() => selectedState = val!),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Apply to Next 4 Weeks',
                    expanded: true,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      List<DateTime> generatedDates = [];
                      DateTime current = DateTime.now().add(
                        const Duration(days: 1),
                      );

                      while (generatedDates.length < 4) {
                        if (current.weekday == selectedWeekday) {
                          String ds = DateFormat('yyyy-MM-dd').format(current);
                          bool isHoliday =
                              _viewModel.slHolidays.contains(ds) ||
                              _viewModel.backupHolidays.containsKey(ds);
                          if (!isHoliday) generatedDates.add(current);
                        }
                        current = current.add(const Duration(days: 1));
                      }

                      final result = await _viewModel.updateFutureDates(
                        generatedDates,
                        selectedState,
                      );
                      _handleUpdateResult(
                        result,
                        'Status updated for ${generatedDates.length} day(s).',
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBulkMarkingDialog() {
    if (_selectedDays.isEmpty) return;
    HapticFeedback.selectionClick();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool canMarkPending = _selectedDays.every(
      (d) => d.difference(today).inDays >= 7,
    );

    AttendanceState selectedOption = AttendanceState.none;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor = Theme.of(ctx).textTheme.bodyLarge?.color;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(ctx).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Theme.of(ctx).dividerColor),
              ),
              title: Text(
                "Set Attendance",
                style: AppTypography.title.copyWith(color: textColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select status for the ${_selectedDays.length} selected day(s):",
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 16),
                    _buildRadioTile(
                      "Morning Ride Only",
                      AttendanceState.morning,
                      selectedOption,
                      (val) => setModalState(() => selectedOption = val!),
                      isDark,
                    ),
                    _buildRadioTile(
                      "Afternoon Ride Only",
                      AttendanceState.afternoon,
                      selectedOption,
                      (val) => setModalState(() => selectedOption = val!),
                      isDark,
                    ),
                    _buildRadioTile(
                      "Not Going",
                      AttendanceState.none,
                      selectedOption,
                      (val) => setModalState(() => selectedOption = val!),
                      isDark,
                    ),
                    if (canMarkPending)
                      _buildRadioTile(
                        "Pending",
                        AttendanceState.pending,
                        selectedOption,
                        (val) => setModalState(() => selectedOption = val!),
                        isDark,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final dates = _selectedDays.toList();
                    final result = await _viewModel.updateFutureDates(
                      dates,
                      selectedOption,
                    );
                    _handleUpdateResult(
                      result,
                      'Status updated for ${dates.length} day(s).',
                    );
                  },
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRadioTile(
    String title,
    AttendanceState value,
    AttendanceState groupValue,
    ValueChanged<AttendanceState?> onChanged,
    bool isDark,
  ) {
    final isSelected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.accent
              : (isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: RadioListTile<AttendanceState>(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.accent : null,
            fontSize: 14,
          ),
        ),
        value: value,
        groupValue: groupValue,
        activeColor: AppColors.accent,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildCalendarCell(
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    String dateStr = DateFormat('yyyy-MM-dd').format(day);
    bool isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    bool isHoliday =
        _viewModel.slHolidays.contains(dateStr) ||
        _viewModel.backupHolidays.containsKey(dateStr);

    AttendanceState? state = _viewModel.allPlans[dateStr]?['state'];
    if (state == null && !isWeekend && !isHoliday) state = AttendanceState.both;

    Color bgColor = Colors.transparent;
    Color textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;

    if (state == AttendanceState.both) {
      bgColor = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
    } else if (state == AttendanceState.none) {
      bgColor = AppColors.danger.withValues(alpha: 0.15);
      textColor = AppColors.danger;
    } else if (state == AttendanceState.morning) {
      bgColor = Colors.teal.withValues(alpha: 0.15);
      textColor = Colors.teal;
    } else if (state == AttendanceState.afternoon) {
      bgColor = Colors.deepPurple.withValues(alpha: 0.15);
      textColor = Colors.deepPurple;
    } else if (state == AttendanceState.pending) {
      bgColor = AppColors.warning.withValues(alpha: 0.2);
      textColor = AppColors.warning;
    }

    if (isWeekend || isHoliday) {
      bgColor = Theme.of(context).dividerColor.withValues(alpha: 0.2);
      textColor = Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkTextSecondary
          : AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.accent, width: 2.5)
            : (isToday
                  ? Border.all(color: AppColors.accentLow, width: 2)
                  : null),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isToday || isSelected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.body.copyWith(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Attendance',
          style: AppTypography.title.copyWith(color: textColor),
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.selectedChild == null) {
            return const AttendanceSkeletonWidget();
          }

          if (_viewModel.linkedChildren.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceStrong
                            : AppColors.accentLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bus_filled_outlined,
                        size: 64,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Driver Linked',
                      style: AppTypography.headline.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To manage daily and future attendance, you must first assign a driver to your child.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              ChildSelectorWidget(
                linkedChildren: _viewModel.linkedChildren,
                selectedChild: _viewModel.selectedChild,
                onChildSelected: _viewModel.switchChild,
              ),
              Expanded(
                child: _viewModel.isLoading && _viewModel.allPlans.isEmpty
                    ? const AttendanceSkeletonWidget()
                    : RefreshIndicator(
                        onRefresh: _viewModel.refresh,
                        color: AppColors.accent,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Ride",
                                style: AppTypography.title.copyWith(
                                  fontSize: 18,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),

                              TodayRideWidget(
                                selectedChild: _viewModel.selectedChild!,
                                isTogglingToday: _viewModel.isTogglingToday,
                                onUpdateRide: (isMorning, isAfternoon) async {
                                  final result = await _viewModel
                                      .updateTodayRide(
                                        isMorning: isMorning,
                                        isAfternoon: isAfternoon,
                                      );
                                  _handleUpdateResult(result);
                                },
                              ),

                              const SizedBox(height: 32),
                              Text(
                                'Plan Calendar',
                                style: AppTypography.title.copyWith(
                                  fontSize: 18,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  boxShadow: [
                                    if (!isDark)
                                      BoxShadow(
                                        color: AppColors.textPrimary.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    TableCalendar(
                                      firstDay: DateTime.now().subtract(
                                        const Duration(days: 365),
                                      ),
                                      lastDay: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                      focusedDay: _focusedDay,
                                      calendarFormat: CalendarFormat.month,
                                      startingDayOfWeek:
                                          StartingDayOfWeek.monday,

                                      // 👇 THE FIX: THIS PREVENTS THE CALENDAR FROM EATING SCROLL GESTURES!
                                      availableGestures:
                                          AvailableGestures.horizontalSwipe,

                                      headerStyle: HeaderStyle(
                                        formatButtonVisible: false,
                                        titleCentered: true,
                                        titleTextStyle: AppTypography.title
                                            .copyWith(
                                              fontSize: 16,
                                              color: textColor,
                                            ),
                                        leftChevronIcon: Icon(
                                          Icons.chevron_left,
                                          color: textColor,
                                        ),
                                        rightChevronIcon: Icon(
                                          Icons.chevron_right,
                                          color: textColor,
                                        ),
                                      ),
                                      selectedDayPredicate: (day) =>
                                          _selectedDays.any(
                                            (d) => isSameDay(d, day),
                                          ),
                                      onDaySelected: (selectedDay, focusedDay) {
                                        setState(() {
                                          _focusedDay = focusedDay;
                                          final today = DateTime(
                                            DateTime.now().year,
                                            DateTime.now().month,
                                            DateTime.now().day,
                                          );
                                          final normalizedSelected = DateTime(
                                            selectedDay.year,
                                            selectedDay.month,
                                            selectedDay.day,
                                          );

                                          if (normalizedSelected.isBefore(
                                                today,
                                              ) ||
                                              isSameDay(
                                                normalizedSelected,
                                                today,
                                              )) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Past days and today cannot be selected here.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          if (_selectedDays.length >= 30 &&
                                              !_selectedDays.any(
                                                (d) =>
                                                    isSameDay(d, selectedDay),
                                              )) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Maximum 30 days allowed per update.',
                                                ),
                                                backgroundColor:
                                                    AppColors.warning,
                                              ),
                                            );
                                            return;
                                          }
                                          if (_selectedDays.any(
                                            (d) => isSameDay(d, selectedDay),
                                          )) {
                                            _selectedDays.removeWhere(
                                              (d) => isSameDay(d, selectedDay),
                                            );
                                          } else {
                                            _selectedDays.add(selectedDay);
                                          }
                                        });
                                      },
                                      calendarBuilders: CalendarBuilders(
                                        defaultBuilder:
                                            (context, day, focusedDay) =>
                                                _buildCalendarCell(day),
                                        todayBuilder:
                                            (context, day, focusedDay) =>
                                                _buildCalendarCell(
                                                  day,
                                                  isToday: true,
                                                ),
                                        selectedBuilder:
                                            (context, day, focusedDay) =>
                                                _buildCalendarCell(
                                                  day,
                                                  isSelected: true,
                                                ),
                                        outsideBuilder:
                                            (context, day, focusedDay) =>
                                                const SizedBox.shrink(),
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ),

                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        _buildLegendItem(
                                          AppColors.success,
                                          'Going (Default)',
                                        ),
                                        _buildLegendItem(
                                          Colors.teal,
                                          'Morning',
                                        ),
                                        _buildLegendItem(
                                          Colors.deepPurple,
                                          'Afternoon',
                                        ),
                                        _buildLegendItem(
                                          AppColors.danger,
                                          'None',
                                        ),
                                        _buildLegendItem(
                                          AppColors.warning,
                                          'Pending',
                                        ),
                                        _buildLegendItem(
                                          secondaryTextColor,
                                          'Holiday',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              if (_selectedDays.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: GradientButton(
                                    label:
                                        'Set Status for ${_selectedDays.length} Day(s)',
                                    onPressed: _showBulkMarkingDialog,
                                    expanded: true,
                                  ),
                                ),

                              if (_selectedDays.isEmpty) ...[
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _quickMarkNextWeek(
                                      AttendanceState.none,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: AppColors.danger.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Mark Next Week Absent',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _showRecurringSetup,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isDark
                                            ? AppColors.darkAccent
                                            : AppColors.accent,
                                      ),
                                      foregroundColor: isDark
                                          ? AppColors.darkAccent
                                          : AppColors.accent,
                                    ),
                                    child: const Text('Set Weekly Recurring'),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),
                              Text(
                                'Audit History',
                                style: AppTypography.title.copyWith(
                                  fontSize: 18,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              AttendanceHistoryWidget(
                                allPlans: _viewModel.allPlans,
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
