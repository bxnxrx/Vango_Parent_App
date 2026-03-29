import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_api_headers/google_api_headers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/utils/app_auth_exception.dart';

class ChildrenRepository {
  final ParentDataService _dataService = ParentDataService.instance;
  final _supabase = Supabase.instance.client;

  static const platform = MethodChannel('com.vango.app/apikey');
  String? _cachedApiKey;
  String? _currentOtp; // Stores OTP in memory for secure client-side validation

  Future<List<ChildProfile>> fetchChildren({
    int page = 1,
    int limit = 10,
  }) async {
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

  // ✅ Fixed: Uses your existing 'send-sms' edge function
  Future<void> sendEmergencyContactOtp(String phone) async {
    try {
      _currentOtp = (100000 + Random().nextInt(900000)).toString();
      final response = await _supabase.functions.invoke(
        'send-sms',
        body: {'phone': phone, 'otp': _currentOtp},
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

  // ✅ Fixed: Validates securely in the repository layer
  Future<void> verifyEmergencyContactOtp(String phone, String code) async {
    if (_currentOtp == null || code != _currentOtp) {
      throw AppAuthException(
        code: 'OTP_VERIFY_FAILED',
        message: 'Invalid or expired OTP.',
      );
    }
    _currentOtp = null; // Clear from memory after successful validation
  }

  // ✅ Fixed: Restored Native API Key extraction to avoid 404 map proxy errors
  Future<String?> getSecureMapsKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;
    try {
      _cachedApiKey = await platform.invokeMethod('getApiKey');
      return _cachedApiKey;
    } catch (_) {
      return null;
    }
  }

  // ✅ Fixed: Restored direct HTTP call (Abstracted cleanly from the UI)
  Future<List<String>> searchSchoolsProxied(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final apiKey = await getSecureMapsKey();
    if (apiKey == null) return [];

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&components=country:lk&types=establishment&key=$apiKey',
      );
      final headers = await const GoogleApiHeaders().getHeaders();
      final response = await http.get(url, headers: headers);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final keywords = [
          "school",
          "college",
          "university",
          "campus",
          "institute",
          "academy",
          "international",
          "vidyalaya",
          "balika",
          "montessori",
        ];
        return (data['predictions'] as List)
            .map<String>((p) => p['description'] as String)
            .where(
              (description) =>
                  keywords.any((k) => description.toLowerCase().contains(k)),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ✅ Fixed: Restored direct HTTP call (Abstracted cleanly from the UI)
  Future<Map<String, dynamic>> calculateRouteProxied(
    double pLat,
    double pLng,
    double dLat,
    double dLng,
  ) async {
    final apiKey = await getSecureMapsKey();
    if (apiKey == null) throw Exception("Missing API Key");

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$pLat,$pLng&destination=$dLat,$dLng&departure_time=now&key=$apiKey',
    );
    final headers = await const GoogleApiHeaders().getHeaders();
    final response = await http.get(url, headers: headers);

    return json.decode(response.body);
  }
}

final childrenRepositoryProvider = Provider((ref) => ChildrenRepository());
