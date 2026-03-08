import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  Future<dynamic> _send({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    AppConfig.ensure();
    final baseUri = Uri.parse('${AppConfig.backendBaseUrl}$path');
    final uri = queryParameters == null
        ? baseUri
        : baseUri.replace(queryParameters: queryParameters);
    final headers = await _headers();
    http.Response response;

    try {
      // UPGRADE 1: 10-Second API Timeout
      const timeoutDuration = Duration(seconds: 10);

      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(timeoutDuration);
          break;
        case 'POST':
          response = await _client
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body ?? <String, dynamic>{}),
              )
              .timeout(timeoutDuration);
          break;
        case 'PATCH':
          response = await _client
              .patch(
                uri,
                headers: headers,
                body: jsonEncode(body ?? <String, dynamic>{}),
              )
              .timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await _client
              .put(
                uri,
                headers: headers,
                body: jsonEncode(body ?? <String, dynamic>{}),
              )
              .timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await _client
              .delete(
                uri,
                headers: headers,
                body: jsonEncode(body ?? <String, dynamic>{}),
              )
              .timeout(timeoutDuration);
          break;
        default:
          throw UnsupportedError('Unsupported method $method');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timed out. Please check your internet and try again.',
      );
    } on SocketException {
      // UPGRADE 2: Offline Handling
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      throw Exception('Network request failed: $e');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      return jsonDecode(response.body);
    }

    debugPrint(
      'Backend request to $path failed with ${response.statusCode}: ${response.body}',
    );

    String errorMessage = 'Backend request failed (${response.statusCode})';
    try {
      final Map<String, dynamic> errorBody = jsonDecode(response.body);
      if (errorBody.containsKey('message')) {
        errorMessage = errorBody['message']?.toString() ?? errorMessage;
      } else if (errorBody.containsKey('errors')) {
        errorMessage = 'Validation Error: ${errorBody['errors']}';
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        errorMessage = '$errorMessage: ${response.body}';
      }
    }

    throw Exception(errorMessage);
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

  Future<dynamic> put(String path, Map<String, dynamic> body) {
    return _send(method: 'PUT', path: path, body: body);
  }

  Future<dynamic> delete(String path) {
    return _send(method: 'DELETE', path: path);
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
