import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/models/message_thread.dart';
import 'package:vango_parent_app/models/notification_item.dart';
import 'package:vango_parent_app/models/payment_record.dart';
import 'package:vango_parent_app/services/backend_client.dart';

class ParentDataService {
  ParentDataService._();

  static final ParentDataService instance = ParentDataService._();

  final BackendClient _backend = BackendClient.instance;
  static const String _defaultPickupTime = '06:45 AM';

  Future<List<ChildProfile>> fetchChildren() async {
    final response = await _backend.get('/api/parents/children');
    return _mapList(response, ChildProfile.fromJson);
  }

  Future<ChildProfile> createChild({
    required String childName,
    required String school,
    required String pickupLocation,
    String? pickupTime,
  }) async {
    final payload = _buildChildPayload(
      childName: childName,
      school: school,
      pickupLocation: pickupLocation,
      pickupTime: pickupTime,
    );
    final response = _expectMap(await _backend.post('/api/parents/children', payload));
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

  Future<List<PaymentRecord>> fetchPayments() async {
    final response = await _backend.get('/api/parents/payments');
    return _mapList(response, PaymentRecord.fromJson);
  }

  List<T> _mapList<T>(dynamic payload, T Function(Map<String, dynamic>) mapper) {
    if (payload is List) {
      return payload.map((item) => mapper(item as Map<String, dynamic>)).toList();
    }
    return <T>[];
  }

  Map<String, dynamic> _buildChildPayload({
    required String childName,
    required String school,
    required String pickupLocation,
    String? pickupTime,
  }) {
    final normalizedTime = (pickupTime ?? '').trim().isEmpty ? _defaultPickupTime : pickupTime!.trim();
    return {
      'childName': childName.trim(),
      'school': school.trim(),
      'pickupLocation': pickupLocation.trim(),
      'pickupTime': normalizedTime,
    };
  }

  Map<String, dynamic> _expectMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw StateError('Unexpected backend payload: ${payload.runtimeType}');
  }
}
