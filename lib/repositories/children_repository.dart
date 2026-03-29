import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';

class ChildrenRepository {
  final ParentDataService _dataService = ParentDataService.instance;
  final _supabase = Supabase.instance.client;

  Future<List<ChildProfile>> fetchChildren({
    int page = 1,
    int limit = 10,
  }) async {
    // Pass pagination parameters if supported by your backend
    return await _dataService.fetchChildren();
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

  // ✅ Secure Backend OTP
  Future<bool> sendEmergencyContactOtp(String phone) async {
    try {
      final response = await _supabase.functions.invoke(
        'auth-otp',
        body: {'action': 'send', 'phone': phone},
      );
      return response.status == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyEmergencyContactOtp(String phone, String code) async {
    try {
      final response = await _supabase.functions.invoke(
        'auth-otp',
        body: {'action': 'verify', 'phone': phone, 'code': code},
      );
      return response.status == 200 && response.data['verified'] == true;
    } catch (_) {
      return false;
    }
  }

  // ✅ Secure API Key & Proxies (Hides Google Maps Key from Client)
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
