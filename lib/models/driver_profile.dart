class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
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
  final String phone;
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

    // Safely extract names depending on which API endpoint is calling this
    final rawName =
        (json['driverName'] as String? ?? json['name'] as String? ?? 'Driver')
            .trim();

    // ✅ CRITICAL FIX: Safely parse ID even if the backend returns null or uses 'driverId'
    final idStr = (json['id'] ?? json['driverId'] ?? '').toString();

    // Map invite-code specific payload to your standard model properties
    final vehicleMake = json['vehicleMake'] as String? ?? '';
    final vehicleModel = json['vehicleModel'] as String? ?? '';
    final vehicleTypeStr =
        json['vehicleType'] as String? ??
        (vehicleMake.isNotEmpty ? '$vehicleMake $vehicleModel'.trim() : 'Van');

    final city = json['city'] as String? ?? '';
    final district = json['district'] as String? ?? '';
    final routeStr =
        json['route'] as String? ??
        (city.isNotEmpty
            ? '${city.trim()}, ${district.trim()}'.replaceAll(
                RegExp(r'^,\s*'),
                '',
              )
            : 'Daily route');

    return DriverProfile(
      id: idStr,
      name: rawName.isEmpty ? 'Driver' : rawName,
      phone: json['driverPhone'] as String? ?? json['phone'] as String? ?? '',
      vehicleType: vehicleTypeStr,
      route: routeStr,
      price: _toDouble(json['price']),
      distance: _toDouble(json['distance']),
      rating: _toDouble(json['rating'], fallback: 5),
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      vehicleImageUrl: json['vehicleImageUrl'] as String? ?? '',
      tags: rawTags is List
          ? rawTags.whereType<String>().toList()
          : const <String>[],
    );
  }

  DriverProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? vehicleType,
    String? route,
    double? price,
    double? distance,
    double? rating,
    int? seats,
    String? vehicleImageUrl,
    List<String>? tags,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      route: route ?? this.route,
      price: price ?? this.price,
      distance: distance ?? this.distance,
      rating: rating ?? this.rating,
      seats: seats ?? this.seats,
      vehicleImageUrl: vehicleImageUrl ?? this.vehicleImageUrl,
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
