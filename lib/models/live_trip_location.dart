class LiveTripLocation {
  const LiveTripLocation({
    required this.tripId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.tripPhase,
    this.speedKmh,
    this.heading,
    this.accuracyM,
  });

  final String tripId;
  final String driverId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final String tripPhase;
  final double? speedKmh;
  final double? heading;
  final double? accuracyM;

  factory LiveTripLocation.fromJson(Map<String, dynamic> json) {
    return LiveTripLocation(
      tripId: (json['tripId'] ?? '').toString(),
      driverId: (json['driverId'] ?? '').toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      speedKmh: _toNullableDouble(json['speedKmh']),
      heading: _toNullableDouble(json['heading']),
      accuracyM: _toNullableDouble(json['accuracyM']),
      tripPhase: (json['tripPhase'] ?? 'idle').toString(),
      recordedAt: DateTime.tryParse((json['recordedAt'] ?? '').toString()) ?? DateTime.now(),
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
