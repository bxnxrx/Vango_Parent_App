import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get backendBaseUrl => dotenv.env['BACKEND_BASE_URL'] ?? '';

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
}
