import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/models/live_trip_location.dart';
import 'package:vango_parent_app/models/trip_geofence_event.dart';

import 'app_config.dart';

class ParentTrackingSocketService {
  ParentTrackingSocketService();

  io.Socket? _socket;
  final StreamController<LiveTripLocation> _locationController = StreamController<LiveTripLocation>.broadcast();
  final StreamController<TripGeofenceEvent> _geofenceController = StreamController<TripGeofenceEvent>.broadcast();

  Stream<LiveTripLocation> get locationStream => _locationController.stream;
  Stream<TripGeofenceEvent> get geofenceEventStream => _geofenceController.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (isConnected) {
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (token == null) {
      throw Exception('Missing session token. Please log in again.');
    }

    final baseUrl = _resolveSocketBaseUrl();

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .enableForceNew()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    final socket = _socket!;
    final completer = Completer<void>();

    socket.onConnect((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    socket.onConnectError((error) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Socket connection error: $error'));
      }
    });

    socket.on('trip:location_broadcast', (payload) {
      if (payload is Map) {
        final parsed = <String, dynamic>{};
        payload.forEach((key, value) {
          parsed[key.toString()] = value;
        });
        _locationController.add(LiveTripLocation.fromJson(parsed));
      }
    });

    socket.on('trip:geofence_event', (payload) {
      if (payload is Map) {
        final parsed = <String, dynamic>{};
        payload.forEach((key, value) {
          parsed[key.toString()] = value;
        });
        _geofenceController.add(TripGeofenceEvent.fromJson(parsed));
      }
    });

    socket.connect();

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Socket connection timeout'),
    );
  }

  Future<void> subscribeToTrip(String tripId) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw Exception('Socket is not connected');
    }

    final completer = Completer<void>();

    socket.emitWithAck('parent:subscribe_trip', {'tripId': tripId}, ack: (response) {
      if (response is Map && response['ok'] == true) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        return;
      }

      final message = response is Map
          ? (response['message']?.toString() ?? 'Trip subscription failed')
          : 'Trip subscription failed';

      if (!completer.isCompleted) {
        completer.completeError(Exception(message));
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception('Trip subscription timeout'),
    );
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _locationController.close();
    _geofenceController.close();
  }

  String _resolveSocketBaseUrl() {
    AppConfig.ensure();
    final backendUrl = AppConfig.backendBaseUrl;
    final uri = Uri.parse(backendUrl);

    final normalized = uri.replace(
      path: '',
      query: null,
      fragment: null,
    );

    return normalized.toString();
  }
}
