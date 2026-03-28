import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CallService {
  CallService._privateConstructor();
  static final CallService instance = CallService._privateConstructor();

  final String _baseUrl = 'https://api.vango.lk/api';

  /// Tells the backend to send a "Wake Up & Ring" push notification to the driver
  Future<bool> notifyDriverOfCall({
    required String receiverId,
    required String channelName,
  }) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('[CALL SERVICE] ❌ No authenticated user found.');
        return false;
      }

      // 1. Fetch the Parent's real name (Adjust 'parents' table if yours is named differently)
      String callerName = 'VanGo Parent';
      try {
        final parentData = await Supabase.instance.client
            .from('parents') // Change to 'users' if your parents are stored there
            .select('first_name, last_name')
            .eq('id', currentUser.id)
            .maybeSingle();
        
        if (parentData != null) {
          callerName = '${parentData['first_name']} ${parentData['last_name']}';
        }
      } catch (e) {
        debugPrint('[CALL SERVICE] Could not fetch parent name, using default.');
      }

      // 2. Prepare payload for Node.js backend
      final url = Uri.parse('$_baseUrl/call/ring');
      final payload = {
        'callerName': callerName,
        'receiverId': receiverId,
        'channelName': channelName,
        'callerId': currentUser.id,
      };

      debugPrint('[CALL SERVICE] 📡 Sending ring signal to driver: $payload');

      // 3. Fire the HTTP request
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('[CALL SERVICE] ✅ Successfully notified backend to ring driver.');
        return true;
      } else {
        debugPrint('[CALL SERVICE] ❌ Backend error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[CALL SERVICE] ❌ Error notifying driver: $e');
      return false;
    }
  }

  /// Optional: Cancel call if parent hangs up before driver answers
  Future<bool> cancelCall({
    required String receiverId,
    required String channelName,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/call/cancel');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'receiverId': receiverId,
          'channelName': channelName,
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[CALL SERVICE] ❌ Error canceling call: $e');
      return false;
    }
  }
}