import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get backendBaseUrl => _resolveBackendBaseUrl();
  static String? get googleWebClientId => _readOptional('GOOGLE_WEB_CLIENT_ID');
  static String? get googleIosClientId => _readOptional('GOOGLE_IOS_CLIENT_ID');
  static String? get googleAndroidClientId => _readOptional('GOOGLE_ANDROID_CLIENT_ID');

  static void ensure() {
    if (supabaseUrl.isEmpty ||
        supabaseAnonKey.isEmpty ||
        backendBaseUrl.isEmpty) {
      throw Exception(
        'Missing environment variables in .env file. '
        'Ensure SUPABASE_URL, SUPABASE_ANON_KEY, and BACKEND_BASE_URL are set.',
      );
    }
  }

  static String _resolveBackendBaseUrl() {
    final raw = dotenv.env['BACKEND_BASE_URL'] ?? '';
    if (raw.isEmpty) {
      return raw;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      return raw;
    }

    final isLoopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (Platform.isAndroid && isLoopback) {
      return uri.replace(host: '10.0.2.2').toString();
    }

    return raw;
  }

  static String? _readOptional(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
