class RideTimelineStep {
  // Removed const constructor
  RideTimelineStep({
    required this.label,
    required this.time,
    required this.completed,
  });

  final String label;
  final String time;
  final bool completed;
}

class RideStatus {
  // Removed const constructor
  RideStatus({
    required this.driverName,
    required this.vehiclePlate,
    required this.speedKph,
    required this.etaMinutes,
    required this.timeline,
    this.delayReason,
  });

  final String driverName;
  final String vehiclePlate;
  final int speedKph;
  final int etaMinutes;
  final List<RideTimelineStep> timeline;
  final String? delayReason;
}
