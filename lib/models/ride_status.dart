class RideTimelineStep {
  const RideTimelineStep({required this.label, required this.completed});

  final String label;
  final bool completed;

  factory RideTimelineStep.fromJson(Map<String, dynamic> json) {
    final label = (json['label'] as String? ?? '').trim();
    return RideTimelineStep(
      label: label.isEmpty ? 'Status update' : label,
      completed: json['completed'] as bool? ?? false,
    );
  }

  static List<RideTimelineStep> fromJsonList(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(RideTimelineStep.fromJson)
          .toList();
    }
    return const <RideTimelineStep>[];
  }
}

class RideStatus {
  const RideStatus({
    required this.etaMinutes,
    required this.vehiclePlate,
    required this.speedKph,
    required this.timeline,
    this.driverName,
    this.delayReason,
  });

  final int etaMinutes;
  final String vehiclePlate;
  final int speedKph;
  final List<RideTimelineStep> timeline;
  final String? driverName;
  final String? delayReason;

  factory RideStatus.fromJson(Map<String, dynamic> json) {
    return RideStatus(
      etaMinutes: _asInt(json['eta_minutes'] ?? json['etaMinutes'], 0),
      vehiclePlate: (json['vehicle_plate'] ?? json['vehiclePlate'] ?? 'UNKNOWN') as String,
      speedKph: _asInt(json['speed_kph'] ?? json['speedKph'], 0),
      timeline: RideTimelineStep.fromJsonList(json['timeline']),
      driverName: json['driver_name'] as String? ?? json['driverName'] as String?,
      delayReason: json['delay_reason'] as String? ?? json['delayReason'] as String?,
    );
  }

  const RideStatus.placeholder()
      : etaMinutes = 8,
        vehiclePlate = 'SP-2045',
        speedKph = 34,
        timeline = const <RideTimelineStep>[
          RideTimelineStep(label: 'Departed yard', completed: true),
          RideTimelineStep(label: 'Pickup stop', completed: true),
          RideTimelineStep(label: 'En route', completed: true),
          RideTimelineStep(label: 'Approaching school', completed: false),
        ],
        driverName = 'Chamath',
        delayReason = null;

  RideStatus copyWith({
    int? etaMinutes,
    String? vehiclePlate,
    int? speedKph,
    List<RideTimelineStep>? timeline,
    String? driverName,
    String? delayReason,
  }) {
    return RideStatus(
      etaMinutes: etaMinutes ?? this.etaMinutes,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      speedKph: speedKph ?? this.speedKph,
      timeline: timeline ?? this.timeline,
      driverName: driverName ?? this.driverName,
      delayReason: delayReason ?? this.delayReason,
    );
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}
