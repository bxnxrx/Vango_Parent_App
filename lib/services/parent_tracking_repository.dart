import 'package:vango_parent_app/models/live_trip_location.dart';
import 'package:vango_parent_app/models/trip_geofence_event.dart';
import 'package:vango_parent_app/services/backend_client.dart';

class ParentTrackingRepository {
  ParentTrackingRepository({BackendClient? backendClient})
    : _backendClient = backendClient ?? BackendClient.instance;

  final BackendClient _backendClient;

  Future<LiveTripLocation?> fetchLatest(String tripId) async {
    try {
      final response = await _backendClient.get('/api/tracking/trips/$tripId/latest');
      if (response is! Map<String, dynamic>) {
        return null;
      }
      return LiveTripLocation.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<List<LiveTripLocation>> fetchHistory(String tripId, {int limit = 100}) async {
    try {
      final response = await _backendClient.get(
        '/api/tracking/trips/$tripId/history',
        queryParameters: {'limit': limit.toString()},
      );

      if (response is! List) {
        return const <LiveTripLocation>[];
      }

      return response
          .whereType<Map<String, dynamic>>()
          .map(LiveTripLocation.fromJson)
          .toList();
    } catch (_) {
      return const <LiveTripLocation>[];
    }
  }

  Future<List<TripGeofenceEvent>> fetchGeofenceEvents(String tripId, {int limit = 100}) async {
    try {
      final response = await _backendClient.get(
        '/api/tracking/trips/$tripId/geofence-events',
        queryParameters: {'limit': limit.toString()},
      );

      if (response is! List) {
        return const <TripGeofenceEvent>[];
      }

      return response
          .whereType<Map<String, dynamic>>()
          .map(TripGeofenceEvent.fromJson)
          .toList();
    } catch (_) {
      return const <TripGeofenceEvent>[];
    }
  }

  Future<Map<String, dynamic>?> fetchPlayback(
    String tripId, {
    DateTime? from,
    DateTime? to,
    int limit = 300,
    String order = 'asc',
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
      'order': order,
    };

    if (from != null) {
      query['from'] = from.toUtc().toIso8601String();
    }
    if (to != null) {
      query['to'] = to.toUtc().toIso8601String();
    }

    try {
      final response = await _backendClient.get(
        '/api/tracking/trips/$tripId/playback',
        queryParameters: query,
      );

      if (response is! Map<String, dynamic>) {
        return null;
      }

      return response;
    } catch (_) {
      return null;
    }
  }
}
