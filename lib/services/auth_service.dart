import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/utils/app_auth_exception.dart';
import 'app_config.dart';
import 'backend_client.dart';
import 'parent_data_service.dart';

enum OnboardingPhase { email, phone, profile, link, completed }

OnboardingPhase _parsePhase(String? value) {
  switch (value) {
    case 'phone':
      return OnboardingPhase.phone;
    case 'profile':
      return OnboardingPhase.profile;
    case 'link':
      return OnboardingPhase.link;
    case 'completed':
      return OnboardingPhase.completed;
    case 'email':
    default:
      return OnboardingPhase.email;
  }
}

class ParentStageInfo {
  const ParentStageInfo({
    this.parentId,
    required this.profileComplete,
    required this.childCount,
    required this.linkedChildren,
  });

  factory ParentStageInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ParentStageInfo(
        parentId: null,
        profileComplete: false,
        childCount: 0,
        linkedChildren: 0,
      );
    }

    return ParentStageInfo(
      parentId: json['parentId'] as String?,
      profileComplete: json['profileComplete'] == true,
      childCount: (json['childCount'] as num?)?.toInt() ?? 0,
      linkedChildren: (json['linkedChildren'] as num?)?.toInt() ?? 0,
    );
  }

  final String? parentId;
  final bool profileComplete;
  final int childCount;
  final int linkedChildren;

  bool get hasLinkedDriver => linkedChildren > 0;
}

class OnboardingStatus {
  const OnboardingStatus({
    required this.phase,
    required this.ready,
    required this.emailComplete,
    required this.phoneComplete,
    required this.profileComplete,
    required this.linkComplete,
    this.role,
    this.parent,
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> readSteps() {
      final raw = json['steps'];
      if (raw is Map<String, dynamic>) {
        return raw;
      }
      return const <String, dynamic>{};
    }

    bool stepComplete(String key) {
      final steps = readSteps();
      final value = steps[key];
      if (value is Map<String, dynamic>) {
        return value['completed'] == true;
      }
      return false;
    }

    return OnboardingStatus(
      role: json['role'] as String?,
      phase: _parsePhase(json['nextStep'] as String?),
      ready: json['ready'] == true,
      emailComplete: stepComplete('email'),
      phoneComplete: stepComplete('phone'),
      profileComplete: stepComplete('profile'),
      linkComplete: stepComplete('link'),
      parent: ParentStageInfo.fromJson(json['parent'] as Map<String, dynamic>?),
    );
  }

  final String? role;
  final OnboardingPhase phase;
  final bool ready;
  final bool emailComplete;
  final bool phoneComplete;
  final bool profileComplete;
  final bool linkComplete;
  final ParentStageInfo? parent;
}

class EmailAuthResult {
  const EmailAuthResult({required this.requiresEmailVerification});

  final bool requiresEmailVerification;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? get currentUser => _client.auth.currentUser;

  Future<void> initialize() async {
    AppConfig.ensure();
    await BackendClient.instance.ensureBackendHealthy();
  }

