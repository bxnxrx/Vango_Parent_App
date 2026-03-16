import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

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

  final Map<String, dynamic> _allPlans = {};

  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDays = {};

  final Set<String> _slHolidays = {};
  final Map<String, String> _holidayNames = {};

  final Map<String, String> _backupHolidays = {
    '2025-01-13': 'Duruthu Full Moon Poya',
    '2025-01-14': 'Tamil Thai Pongal Day',
    '2025-02-04': 'Independence Day',
    '2025-02-12': 'Navam Full Moon Poya',
    '2025-02-26': 'Mahashivratri',
    '2025-03-13': 'Medin Full Moon Poya',
    '2025-03-31': 'Eid al-Fitr',
    '2025-04-12': 'Bak Full Moon Poya',
    '2025-04-13': 'Sinhala & Tamil New Year Eve',
    '2025-04-14': 'Sinhala & Tamil New Year',
    '2025-04-18': 'Good Friday',
    '2025-05-01': 'May Day',
    '2025-05-11': 'Vesak Full Moon Poya',
    '2025-05-12': 'Day following Vesak',
    '2025-06-07': 'Eid al-Adha',
    '2025-06-10': 'Poson Full Moon Poya',
    '2025-07-09': 'Esala Full Moon Poya',
    '2025-08-08': 'Nikini Full Moon Poya',
    '2025-09-06': 'Binara Full Moon Poya',
    '2025-10-06': 'Vap Full Moon Poya',
    '2025-11-04': 'Ill Full Moon Poya',
    '2025-12-04': 'Unduvap Full Moon Poya',
    '2025-12-25': 'Christmas Day',
  };

  @override
  void initState() {
    super.initState();
    _fetchLinkedChildren();
    _fetchSriLankanHolidays();
  }

  Future<void> _fetchSriLankanHolidays() async {
    try {
      final url = Uri.parse(
        'https://calendar.google.com/calendar/ical/en.lk%23holiday%40group.v.calendar.google.com/public/basic.ics',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        String? currentDate;
        String? currentSummary;

        for (var line in lines) {
          if (line.startsWith('BEGIN:VEVENT')) {
            currentDate = null;
            currentSummary = null;
          } else if (line.startsWith('DTSTART')) {
            final parts = line.split(':');
            if (parts.length > 1) {
              final dateRaw = parts[1].trim();
              if (dateRaw.length == 8) {
                currentDate =
                    '${dateRaw.substring(0, 4)}-${dateRaw.substring(4, 6)}-${dateRaw.substring(6, 8)}';
              }
            }
          } else if (line.startsWith('SUMMARY:')) {
            currentSummary = line.substring(8).trim();
          } else if (line.startsWith('END:VEVENT')) {
            if (currentDate != null && currentSummary != null) {
              _slHolidays.add(currentDate);
              _holidayNames[currentDate] = currentSummary;
            }
          }
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint(
        'Failed to fetch live SL holidays, falling back to local database.',
      );
    }
  }

  Future<void> _fetchLinkedChildren() async {
    setState(() => _isLoading = true);
    try {
      final childrenList = await _dataService.fetchChildren();
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
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          _allPlans.clear();
          _allPlans.addAll(plans);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    if (_selectedChild != null) {
      _dataService.clearAttendanceCache(_selectedChild!.id);
      await _fetchAttendanceData();
    }
  }

  void _switchChild(ChildProfile child) {
    if (_selectedChild?.id == child.id) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedChild = child;
      _allPlans.clear();
      _selectedDays.clear();
    });
    _fetchAttendanceData();
  }

  void _showCallDriverDialog(bool isToday) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_clock, color: AppColors.warning),
            const SizedBox(width: 8),
            Text("Deadline Passed", style: AppTypography.title),
          ],
        ),
        content: Text(
          "Attendance changes are allowed until 9 PM the previous day to ensure driver routing stability.\n\nFor urgent last-minute changes, please contact the driver directly.",
          style: AppTypography.body.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
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
              final phone = await _dataService.getDriverPhoneForChild(
                _selectedChild!.id,
              );
              if (phone != null && phone.isNotEmpty) {
                final Uri launchUri = Uri(scheme: 'tel', path: phone);
                await launchUrl(launchUri);
              } else {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Driver phone number not found.'),
                    ),
                  );
              }
            },
            icon: const Icon(Icons.call),
            label: const Text("Call Driver"),
          ),
        ],
      ),
    );
  }

  // --- 3️⃣ ENTERPRISE CONFIRMATION ANIMATION ---
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
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
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Auto dismiss after 1.8 seconds
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _toggleToday(bool isComing) async {
    if (_selectedChild == null) return;
    if (_isTogglingToday) return;

    HapticFeedback.selectionClick();
    setState(() => _isTogglingToday = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _dataService.updateAttendance(
        _selectedChild!.id,
        isComing ? AttendanceState.coming : AttendanceState.notComing,
      );
      if (mounted) {
        setState(() {
          _selectedChild = _selectedChild!.copyWith(
            attendance: isComing
                ? AttendanceState.coming
                : AttendanceState.notComing,
          );
          final index = _linkedChildren.indexWhere(
            (c) => c.id == _selectedChild!.id,
          );
          if (index != -1) _linkedChildren[index] = _selectedChild!;
          _isTogglingToday = false;
        });
        _showSuccessAnimation('Today\'s ride updated.');
      }
    } catch (e) {
      final errorStr = e.toString();
      if (mounted) {
        setState(() => _isTogglingToday = false);

        if (errorStr.contains('Saved offline')) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Saved offline. Will sync when internet is restored.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
          setState(() {
            _selectedChild = _selectedChild!.copyWith(
              attendance: isComing
                  ? AttendanceState.coming
                  : AttendanceState.notComing,
            );
          });
        } else if (errorStr.contains('Deadline passed') ||
            errorStr.contains('closed at 9 PM')) {
          _showCallDriverDialog(true);
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(errorStr.replaceAll('Exception: ', '')),
              backgroundColor: AppColors.danger,
            ),
          );
        }
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
          _allPlans[date] = {
            'state': newState,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          };
        }
        _selectedDays.clear();
        _isLoading = false;
      });

      if (mounted) {
        String msg = newState == AttendanceState.coming
            ? 'Going'
            : (newState == AttendanceState.pending ? 'Pending' : 'Not Going');
        _showSuccessAnimation('Marked $msg for ${dates.length} day(s).');
      }
    } catch (e) {
      final errorStr = e.toString();
      if (mounted) {
        setState(() => _isLoading = false);

        if (errorStr.contains('Saved offline')) {
          setState(() {
            for (var date in formattedDates) {
              _allPlans[date] = {
                'state': newState,
                'updated_at': DateTime.now().toIso8601String(),
              };
            }
            _selectedDays.clear();
          });
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Saved offline. Will sync when online.'),
              backgroundColor: AppColors.warning,
            ),
          );
        } else if (errorStr.contains('Deadline passed') ||
            errorStr.contains('closed at 9 PM')) {
          _showCallDriverDialog(false);
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(errorStr.replaceAll('Exception: ', '')),
              backgroundColor: AppColors.danger,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _updateFutureDates(dates, newState),
              ),
            ),
          );
        }
      }
    }
  }

  void _quickMarkNextWeek(bool isComing) {
    DateTime nextMonday = DateTime.now();
    while (nextMonday.weekday != DateTime.monday) {
      nextMonday = nextMonday.add(const Duration(days: 1));
    }

    List<DateTime> nextWeekDays = [];
    for (int i = 0; i < 5; i++) {
      DateTime d = nextMonday.add(Duration(days: i));
      String ds = DateFormat('yyyy-MM-dd').format(d);

      bool isHoliday =
          _slHolidays.contains(ds) || _backupHolidays.containsKey(ds);

      if (!isHoliday) {
        nextWeekDays.add(d);
      }
    }

    if (nextWeekDays.isNotEmpty) {
      _updateFutureDates(
        nextWeekDays,
        isComing ? AttendanceState.coming : AttendanceState.notComing,
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

  // --- 4️⃣ NEW: WEEKLY RECURRING LOGIC ---
  void _showRecurringSetup() {
    int selectedWeekday = DateTime.monday;
    AttendanceState selectedState = AttendanceState.notComing;

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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                  Text("Set Weekly Recurring", style: AppTypography.headline),
                  const SizedBox(height: 8),
                  Text(
                    "Applies to the next 4 weeks (max 30 days limit). Automatically skips holidays.",
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text("Select Day", style: AppTypography.title),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(5, (index) {
                      int dayInt = index + 1; // 1 = Monday, 5 = Friday
                      bool isSelected = selectedWeekday == dayInt;
                      return ChoiceChip(
                        label: Text(weekdays[index]),
                        selected: isSelected,
                        selectedColor: AppColors.accent.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textPrimary,
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
                  Text("Set Status", style: AppTypography.title),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<AttendanceState>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Not Going'),
                          value: AttendanceState.notComing,
                          groupValue: selectedState,
                          activeColor: AppColors.danger,
                          onChanged: (val) =>
                              setModalState(() => selectedState = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<AttendanceState>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Going'),
                          value: AttendanceState.coming,
                          groupValue: selectedState,
                          activeColor: AppColors.success,
                          onChanged: (val) =>
                              setModalState(() => selectedState = val!),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Apply to Next 4 Weeks',
                    expanded: true,
                    onPressed: () {
                      Navigator.pop(ctx);

                      // Calculate the next 4 occurrences of that weekday
                      List<DateTime> generatedDates = [];
                      DateTime current = DateTime.now().add(
                        const Duration(days: 1),
                      ); // Start from tomorrow

                      while (generatedDates.length < 4) {
                        if (current.weekday == selectedWeekday) {
                          String ds = DateFormat('yyyy-MM-dd').format(current);
                          bool isHoliday =
                              _slHolidays.contains(ds) ||
                              _backupHolidays.containsKey(ds);

                          if (!isHoliday) {
                            generatedDates.add(current);
                          }
                        }
                        current = current.add(const Duration(days: 1));
                      }

                      _updateFutureDates(generatedDates, selectedState);
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

  void _showBulkMarkingDialog(BuildContext context, List<DateTime> dates) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool canMarkPending = dates.every((d) => d.difference(today).inDays >= 7);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Set Attendance", style: AppTypography.title),
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
                  "Coming (Green)",
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
                  "Not Coming (Red)",
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
                      ? "Pending (Yellow)"
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

  Widget _buildCalendarCell(
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    String dateStr = DateFormat('yyyy-MM-dd').format(day);
    bool isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    bool isHoliday =
        _slHolidays.contains(dateStr) || _backupHolidays.containsKey(dateStr);
    String holidayName =
        (_holidayNames[dateStr] ?? _backupHolidays[dateStr] ?? '')
            .toLowerCase();
    bool isPoya = isHoliday && holidayName.contains('poya');

    AttendanceState? state = _allPlans[dateStr]?['state'];

    if (state == null && !isWeekend && !isHoliday) {
      state = AttendanceState.coming;
    }

    Color bgColor = Colors.transparent;
    Color textColor = AppColors.textPrimary;
    Widget? icon;

    if (state == AttendanceState.coming) {
      bgColor = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
    } else if (state == AttendanceState.notComing) {
      bgColor = AppColors.danger.withValues(alpha: 0.15);
      textColor = AppColors.danger;
    } else if (state == AttendanceState.pending) {
      bgColor = AppColors.warning.withValues(alpha: 0.2);
      textColor = AppColors.warning;
    }

    if (isWeekend || isHoliday) {
      bgColor = AppColors.stroke.withValues(alpha: 0.2);
      textColor = AppColors.textSecondary;
      if (isPoya) {
        icon = const Icon(
          Icons.brightness_3,
          size: 10,
          color: AppColors.warning,
        );
      } else if (isHoliday) {
        icon = const Icon(
          Icons.celebration,
          size: 10,
          color: AppColors.warning,
        );
      }
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isToday || isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            if (icon != null)
              Padding(padding: const EdgeInsets.only(top: 2), child: icon),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {IconData? icon}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
          child: icon != null ? Icon(icon, size: 10, color: color) : null,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.body.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _selectedChild == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: _AttendanceSkeleton(),
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
            child: _isLoading && _allPlans.isEmpty
                ? const _AttendanceSkeleton()
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
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
                            style: AppTypography.title.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 12),
                          _buildTodayCard(),

                          const SizedBox(height: 32),
                          Text(
                            'Plan Calendar',
                            style: AppTypography.title.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.stroke),
                              boxShadow: [
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
                                  startingDayOfWeek: StartingDayOfWeek.monday,
                                  headerStyle: HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                    titleTextStyle: AppTypography.title
                                        .copyWith(fontSize: 16),
                                  ),
                                  selectedDayPredicate: (day) => _selectedDays
                                      .any((d) => isSameDay(d, day)),
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

                                      if (normalizedSelected.isBefore(today) ||
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
                                            (d) => isSameDay(d, selectedDay),
                                          )) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Maximum 30 days allowed per update.',
                                            ),
                                            backgroundColor: AppColors.warning,
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
                                    todayBuilder: (context, day, focusedDay) =>
                                        _buildCalendarCell(day, isToday: true),
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

                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    color: AppColors.stroke,
                                  ),
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildLegendItem(
                                      AppColors.success,
                                      'Coming',
                                    ),
                                    _buildLegendItem(
                                      AppColors.danger,
                                      'Not Coming',
                                    ),
                                    _buildLegendItem(
                                      AppColors.warning,
                                      'Pending',
                                    ),
                                    _buildLegendItem(
                                      AppColors.textSecondary,
                                      'Holiday',
                                      icon: Icons.brightness_3,
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
                                onPressed: () => _showBulkMarkingDialog(
                                  context,
                                  _selectedDays.toList(),
                                ),
                                expanded: true,
                              ),
                            ),

                          // 🔮 WEEKLY RECURRING & QUICK ACTIONS
                          if (_selectedDays.isEmpty) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _quickMarkNextWeek(true),
                                    icon: const Icon(
                                      Icons.event_available,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                    label: const Text(
                                      'Next Week Going',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _quickMarkNextWeek(false),
                                    icon: const Icon(
                                      Icons.event_busy,
                                      size: 16,
                                      color: AppColors.danger,
                                    ),
                                    label: const Text(
                                      'Next Week Absent',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showRecurringSetup,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.accent,
                                  ),
                                  foregroundColor: AppColors.accent,
                                ),
                                icon: const Icon(Icons.repeat),
                                label: const Text(
                                  'Set Weekly Recurring (e.g. Every Monday)',
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                          Text(
                            'Audit History',
                            style: AppTypography.title.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 12),
                          _buildHistoryList(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    if (_linkedChildren.length <= 1) return const SizedBox.shrink();

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
    ImageProvider? currentAvatar;
    if (_selectedChild!.imageUrl != null &&
        _selectedChild!.imageUrl!.isNotEmpty) {
      currentAvatar = CachedNetworkImageProvider(_selectedChild!.imageUrl!);
    }

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
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _selectedChild!.avatarColor.withValues(
                    alpha: 0.2,
                  ),
                  backgroundImage: currentAvatar,
                  child: currentAvatar == null
                      ? Text(
                          _selectedChild!.name[0].toUpperCase(),
                          style: TextStyle(
                            color: _selectedChild!.avatarColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedChild!.attendance == AttendanceState.coming
                            ? 'Going to School'
                            : 'Not Going Today',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              _selectedChild!.attendance ==
                                  AttendanceState.coming
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attendance changes allowed until 9 PM previous day',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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

  Widget _buildHistoryList() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final pastKeys =
        _allPlans.keys.where((k) => k.compareTo(todayStr) < 0).toList()
          ..sort((a, b) => b.compareTo(a));

    if (pastKeys.isEmpty) {
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
              'No history records found.',
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pastKeys.length,
      itemBuilder: (context, index) {
        String dateStr = pastKeys[index];
        final record = _allPlans[dateStr];
        AttendanceState state = record['state'];
        DateTime dateObj = DateTime.parse(dateStr);

        String timeAgo = '';
        if (record['updated_at'] != null) {
          DateTime updatedObj = DateTime.parse(record['updated_at']).toLocal();
          timeAgo = ' • Updated at ${DateFormat('h:mm a').format(updatedObj)}';
        }

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
                    const SizedBox(height: 2),
                    Text(
                      (state == AttendanceState.coming
                              ? 'Marked Going'
                              : (state == AttendanceState.notComing
                                    ? 'Marked Not Going'
                                    : 'Marked Pending')) +
                          timeAgo,
                      style: AppTypography.body.copyWith(
                        fontSize: 12,
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

class _AttendanceSkeleton extends StatelessWidget {
  const _AttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.stroke.withValues(alpha: 0.5),
      highlightColor: AppColors.surfaceStrong,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 20, width: 120, color: Colors.white),
            const SizedBox(height: 12),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 32),
            Container(height: 20, width: 120, color: Colors.white),
            const SizedBox(height: 12),
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
