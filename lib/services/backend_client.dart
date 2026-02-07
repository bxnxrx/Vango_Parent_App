import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class BackendClient {
  BackendClient._();

  static final BackendClient instance = BackendClient._();

  final http.Client _client = http.Client();

  Future<Map<String, String>> _headers() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (token == null) {
      throw Exception('No Supabase session available');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send({required String method, required String path, Map<String, String>? queryParameters, Map<String, dynamic>? body}) async {
    AppConfig.ensure();
    final baseUri = Uri.parse('${AppConfig.backendBaseUrl}$path');
    final uri = queryParameters == null ? baseUri : baseUri.replace(queryParameters: queryParameters);
    final headers = await _headers();
    http.Response response;

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}));
        break;
      case 'PATCH':
        response = await _client.patch(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}));
        break;
      default:
        throw UnsupportedError('Unsupported method $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      return jsonDecode(response.body);
    }

    debugPrint('Backend request to $path failed with ${response.statusCode}: ${response.body}');
    throw Exception('Backend request failed');
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParameters}) {
    return _send(method: 'GET', path: path, queryParameters: queryParameters);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) {
    return _send(method: 'POST', path: path, body: body);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) {
    return _send(method: 'PATCH', path: path, body: body);
  }

  Future<void> ensureBackendHealthy() async {
    AppConfig.ensure();
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/health');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Backend health check failed (${response.statusCode})');
    }
  }
}
