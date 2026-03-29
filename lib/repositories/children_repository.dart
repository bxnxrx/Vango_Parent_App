import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_api_headers/google_api_headers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';

class ChildrenRepository {
  final ParentDataService _dataService = ParentDataService.instance;
  static const platform = MethodChannel('com.vango.app/apikey');
  String? _cachedApiKey;

  Future<String?> getNativeApiKey() async {
    if (_cachedApiKey != null) {
      return _cachedApiKey;
    }
    try {
      _cachedApiKey = await platform.invokeMethod('getApiKey');
      return _cachedApiKey;
    } catch (_) {
      return null;
    }
  }

  Future<List<ChildProfile>> fetchChildren() async {
    return await _dataService.fetchChildren();
  }

  Future<void> deleteChild(String id) async {
    return await _dataService.deleteChild(id);
  }

  Future<Map<String, dynamic>> verifyInviteCode(String code) async {
    return await _dataService.verifyInviteCode(code);
  }

  Future<List<String>> searchSchools(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final apiKey = await getNativeApiKey();
    if (apiKey == null) {
      return [];
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&components=country:lk&types=establishment&key=$apiKey',
      );
      final headers = await const GoogleApiHeaders().getHeaders();
      final response = await http.get(url, headers: headers);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final keywords = [
          "school",
          "college",
          "university",
          "campus",
          "institute",
          "academy",
          "international",
          "vidyalaya",
          "balika",
          "montessori",
        ];
        return (data['predictions'] as List)
            .map<String>((p) => p['description'] as String)
            .where(
              (description) =>
                  keywords.any((k) => description.toLowerCase().contains(k)),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

final childrenRepositoryProvider = Provider((ref) => ChildrenRepository());
