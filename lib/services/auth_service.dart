import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';
import 'backend_client.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> initialize() async {
    AppConfig.ensure();
  }

  Future<void> signInOrSignUp(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (_) {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: const {'role': 'parent'},
      );
    }
  }

  Future<void> saveParentProfile({required String fullName, required String phone}) async {
    await BackendClient.instance.post('/api/parents/profile', {
      'fullName': fullName,
      'phone': phone,
    });
  }

  Future<String> createChild({
    required String childName,
    required String school,
    required String pickupLocation,
  }) async {
    final response = await BackendClient.instance.post('/api/parents/children', {
      'childName': childName,
      'school': school,
      'pickupLocation': pickupLocation,
    });

    final id = response['id'] as String?;
    if (id == null) {
      throw Exception('Child ID missing from backend response');
    }
    return id;
  }

  Future<void> linkDriver({required String code, required String childId}) async {
    await BackendClient.instance.post('/api/parents/link-driver', {
      'code': code,
      'childId': childId,
    });
  }

  Future<void> requestPhoneOtp(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone, shouldCreateUser: false);
  }

  Future<void> verifyPhoneOtp({required String phone, required String token}) async {
    await _supabase.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
    await BackendClient.instance.post('/api/auth/complete', {
      'role': 'parent',
      'phoneVerifiedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> cachePhone(String phone) async {
    await _storage.write(key: 'parent_phone', value: phone);
  }

  Future<String?> getCachedPhone() async {
    return _storage.read(key: 'parent_phone');
  }
}
