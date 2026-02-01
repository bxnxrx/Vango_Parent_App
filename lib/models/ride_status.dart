class RideTimelineStep {
  const RideTimelineStep({required this.label, required this.completed});

  final String label;
  final bool completed;
}

class RideStatus {
  const RideStatus({
    required this.etaMinutes,
    required this.vehiclePlate,
    required this.speedKph,
    required this.timeline,
  });

  final int etaMinutes;
  final String vehiclePlate;
  final int speedKph;
  final List<RideTimelineStep> timeline;

  const RideStatus.placeholder()
      : etaMinutes = 8,
        vehiclePlate = 'SP-2045',
        speedKph = 34,
        timeline = const <RideTimelineStep>[
          RideTimelineStep(label: 'Departed yard', completed: true),
          RideTimelineStep(label: 'Pickup stop', completed: true),
          RideTimelineStep(label: 'En route', completed: true),
          RideTimelineStep(label: 'Approaching school', completed: false),
        ];
}
