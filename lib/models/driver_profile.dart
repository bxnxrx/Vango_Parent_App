class DriverProfile {
  const DriverProfile({
    required this.name,
    required this.rating,
    required this.distance,
    required this.seats,
    required this.price,
    required this.tags,
    required this.route,
    required this.badges,
    required this.vehicleType,
    required this.vehicleImageUrl,
  });

  final String name;
  final double rating;
  final double distance;
  final int seats;
  final int price;
  final String route;
  final List<String> tags;
  final List<String> badges;
  final String vehicleType;
  final String vehicleImageUrl;
}
