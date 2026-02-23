import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vango_parent_app/models/live_trip_location.dart';
import 'package:vango_parent_app/models/trip_geofence_event.dart';
import 'package:vango_parent_app/services/parent_tracking_repository.dart';
import 'package:vango_parent_app/services/parent_tracking_socket_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({
    super.key,
    required this.tripId,
    this.title = 'Live Tracking',
    this.destinationLatitude = 6.9271,
    this.destinationLongitude = 79.8612,
  });

  final String tripId;
  final String title;
  final double destinationLatitude;
  final double destinationLongitude;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  static const LatLng _fallbackCenter = LatLng(6.9271, 79.8612);
  static const double _fallbackSpeedKmh = 30.0;
  static const String _purpleMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#4b3b6b"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#3b2d55"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#1f1730"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#b39ddb"}]}
]
''';

  final ParentTrackingRepository _repository = ParentTrackingRepository();
  final ParentTrackingSocketService _socketService = ParentTrackingSocketService();

  GoogleMapController? _mapController;
  StreamSubscription<LiveTripLocation>? _locationSubscription;
  StreamSubscription<TripGeofenceEvent>? _geofenceSubscription;
  Timer? _playbackTimer;

  LiveTripLocation? _latestLocation;
  List<LiveTripLocation> _history = <LiveTripLocation>[];
  List<TripGeofenceEvent> _geofenceEvents = <TripGeofenceEvent>[];
  List<LiveTripLocation> _playbackPoints = <LiveTripLocation>[];
  bool _loading = true;
  String? _error;
  bool _isReconnecting = false;
  bool _isPlaybackMode = false;
  bool _isPlayingPlayback = false;
  bool _isLoadingPlayback = false;
  int _playbackIndex = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _geofenceSubscription?.cancel();
    _playbackTimer?.cancel();
    _mapController?.dispose();
    _socketService.dispose();
    super.dispose();
  }

  LiveTripLocation? get _displayLocation {
    if (_isPlaybackMode && _playbackPoints.isNotEmpty) {
      return _playbackPoints[_playbackIndex];
    }

    return _latestLocation;
  }

  Future<void> _togglePlaybackMode() async {
    if (_isPlaybackMode) {
      _playbackTimer?.cancel();
      setState(() {
        _isPlaybackMode = false;
        _isPlayingPlayback = false;
        _isLoadingPlayback = false;
      });
      return;
    }

    setState(() {
      _isLoadingPlayback = true;
      _error = null;
    });

    try {
      final playback = await _repository.fetchPlayback(
        widget.tripId,
        limit: 500,
        order: 'asc',
      );

      final rawPoints = playback?['points'];
      final parsedPoints = <LiveTripLocation>[];

      if (rawPoints is List) {
        for (final item in rawPoints) {
          if (item is Map) {
            final json = <String, dynamic>{};
            item.forEach((key, value) {
              json[key.toString()] = value;
            });
            parsedPoints.add(LiveTripLocation.fromJson(json));
          }
        }
      }

      if (!mounted) {
        return;
      }

      if (parsedPoints.isEmpty) {
        setState(() {
          _isLoadingPlayback = false;
          _error = 'No playback points found for this trip.';
        });
        return;
      }

      setState(() {
        _playbackPoints = parsedPoints;
        _playbackIndex = 0;
        _isPlaybackMode = true;
        _isPlayingPlayback = false;
        _isLoadingPlayback = false;
      });

      _animateTo(parsedPoints.first);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingPlayback = false;
        _error = 'Failed to load playback: $error';
      });
    }
  }

  void _togglePlaybackRunning() {
    if (_playbackPoints.length < 2) {
      return;
    }

    if (_isPlayingPlayback) {
      _playbackTimer?.cancel();
      setState(() {
        _isPlayingPlayback = false;
      });
      return;
    }

    _playbackTimer?.cancel();
    setState(() {
      _isPlayingPlayback = true;
    });

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted || !_isPlaybackMode) {
        timer.cancel();
        return;
      }

      if (_playbackIndex >= _playbackPoints.length - 1) {
        timer.cancel();
        setState(() {
          _isPlayingPlayback = false;
        });
        return;
      }

      setState(() {
        _playbackIndex += 1;
      });

      _animateTo(_playbackPoints[_playbackIndex]);
    });
  }

  Future<void> _bootstrap() async {
    try {
      final results = await Future.wait([
        _repository.fetchLatest(widget.tripId),
        _repository.fetchHistory(widget.tripId, limit: 80),
        _repository.fetchGeofenceEvents(widget.tripId, limit: 10),
      ]);

      final latest = results[0] as LiveTripLocation?;
      final history = results[1] as List<LiveTripLocation>;
      final geofenceEvents = results[2] as List<TripGeofenceEvent>;

      if (!mounted) {
        return;
      }

      setState(() {
        _latestLocation = latest;
        _history = history;
        _geofenceEvents = geofenceEvents;
        _loading = false;
        _error =
            latest == null
            ? 'No accessible live location yet. Link the parent to the driver and ensure tracking has started.'
            : null;
      });

      await _socketService.connect();
      await _socketService.subscribeToTrip(widget.tripId);

      _locationSubscription = _socketService.locationStream.listen(
        (location) {
          if (!mounted) {
            return;
          }

          setState(() {
            _latestLocation = location;
            _error = null;
            _isReconnecting = false;

            final isDuplicate = _history.isNotEmpty &&
                _history.first.recordedAt == location.recordedAt;

            if (!isDuplicate) {
              _history.insert(0, location);
              if (_history.length > 120) {
                _history = _history.sublist(0, 120);
              }
            }
          });

          _animateTo(location);
        },
        onError: (_) {
          if (!mounted) {
            return;
          }

          setState(() {
            _isReconnecting = true;
          });
        },
      );

      _geofenceSubscription = _socketService.geofenceEventStream.listen((event) {
        if (!mounted) {
          return;
        }

        setState(() {
          _geofenceEvents.insert(0, event);
          if (_geofenceEvents.length > 10) {
            _geofenceEvents = _geofenceEvents.sublist(0, 10);
          }
        });
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _animateTo(LiveTripLocation location) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(location.latitude, location.longitude),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    final latest = _latestLocation;
    if (latest != null) {
      markers.add(Marker(
        markerId: const MarkerId('van'),
        position: LatLng(latest.latitude, latest.longitude),
        rotation: latest.heading ?? 0,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Van Location'),
      ));
    }

    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.destinationLatitude, widget.destinationLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    );

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final source = _isPlaybackMode ? _playbackPoints : _history.reversed.toList();

    if (source.length < 2) {
      return const <Polyline>{};
    }

    final points = (_isPlaybackMode ? source.take(_playbackIndex + 1) : source)
        .map((location) => LatLng(location.latitude, location.longitude))
        .toList();

    return {
      Polyline(
        polylineId: const PolylineId('trip_route'),
        points: points,
        color: AppColors.accent.withOpacity(0.8),
        width: 5,
        geodesic: true,
      ),
    };
  }

  String _buildEtaText(LiveTripLocation location) {
    final distanceKm = _distanceInKm(
      location.latitude,
      location.longitude,
      widget.destinationLatitude,
      widget.destinationLongitude,
    );

    final speed = (location.speedKmh != null && location.speedKmh! > 0)
        ? location.speedKmh!
        : _fallbackSpeedKmh;

    final minutes = ((distanceKm / speed) * 60).round();

    if (minutes <= 1) {
      return 'Arriving soon';
    }

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return '${hours}h ${remaining}m';
  }

  double _distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;

    final latDistance = _toRadians(lat2 - lat1);
    final lonDistance = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final a = math.sin(latDistance / 2) * math.sin(latDistance / 2) +
        math.sin(lonDistance / 2) *
            math.sin(lonDistance / 2) *
            math.cos(lat1Rad) *
            math.cos(lat2Rad);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    final latest = _displayLocation;
    final mapCenter = latest == null
        ? _fallbackCenter
        : LatLng(latest.latitude, latest.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.background,
        actions: [
          if (_isLoadingPlayback)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: _isPlaybackMode ? 'Exit playback mode' : 'Enter playback mode',
            onPressed: _isLoadingPlayback ? null : _togglePlaybackMode,
            icon: Icon(_isPlaybackMode ? Icons.timeline : Icons.replay),
          ),
          if (_isReconnecting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: mapCenter,
              zoom: 14,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              controller.setMapStyle(_purpleMapStyle);
            },
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildStatusCard(context),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final latest = _displayLocation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _isReconnecting ? AppColors.warning : AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isPlaybackMode
                    ? 'Playback mode active'
                    : (_isReconnecting ? 'Reconnecting...' : 'Realtime tracking connected'),
                style: AppTypography.title.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Text(
              _error!,
              style: AppTypography.body.copyWith(
                color: AppColors.danger,
                fontSize: 13,
              ),
            )
          else if (latest == null)
            Text(
              'Waiting for driver location updates...',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPlaybackMode
                      ? 'Playback point ${_playbackIndex + 1}/${_playbackPoints.length}'
                      : 'ETA: ${_buildEtaText(latest)}',
                  style: AppTypography.title.copyWith(
                    fontSize: 16,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildSummaryText(latest, context),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (_isPlaybackMode && _playbackPoints.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Slider(
                    min: 0,
                    max: (_playbackPoints.length - 1).toDouble(),
                    value: _playbackIndex.toDouble().clamp(0, (_playbackPoints.length - 1).toDouble()),
                    onChanged: (value) {
                      final targetIndex = value.round();
                      setState(() {
                        _playbackIndex = targetIndex;
                      });
                      _animateTo(_playbackPoints[targetIndex]);
                    },
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _togglePlaybackRunning,
                        icon: Icon(_isPlayingPlayback ? Icons.pause : Icons.play_arrow),
                        label: Text(_isPlayingPlayback ? 'Pause' : 'Play'),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        TimeOfDay.fromDateTime(
                          _playbackPoints[_playbackIndex].recordedAt.toLocal(),
                        ).format(context),
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_geofenceEvents.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _buildGeofenceSummary(context),
                    style: AppTypography.body.copyWith(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  String _buildGeofenceSummary(BuildContext context) {
    final latestEvent = _geofenceEvents.first;
    final timeLabel = TimeOfDay.fromDateTime(latestEvent.recordedAt.toLocal()).format(context);
    final label = latestEvent.label == 'school' ? 'School' : latestEvent.label == 'pickup' ? 'Pickup' : 'Stop';
    final action = latestEvent.eventType == 'reached'
        ? 'reached'
        : latestEvent.eventType == 'entered'
            ? 'entered'
            : 'exited';

    return 'Latest checkpoint: $label $action at $timeLabel';
  }

  String _buildSummaryText(LiveTripLocation latest, BuildContext context) {
    final recordedLocal = latest.recordedAt.toLocal();
    final timeLabel = TimeOfDay.fromDateTime(recordedLocal).format(context);
    final speed = latest.speedKmh;

    if (_isPlaybackMode) {
      if (speed == null) {
        return 'Playback • Phase: ${latest.tripPhase} • Time: $timeLabel';
      }
      return 'Playback • Phase: ${latest.tripPhase} • ${speed.toStringAsFixed(1)} km/h • Time: $timeLabel';
    }

    if (speed == null) {
      return 'Phase: ${latest.tripPhase} • Updated at $timeLabel';
    }

    return 'Phase: ${latest.tripPhase} • ${speed.toStringAsFixed(1)} km/h • Updated at $timeLabel';
  }
}
