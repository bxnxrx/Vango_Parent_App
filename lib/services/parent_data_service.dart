import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Fetches the parent's profile data (including full_name)
  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _backend.get('/api/parents/profile');
    return _expectMap(response);
  }

  Future<List<ChildProfile>> fetchChildren() async {
    final response = await _backend.get('/api/parents/children');

    final List<dynamic> data = response is List
        ? response
        : (response['data'] ?? []);
    final List<ChildProfile> children = data
        .map((json) => ChildProfile.fromJson(json))
        .toList();

    await Future.wait(
      children.map((child) async {
        if (child.imageUrl != null &&
            child.imageUrl!.isNotEmpty &&
            !child.imageUrl!.startsWith('http')) {
          try {
            final signedUrl = await Supabase.instance.client.storage
                .from('child-photos')
                .createSignedUrl(child.imageUrl!, 60 * 60 * 24 * 7);

            final index = children.indexOf(child);
            if (index != -1) {
              children[index] = child.copyWith(imageUrl: signedUrl);
            }
          } catch (e) {
            debugPrint('Failed to sign url: $e');
          }
        }
      }),
    );

    return children;
  }

  Future<String?> uploadChildPhoto(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception("Image file does not exist on device.");
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("User not authenticated.");
      }

      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$userId/$fileName';

      await Supabase.instance.client.storage
          .from('child-photos')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      return path;
    } on StorageException catch (e) {
      throw Exception('Storage Error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  Future<ChildProfile> createChild({
    required String childName,
    int? age,
    required String school,
    required String pickupLocation,
    double? pickupLat,
    double? pickupLng,
    required String dropLocation,
    double? dropLat,
    double? dropLng,
    required String inviteCode,
    String? pickupTime,
    String? etaSchool,
    required String emergencyContact,
    String? description,
    String? imageUrl,
  }) async {
    final payload = _buildChildPayload(
      childName: childName,
      age: age,
      school: school,
      pickupLocation: pickupLocation,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLocation: dropLocation,
      dropLat: dropLat,
      dropLng: dropLng,
      pickupTime: pickupTime,
      etaSchool: etaSchool,
      emergencyContact: emergencyContact,
      description: description,
      inviteCode: inviteCode,
      imageUrl: imageUrl,
    );
    final response = _expectMap(
      await _backend.post('/api/parents/children', payload),
    );
    return ChildProfile.fromJson(response);
  }

  Future<ChildProfile> updateChild({
    required String childId,
    required String childName,
    int? age,
    required String school,
    required String pickupLocation,
    double? pickupLat,
    double? pickupLng,
    required String dropLocation,
    double? dropLat,
    double? dropLng,
    required String inviteCode,
    String? pickupTime,
    String? etaSchool,
    required String emergencyContact,
    String? description,
    String? imageUrl,
  }) async {
    final payload = _buildChildPayload(
      childName: childName,
      age: age,
      school: school,
      pickupLocation: pickupLocation,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLocation: dropLocation,
      dropLat: dropLat,
      dropLng: dropLng,
      pickupTime: pickupTime,
      etaSchool: etaSchool,
      emergencyContact: emergencyContact,
      description: description,
      inviteCode: inviteCode,
      imageUrl: imageUrl,
    );
    final response = _expectMap(
      await _backend.put('/api/parents/children/$childId', payload),
    );
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

  Future<List<DriverProfile>> fetchFinderServices({
    String? vehicleType,
    String? sortBy,
  }) async {
    final query = <String, String>{};
    if (vehicleType != null && vehicleType.isNotEmpty && vehicleType != 'All') {
      query['vehicleType'] = vehicleType;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      query['sortBy'] = sortBy;
    }

    final response = await _backend.get(
      '/api/parents/finder/services',
      queryParameters: query.isEmpty ? null : query,
    );
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
    final response =
        await _backend.post('/api/parents/messages/$threadId', {'body': body})
            as Map<String, dynamic>;
    return Message.fromJson(response);
  }

  Future<List<PaymentRecord>> fetchPayments() async {
    final response = await _backend.get('/api/parents/payments');
    return _mapList(response, PaymentRecord.fromJson);
  }

  Future<bool> hasLinkedDriver() async {
    final response = await _backend.get('/api/parents/link-status');
    final linked = response is Map<String, dynamic> ? response['linked'] : null;
    return linked is bool ? linked : false;
  }

  Future<List<DriverProfile>> fetchFinderServicesDetailed({
    String? vehicleType,
    String? sortBy,
  }) async {
    final query = <String, String>{};
    if (vehicleType != null && vehicleType.isNotEmpty && vehicleType != 'All') {
      query['vehicleType'] = vehicleType;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      query['sortBy'] = sortBy;
    }

    final response = await _backend.get(
      '/api/parents/finder/services/detailed',
      queryParameters: query.isEmpty ? null : query,
    );
    return _mapList(response, DriverProfile.fromJson);
  }

  Future<void> submitDriverReport({
    required String driverId,
    required String reason,
  }) async {
    await _backend.post('/api/parents/drivers/$driverId/report', {
      'reason': reason,
    });
  }

  Future<Map<String, dynamic>> createBookingRequest({
    required String vehicleId,
    required List<String> childIds,
    String? note,
  }) async {
    final response = await _backend.post('/api/parents/booking-requests', {
      'vehicleId': vehicleId,
      'childIds': childIds,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return _expectMap(response);
  }

  List<T> _mapList<T>(
    dynamic payload,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (payload is List) {
      return payload
          .map((item) => mapper(item as Map<String, dynamic>))
          .toList();
    }
    return <T>[];
  }

  Map<String, dynamic> _buildChildPayload({
    required String childName,
    int? age,
    required String school,
    required String pickupLocation,
    double? pickupLat,
    double? pickupLng,
    required String dropLocation,
    double? dropLat,
    double? dropLng,
    required String inviteCode,
    String? pickupTime,
    String? etaSchool,
    required String emergencyContact,
    String? description,
    String? imageUrl,
  }) {
    final normalizedTime = (pickupTime ?? '').trim().isEmpty
        ? _defaultPickupTime
        : pickupTime!.trim();
    return {
      'childName': childName.trim(),
      if (age != null) 'age': age,
      'school': school.trim(),
      'pickupLocation': pickupLocation.trim(),
      if (pickupLat != null) 'pickupLat': pickupLat,
      if (pickupLng != null) 'pickupLng': pickupLng,
      'dropLocation': dropLocation.trim(),
      if (dropLat != null) 'dropLat': dropLat,
      if (dropLng != null) 'dropLng': dropLng,
      'pickupTime': normalizedTime,
      if (etaSchool != null) 'etaSchool': etaSchool.trim(),
      'emergencyContact': emergencyContact.trim(),
      if (description != null) 'description': description.trim(),
      'inviteCode': inviteCode.trim(),
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  Map<String, dynamic> _expectMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw StateError('Unexpected backend payload: ${payload.runtimeType}');
  }

  Future<void> deleteChild(String childId) async {
    await _backend.delete('/api/parents/children/$childId');
  }

  Future<Map<String, dynamic>> verifyInviteCode(String code) async {
    final response = await _backend.get('/api/parents/verify-invite/$code');
    return _expectMap(response);
  }

  Future<void> updateFutureAttendance(
    String childId,
    List<String> dates,
    AttendanceState status,
  ) async {
    await _backend.post(
      '/api/parents/children/$childId/attendance-exceptions',
      {'dates': dates, 'status': status.apiValue},
    );
  }

  Future<Map<String, AttendanceState>> fetchFutureAttendance(
    String childId,
  ) async {
    final response = await _backend.get(
      '/api/parents/children/$childId/attendance-exceptions',
    );

    final Map<String, AttendanceState> plans = {};
    if (response is List) {
      for (var item in response) {
        plans[item['exception_date']] = AttendanceStateApi.fromString(
          item['status'],
        );
      }
    }
    return plans;
  }
}
