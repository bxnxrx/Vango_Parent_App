class TripGeofenceEvent {
  const TripGeofenceEvent({
    required this.id,
    required this.pointId,
    required this.tripId,
    required this.driverId,
    required this.label,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.distanceM,
  });

  final String id;
  final String pointId;
  final String tripId;
  final String driverId;
  final String label;
  final String eventType;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double? distanceM;

  factory TripGeofenceEvent.fromJson(Map<String, dynamic> json) {
    return TripGeofenceEvent(
      id: (json['id'] ?? '').toString(),
      pointId: (json['pointId'] ?? '').toString(),
      tripId: (json['tripId'] ?? '').toString(),
      driverId: (json['driverId'] ?? '').toString(),
      label: (json['label'] ?? 'custom').toString(),
      eventType: (json['eventType'] ?? 'entered').toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      recordedAt: DateTime.tryParse((json['recordedAt'] ?? '').toString()) ?? DateTime.now(),
      distanceM: _toNullableDouble(json['distanceM']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
