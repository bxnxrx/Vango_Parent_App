import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/utils/app_auth_exception.dart';

class ChildrenRepository {
  final ParentDataService _dataService = ParentDataService.instance;
  static const platform = MethodChannel('com.vango.app/apikey');
  String? _cachedApiKey;

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
    try {
      final data = await _dataService.verifyInviteCode(code);
      if (data['valid'] == true) {
        return DriverProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      // Expected behavior for invalid codes (HTTP 400). Do not log as crash.
      return null;
    }
  }

  // ✅ FIRM SECURITY: Backend handles OTP completely.
  Future<void> sendEmergencyContactOtp(String phone) async {
    try {
      await _dataService.sendEmergencyContactOtp(phone);
    } catch (e) {
      // It's a standard API failure, pass it gracefully to UI instead of treating as an App Crash.
      throw AppAuthException(
        code: 'OTP_SEND_FAILED',
        message: 'Failed to send verification code. Please try again.',
      );
    }
  }

  // ✅ FIRM SECURITY: Backend validates OTP.
  Future<void> verifyEmergencyContactOtp(String phone, String code) async {
    try {
      await _dataService.verifyEmergencyContactOtp(phone, code);
    } catch (e) {
      // It's a validation error (user entered wrong OTP). Never log these to Crashlytics.
      throw AppAuthException(
        code: 'OTP_VERIFY_FAILED',
        message: 'Invalid or expired verification code.',
      );
    }
  }

  // Retained purely to feed the GoogleMaps PlacePicker widget UI natively.
  Future<String?> getSecureMapsKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;
    try {
      _cachedApiKey = await platform.invokeMethod('getApiKey');
      return _cachedApiKey;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Native MethodChannel maps key fetch failed',
      );
      return null;
    }
  }

  // ✅ PROXY FIXED & NO SILENT CATCHES
  Future<List<String>> searchSchoolsProxied(String query) async {
    if (query.isEmpty) return [];

    try {
      return await _dataService.proxyMapsAutocomplete(query);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Maps Autocomplete Proxy failed',
      );
      return []; // Return empty list rather than crashing the dropdown UI
    }
  }

  // ✅ PROXY FIXED & NO SILENT CATCHES
  Future<Map<String, dynamic>> calculateRouteProxied(
    double pLat,
    double pLng,
    double dLat,
    double dLng,
  ) async {
    try {
      return await _dataService.proxyMapsDirections(pLat, pLng, dLat, dLng);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Maps Directions Proxy failed',
      );
      throw AppAuthException(
        code: 'MAPS_ERROR',
        message: 'Error calculating route via proxy.',
      );
    }
  }
}

final childrenRepositoryProvider = Provider((ref) => ChildrenRepository());
