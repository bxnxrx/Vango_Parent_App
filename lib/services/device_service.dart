import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceService {
  final _supabase = Supabase.instance.client;
  final _fcm = FirebaseMessaging.instance;

  Future<void> syncDeviceData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return; // Only sync if logged in

    try {
      // 1. Get Push Token (With Retry Mechanism for SERVICE_NOT_AVAILABLE)
      String? pushToken;
      int retries = 3;

      while (retries > 0) {
        try {
          if (Platform.isIOS) {
            final apnsToken = await _fcm.getAPNSToken();
            if (apnsToken != null) {
              pushToken = await _fcm.getToken();
            }
          } else {
            pushToken = await _fcm.getToken();
          }
          break; // Token fetched successfully, exit the loop
        } catch (e) {
          retries--;
          print(
            '⚠️ Failed to get FCM token. Retries left: $retries. Error: $e',
          );
          if (retries > 0) {
            await Future.delayed(
              const Duration(seconds: 2),
            ); // Wait 2 seconds before retrying
          } else {
            print(
              '❌ Proceeding without FCM token. Push notifications may not work on this device.',
            );
          }
        }
      }

      // 2. Get Device Details
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceIdentifier = 'unknown';
      String deviceName = 'unknown';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceIdentifier = androidInfo.id; // Unique Android ID
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceIdentifier = iosInfo.identifierForVendor ?? 'unknown_ios';
        deviceName = iosInfo.name;
      }

      // 2.5 Get Public IP Address
      String? currentIp;
      try {
        final ipResponse = await http
            .get(Uri.parse('https://api.ipify.org?format=json'))
            .timeout(const Duration(seconds: 3));
        if (ipResponse.statusCode == 200) {
          currentIp = jsonDecode(ipResponse.body)['ip'];
        }
      } catch (e) {
        print('⚠️ Could not fetch IP address: $e');
      }

      // 3. Upsert to Supabase
      await _supabase.from('trusted_devices').upsert({
        'user_id': user.id,
        'device_identifier': deviceIdentifier,
        'push_token':
            pushToken, // This might be null if FCM failed, but the rest of the data will still save
        'device_name': deviceName,
        'platform': Platform.operatingSystem,
        'app_version': packageInfo.version,
        'last_ip_address': currentIp,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'is_revoked': false, // ✅ FIX: explicitly set so backend query can find this row
      }, onConflict: 'user_id, device_identifier');

      print('✅ Device synced successfully to trusted_devices!');
    } catch (e) {
      print('❌ Error syncing device data: $e');
    }
  }

  // Call this to listen for token changes while the app is running
  void listenForTokenRefreshes() {
    _fcm.onTokenRefresh.listen((newToken) async {
      // Re-run the sync if the token changes
      await syncDeviceData();
    });
  }
}
