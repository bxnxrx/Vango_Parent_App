import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/models/message_thread.dart';
import 'package:vango_parent_app/models/notification_item.dart';
import 'package:vango_parent_app/services/backend_client.dart';

class ParentDataService {
  ParentDataService._();

  static final ParentDataService instance = ParentDataService._();

  final BackendClient _backend = BackendClient.instance;

  Future<List<ChildProfile>> fetchChildren() async {
    final response = await _backend.get('/api/parents/children');
    return _mapList(response, ChildProfile.fromJson);
  }

  Future<ChildProfile> createChild({
    required String childName,
    required String school,
    required String pickupLocation,
    required String pickupTime,
  }) async {
    final response = await _backend.post('/api/parents/children', {
      'childName': childName,
      'school': school,
      'pickupLocation': pickupLocation,
      'pickupTime': pickupTime,
    }) as Map<String, dynamic>;
    return ChildProfile.fromJson(response);
  }

  Future<void> updateAttendance(String childId, AttendanceState state) async {
    await _backend.patch('/api/parents/children/$childId/attendance', {
      'attendanceState': state.apiValue,
    });
  }

  Future<List<NotificationItem>> fetchNotifications() async {
    final response = await _backend.get('/api/parents/notifications');
    return _mapList(response, NotificationItem.fromJson);
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _backend.patch('/api/parents/notifications/$notificationId/read', {});
  }

  Future<List<DriverProfile>> fetchFinderServices({String? vehicleType, String? sortBy}) async {
    final query = <String, String>{};
    if (vehicleType != null && vehicleType.isNotEmpty && vehicleType != 'All') {
      query['vehicleType'] = vehicleType;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      query['sortBy'] = sortBy;
    }

    final response = await _backend.get('/api/parents/finder/services', queryParameters: query.isEmpty ? null : query);
    return _mapList(response, DriverProfile.fromJson);
  }

  Future<List<MessageThread>> fetchThreads() async {
    final response = await _backend.get('/api/parents/messages/threads');
    return _mapList(response, MessageThread.fromJson);
  }

  Future<List<Message>> fetchMessages(String threadId) async {
    final response = await _backend.get('/api/parents/messages/$threadId');
    return _mapList(response, Message.fromJson);
  }

  Future<Message> sendMessage(String threadId, String body) async {
    final response = await _backend.post('/api/parents/messages/$threadId', {'body': body}) as Map<String, dynamic>;
    return Message.fromJson(response);
  }

  List<T> _mapList<T>(dynamic payload, T Function(Map<String, dynamic>) mapper) {
    if (payload is List) {
      return payload.map((item) => mapper(item as Map<String, dynamic>)).toList();
    }
    return <T>[];
  }
}