  Future<void> signInWithPhone(String phone) async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
    } catch (e) {
      throw AppAuthException(code: 'phone_auth_failed', message: e.toString());
    }
  }

  Future<void> resendEmailSignupOtp(String email) async {
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      throw AppAuthException(code: 'resend_failed', message: e.toString());
    }
  }

  Future<bool> checkUserExists(String email) async {
    try {
      final res = await Supabase.instance.client
          .from('parents')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      return res != null;
    } catch (e) {
      throw AppAuthException(code: 'user_check_failed', message: e.toString());
    }
  }

  Future<void> verifyAuthOtp({
    required bool isEmail,
    required String identifier,
    required String token,
    bool isSignup = true,
  }) async {
    try {
      await Supabase.instance.client.auth.verifyOTP(
        type: isEmail
            ? (isSignup ? OtpType.signup : OtpType.email)
            : OtpType.sms,
        token: token,
        email: isEmail ? identifier : null,
        phone: !isEmail ? identifier : null,
      );
    } catch (e) {
      throw AppAuthException(code: 'otp_invalid', message: e.toString());
    }
  }

  Future<void> resendAuthOtp({
    required bool isEmail,
    required String identifier,
    bool isSignup = true,
  }) async {
    try {
      if (isEmail) {
        await Supabase.instance.client.auth.resend(
          type: OtpType.signup,
          email: identifier,
        );
      } else {
        await Supabase.instance.client.auth.signInWithOtp(phone: identifier);
      }
    } catch (e) {
      throw AppAuthException(code: 'otp_resend_failed', message: e.toString());
    }
  }

  Future<void> resetPasswordWithOtp(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AppAuthException(
        code: 'password_reset_failed',
        message: e.toString(),
      );
    }
  }

  Future<EmailAuthResult> signInOrSignUp(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return const EmailAuthResult(requiresEmailVerification: false);
    } on AuthException catch (error) {
      if (!error.message.toLowerCase().contains('invalid login credentials')) {
        rethrow;
      }
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: null,
      data: const {'role': 'parent'},
    );

    final requiresVerification = response.session == null;
    return EmailAuthResult(requiresEmailVerification: requiresVerification);
  }

  Future<void> signInWithPassword(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithGoogleNative({String? webClientId}) async {
    final normalizedClientId = webClientId?.trim();

    Future<void> tryNative({String? serverClientId}) async {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: serverClientId,
      );

      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Missing Google ID token');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    }

    try {
      await tryNative(
        serverClientId:
            (normalizedClientId == null || normalizedClientId.isEmpty)
            ? null
            : normalizedClientId,
      );
      return;
    } catch (firstError) {
      debugPrint(
        'Google native sign-in (with configured client ID) failed: $firstError',
      );
    }

    try {
      await tryNative(serverClientId: null);
    } catch (secondError) {
      debugPrint(
        'Google native sign-in (without server client ID) failed: $secondError',
      );
      throw Exception(
        'Google Sign-In failed on this device. Check Android SHA fingerprints and OAuth client setup in Firebase/Supabase.',
      );
    }
  }

  Future<void> signInWithApple() async {
    final rawNonce = _client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception(
        'Could not find ID Token from generated Apple credential.',
      );
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  Future<OnboardingStatus> fetchOnboardingStatus() async {
    final response = await BackendClient.instance.get('/api/auth/status');
    if (response is Map<String, dynamic>) {
      return OnboardingStatus.fromJson(response);
    }
    throw StateError('Unexpected onboarding payload');
  }

  Future<OnboardingStatus> markEmailVerified({String role = 'parent'}) {
    return _postProgress({'role': role, 'emailVerifiedAt': _isoNow()});
  }

  Future<OnboardingStatus> markPhoneVerified() {
    return _postProgress({'role': 'parent', 'phoneVerifiedAt': _isoNow()});
  }

  Future<OnboardingStatus> markProfileCompleted() {
    return _postProgress({'role': 'parent', 'profileCompletedAt': _isoNow()});
  }

  Future<OnboardingStatus> _postProgress(Map<String, dynamic> body) async {
    if (body.isEmpty) {
      throw Exception('No onboarding fields supplied');
    }
    final response = await BackendClient.instance.post(
      '/api/auth/progress',
      body,
    );
    if (response is Map<String, dynamic>) {
      final onboarding = response['onboarding'];
      if (onboarding is Map<String, dynamic>) {
        return OnboardingStatus.fromJson(onboarding);
      }
    }
    return fetchOnboardingStatus();
  }

  String _isoNow() => DateTime.now().toUtc().toIso8601String();

  Future<void> saveParentProfile({
    required String fullName,
    required String phone,
    String? email,
    String? relationship,
  }) async {
    await BackendClient.instance.post('/api/parents/profile', {
      'fullName': fullName,
      'phone': phone,
      if (email != null) 'email': email,
      if (relationship != null) 'relationship': relationship,
    });

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        await _client
            .from('parents')
            .update({'is_account_created': true})
            .eq('supabase_user_id', userId);
        debugPrint(
          '✅ Successfully marked is_account_created = true in Supabase',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to update is_account_created: $e');
    }
  }

  // --- UPDATED CREATE CHILD WITH NEW REQUIRED FIELDS ---
  Future<String> createChild({
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
  }) async {
    final profile = await ParentDataService.instance.createChild(
      childName: childName,
      age: age,
      school: school,
      pickupLocation: pickupLocation,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLocation: dropLocation,
      dropLat: dropLat,
      dropLng: dropLng,
      inviteCode: inviteCode,
      pickupTime: pickupTime,
      etaSchool: etaSchool,
      emergencyContact: emergencyContact,
      description: description,
    );
    return profile.id;
  }

  Future<void> linkDriver({
    required String code,
    required String childId,
  }) async {
    await BackendClient.instance.post('/api/parents/link-driver', {
      'code': code.trim().toUpperCase(),
      'childId': childId,
    });
  }

  Future<void> requestPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone, shouldCreateUser: false);
  }

  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    await _client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> requestEmailOtp(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    await _client.auth.verifyOTP(email: email, token: token, type: type);
    await markEmailVerified();
  }

  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  Future<void> updateUserPassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> linkPhone(String phone) async {
    await _client.auth.updateUser(UserAttributes(phone: phone));
  }

  Future<void> verifyLinkedPhone({
    required String phone,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.phoneChange,
    );
    await markPhoneVerified();
  }

  Future<void> linkEmail(String email) async {
    await _client.auth.updateUser(UserAttributes(email: email));
  }

  Future<void> verifyLinkedEmail({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.emailChange,
    );
    await markEmailVerified();
  }

  Future<void> cachePhone(String phone) async {
    await _storage.write(key: 'parent_phone', value: phone);
  }

  Future<String?> getCachedPhone() async {
    return _storage.read(key: 'parent_phone');
  }

  Future<bool> hasDriverLink() {
    return ParentDataService.instance.hasLinkedDriver();
  }

  Future<void> cancelSignup() async {
    await BackendClient.instance.post('/api/auth/cancel-signup', {});
    await _client.auth.signOut();
    await _storage.delete(key: 'parent_phone');
  }
}
