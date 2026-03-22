import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ParentEmergencyService {
  static final _supabase = Supabase.instance.client;

  // 1. Fetch the logs for the currently logged-in parent
  static Future<List<Map<String, dynamic>>> getLogs() async {
    try {
      final parentId = _supabase.auth.currentUser?.id;
      if (parentId == null) return [];

      // Grab the logs AND the attached emergency details
      final response = await _supabase
          .from('notification_logs')
          .select('''
            id,
            title,
            message,
            is_read,
            created_at,
            emergencies (
              emergency_type,
              category,
              status
            )
          ''')
          .eq('user_id', parentId) // Only get THIS parent's logs
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("❌ Error fetching logs: $e");
      return [];
    }
  }

  // 2. Mark the log as read when the parent taps it
  static Future<void> markAsRead(String logId) async {
    try {
      await _supabase
          .from('notification_logs')
          .update({'is_read': true})
          .eq('id', logId);
    } catch (e) {
      debugPrint("❌ Error marking read: $e");
    }
  }
}