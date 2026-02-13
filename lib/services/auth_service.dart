import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> signInWithGoogleNative({
    String? webClientId,
    // REMOVED: String? iosClientId, (Not needed anymore)
    String? androidClientId,
  }) async {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    if (Platform.isIOS && (iosClientId == null || iosClientId.isEmpty)) {
      throw Exception(
        'GOOGLE_IOS_CLIENT_ID is missing in .env. Please add it.',
      );
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: webClientId,
      clientId: iosClientId ?? androidClientId,
=======
    // 1. Initialize Google Sign-In
    // We do NOT pass clientId for iOS anymore. The plugin reads it from GoogleService-Info.plist automatically.
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: webClientId,
>>>>>>> Stashed changes
=======
    // 1. Initialize Google Sign-In
    // We do NOT pass clientId for iOS anymore. The plugin reads it from GoogleService-Info.plist automatically.
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: webClientId,
>>>>>>> Stashed changes
    );

    await googleSignIn.signOut();

    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Missing Google ID token');
      }

<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
      // 2. Authenticate with Supabase
>>>>>>> Stashed changes
=======
      // 2. Authenticate with Supabase
>>>>>>> Stashed changes
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
      throw Exception(
        'Google Sign-In failed: $e. (Check Info.plist URL Schemes)',
      );
=======
=======
>>>>>>> Stashed changes
      // Log the full error to help debug
      print("Google Sign In Error: $e");
      throw Exception('Google Sign-In failed: $e');
>>>>>>> Stashed changes
    }
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(OAuthProvider.apple);
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
  }

  Future<String> createChild({
    required String childName,
    required String school,
    required String pickupLocation,
    String? pickupTime,
  }) async {
    final profile = await ParentDataService.instance.createChild(
      childName: childName,
      school: school,
      pickupLocation: pickupLocation,
      pickupTime: pickupTime,
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

  // --- IDENTITY LINKING METHODS ---

  /// Links a phone number to the currently logged in user (Email account)
  Future<void> linkPhone(String phone) async {
    await _client.auth.updateUser(UserAttributes(phone: phone));
  }

  /// Verifies the OTP sent to the phone for linking purposes
  Future<void> verifyLinkedPhone({
    required String phone,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.phoneChange,
    );
    // Optionally mark as verified in your DB immediately
    await markPhoneVerified();
  }

  /// Links an email to the currently logged in user (Phone account)
  Future<void> linkEmail(String email) async {
    await _client.auth.updateUser(UserAttributes(email: email));
  }

  /// Verifies the OTP sent to the email for linking purposes
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

  // ------------------------------

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
