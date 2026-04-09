import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';

// A helper class to cleanly pass results back to the UI without UI dependencies
class AttendanceUpdateResult {
  final bool success;
  final String message;
  final bool isOffline;
  final bool isDeadlinePassed;

  AttendanceUpdateResult({
    required this.success,
    this.message = '',
    this.isOffline = false,
    this.isDeadlinePassed = false,
  });
}

class AttendanceViewModel extends ChangeNotifier {
  final ParentDataService _dataService = ParentDataService.instance;

  List<ChildProfile> linkedChildren = [];
  ChildProfile? selectedChild;

  bool isLoading = true;
  bool isTogglingToday = false;

  final Map<String, dynamic> allPlans = {};

  final Set<String> slHolidays = {};
  final Map<String, String> holidayNames = {};
  final Map<String, String> backupHolidays = {
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
    '2025-12-25': 'Christmas Day',
  };

  Future<void> init(ChildProfile? initialChild) async {
    _fetchSriLankanHolidays();
    await fetchLinkedChildren(initialChild);
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
              slHolidays.add(currentDate);
              holidayNames[currentDate] = currentSummary;
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        'Failed to fetch live SL holidays, falling back to local database.',
      );
    }
  }

  Future<void> fetchLinkedChildren(ChildProfile? initialChild) async {
    isLoading = true;
    notifyListeners();
    try {
      final childrenList = await _dataService.fetchChildren();
      linkedChildren = childrenList
          .where(
            (c) => c.linkedDriverId != null && c.linkedDriverId!.isNotEmpty,
          )
          .toList();

      if (linkedChildren.isNotEmpty) {
        if (initialChild != null &&
            linkedChildren.any((c) => c.id == initialChild.id)) {
          selectedChild = linkedChildren.firstWhere(
            (c) => c.id == initialChild.id,
          );
        } else {
          selectedChild = linkedChildren.first;
        }
        await fetchAttendanceData();
      } else {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendanceData() async {
    if (selectedChild == null) return;
    isLoading = true;
    notifyListeners();
    try {
      final plans = await _dataService.fetchFutureAttendance(selectedChild!.id);
      allPlans.clear();
      allPlans.addAll(plans);
    } catch (e) {
      debugPrint("Failed to fetch attendance plans: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (selectedChild != null) {
      _dataService.clearAttendanceCache(selectedChild!.id);
      await fetchAttendanceData();
    }
  }

  void switchChild(ChildProfile child) {
    if (selectedChild?.id == child.id) return;
    selectedChild = child;
    allPlans.clear();
    notifyListeners();
    fetchAttendanceData();
  }

  Future<AttendanceUpdateResult> updateTodayRide({
    required bool isMorning,
    required bool isAfternoon,
  }) async {
    if (selectedChild == null || isTogglingToday)
      return AttendanceUpdateResult(success: false);

    isTogglingToday = true;
    notifyListeners();

    AttendanceState newState;
    if (isMorning && isAfternoon) {
      newState = AttendanceState.both;
    } else if (isMorning) {
      newState = AttendanceState.morning;
    } else if (isAfternoon) {
      newState = AttendanceState.afternoon;
    } else {
      newState = AttendanceState.none;
    }

    try {
      await _dataService.updateAttendance(selectedChild!.id, newState);
      selectedChild = selectedChild!.copyWith(attendance: newState);
      final index = linkedChildren.indexWhere((c) => c.id == selectedChild!.id);
      if (index != -1) linkedChildren[index] = selectedChild!;

      isTogglingToday = false;
      notifyListeners();
      return AttendanceUpdateResult(
        success: true,
        message: 'Today\'s ride updated.',
      );
    } catch (e) {
      isTogglingToday = false;
      final errorStr = e.toString();

      if (errorStr.contains('Saved offline')) {
        selectedChild = selectedChild!.copyWith(attendance: newState);
        notifyListeners();
        return AttendanceUpdateResult(success: false, isOffline: true);
      } else if (errorStr.contains('Deadline passed') ||
          errorStr.contains('closed at 9 PM')) {
        notifyListeners();
        return AttendanceUpdateResult(success: false, isDeadlinePassed: true);
      } else {
        notifyListeners();
        return AttendanceUpdateResult(
          success: false,
          message: errorStr.replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<AttendanceUpdateResult> updateFutureDates(
    List<DateTime> dates,
    AttendanceState newState,
  ) async {
    if (selectedChild == null) return AttendanceUpdateResult(success: false);

    isLoading = true;
    notifyListeners();

    final formattedDates = dates
        .map((d) => DateFormat('yyyy-MM-dd').format(d))
        .toList();

    try {
      await _dataService.updateFutureAttendance(
        selectedChild!.id,
        formattedDates,
        newState,
      );

      for (var date in formattedDates) {
        allPlans[date] = {
          'state': newState,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
      }
      isLoading = false;
      notifyListeners();
      return AttendanceUpdateResult(success: true);
    } catch (e) {
      isLoading = false;
      final errorStr = e.toString();

      if (errorStr.contains('Saved offline')) {
        for (var date in formattedDates) {
          allPlans[date] = {
            'state': newState,
            'updated_at': DateTime.now().toIso8601String(),
          };
        }
        notifyListeners();
        return AttendanceUpdateResult(success: false, isOffline: true);
      } else if (errorStr.contains('Deadline passed') ||
          errorStr.contains('closed at 9 PM')) {
        notifyListeners();
        return AttendanceUpdateResult(success: false, isDeadlinePassed: true);
      } else {
        notifyListeners();
        return AttendanceUpdateResult(
          success: false,
          message: errorStr.replaceAll('Exception: ', ''),
        );
      }
    }
  }
}
