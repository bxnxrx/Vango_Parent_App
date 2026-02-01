class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.route,
    required this.price,
    required this.distance,
    required this.rating,
    required this.seats,
    required this.vehicleImageUrl,
    this.tags = const <String>[],
  });

  final String id;
  final String name;
  final String vehicleType;
  final String route;
  final double price;
  final double distance;
  final double rating;
  final int seats;
  final String vehicleImageUrl;
  final List<String> tags;

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final rawName = (json['driverName'] as String? ?? 'Driver').trim();
    return DriverProfile(
      id: json['id'] as String,
      name: rawName.isEmpty ? 'Driver' : rawName,
      vehicleType: json['vehicleType'] as String? ?? 'Van',
      route: json['route'] as String? ?? 'Daily route',
      price: _toDouble(json['price']),
      distance: _toDouble(json['distance']),
      rating: _toDouble(json['rating'], fallback: 5),
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      vehicleImageUrl: json['vehicleImageUrl'] as String? ?? '',
      tags: rawTags is List ? rawTags.whereType<String>().toList() : const <String>[],
    );
  }

  DriverProfile copyWith({List<String>? tags}) {
    return DriverProfile(
      id: id,
      name: name,
      vehicleType: vehicleType,
      route: route,
      price: price,
      distance: distance,
      rating: rating,
      seats: seats,
      vehicleImageUrl: vehicleImageUrl,
      tags: tags ?? this.tags,
    );
  }

  static double _toDouble(Object? value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}
