class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const backendBaseUrl = String.fromEnvironment('BACKEND_BASE_URL');

  static void ensure() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty || backendBaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL, SUPABASE_ANON_KEY, and BACKEND_BASE_URL must be provided via --dart-define.');
    }
  }
}
