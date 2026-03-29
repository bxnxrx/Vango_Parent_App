import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/utils/app_auth_exception.dart'; // ✅ Added Exception Import

class ChildrenRepository {
  final ParentDataService _dataService = ParentDataService.instance;
  final _supabase = Supabase.instance.client;

  Future<List<ChildProfile>> fetchChildren({
    int page = 1,
    int limit = 10,
  }) async {
    // ✅ Passes pagination params natively to the data service
    return await _dataService.fetchChildren(page: page, limit: limit);
  }

  Future<void> deleteChild(String id) async {
    await _dataService.deleteChild(id);
  }

  Future<DriverProfile?> verifyInviteCode(String code) async {
    final data = await _dataService.verifyInviteCode(code);
    if (data['valid'] == true) {
      return DriverProfile.fromJson(data);
    }
    return null;
  }

  // ✅ Consistent Error Handling: Throws AppAuthException
  Future<void> sendEmergencyContactOtp(String phone) async {
    try {
      final response = await _supabase.functions.invoke(
        'auth-otp',
        body: {'action': 'send', 'phone': phone},
      );
      if (response.status != 200) {
        throw AppAuthException(
          code: 'OTP_SEND_FAILED',
          message: 'Backend failed to send OTP.',
        );
      }
    } catch (e) {
      throw AppAuthException(code: 'OTP_SEND_FAILED', message: e.toString());
    }
  }

  // ✅ Consistent Error Handling: Throws AppAuthException
  Future<void> verifyEmergencyContactOtp(String phone, String code) async {
    try {
      final response = await _supabase.functions.invoke(
        'auth-otp',
        body: {'action': 'verify', 'phone': phone, 'code': code},
      );
      if (response.status != 200 || response.data['verified'] != true) {
        throw AppAuthException(
          code: 'OTP_VERIFY_FAILED',
          message: 'Invalid or expired OTP.',
        );
      }
    } catch (e) {
      throw AppAuthException(code: 'OTP_VERIFY_FAILED', message: e.toString());
    }
  }

  Future<String?> getSecureMapsKey() async {
    try {
      final response = await _supabase.functions.invoke('get-client-config');
      return response.data['MAPS_API_KEY'];
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> searchSchoolsProxied(String query) async {
    if (query.isEmpty) {
      return [];
    }
    try {
      final response = await _supabase.functions.invoke(
        'maps-proxy',
        body: {'endpoint': 'autocomplete', 'input': query},
      );
      return List<String>.from(response.data['predictions']);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> calculateRouteProxied(
    double pLat,
    double pLng,
    double dLat,
    double dLng,
  ) async {
    final response = await _supabase.functions.invoke(
      'maps-proxy',
      body: {
        'endpoint': 'directions',
        'origin': '$pLat,$pLng',
        'destination': '$dLat,$dLng',
      },
    );
    return response.data;
  }
}

final childrenRepositoryProvider = Provider((ref) => ChildrenRepository());
