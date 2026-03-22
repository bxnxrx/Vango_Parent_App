import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:vango_parent_app/services/app_config.dart';

class SupportbotService {
  SupportbotService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  List<String> _buildEndpointCandidates() {
    final candidates = <String>{};

    if (kDebugMode) {
      candidates.add('http://10.0.2.2:8080/api/support-chatbot/message');
      candidates.add('http://127.0.0.1:8080/api/support-chatbot/message');
    }

    void addForBase(String rawBase) {
      if (rawBase.isEmpty) {
        return;
      }

      final base = rawBase.endsWith('/')
          ? rawBase.substring(0, rawBase.length - 1)
          : rawBase;

      candidates.add('$base/api/support-chatbot/message');
      candidates.add('$base/support-chatbot/message');

      if (base.endsWith('/api')) {
        final rootBase = base.substring(0, base.length - 4);
        candidates.add('$rootBase/api/support-chatbot/message');
      }
    }

    addForBase(AppConfig.backendBaseUrl);

    return candidates.toList(growable: false);
  }

  Future<String> sendMessage({
    required String message,
    required String lang,
    required String sessionId,
  }) async {
    Map<String, dynamic>? response;
    Object? lastError;

    final payload = {
      'message': message,
      'lang': lang,
      'sessionId': sessionId,
      'clientType': 'parent',
    };

    for (final endpoint in _buildEndpointCandidates()) {
      try {
        final uri = Uri.parse(endpoint);
        final httpResponse = await _client
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 10));

        if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
          continue;
        }

        final decoded = jsonDecode(httpResponse.body);
        if (decoded is Map<String, dynamic>) {
          response = decoded;
          break;
        }
      } catch (error) {
        lastError = error;
      }
    }

    if (response == null) {
      throw Exception(lastError?.toString() ?? 'Support bot is unavailable');
    }

    final content = response['content']?.toString().trim() ?? '';
    if (content.isNotEmpty) {
      return content;
    }

    throw Exception('Support bot returned an invalid response');
  }
}