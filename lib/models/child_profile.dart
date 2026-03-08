import 'package:flutter/material.dart';

enum AttendanceState { coming, notComing, pending }

enum PaymentStatus { paid, due, overdue }

extension AttendanceStateApi on AttendanceState {
  String get apiValue {
    switch (this) {
      case AttendanceState.coming:
        return 'coming';
      case AttendanceState.notComing:
        return 'not_coming';
      case AttendanceState.pending:
        return 'pending';
    }
  }

  static AttendanceState fromString(String value) {
    switch (value) {
      case 'not_coming':
        return AttendanceState.notComing;
      case 'pending':
        return AttendanceState.pending;
      default:
        return AttendanceState.coming;
    }
  }
}

extension PaymentStatusApi on PaymentStatus {
  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'due':
        return PaymentStatus.due;
      case 'overdue':
        return PaymentStatus.overdue;
      default:
        return PaymentStatus.paid;
    }
  }
}

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.school,
    required this.pickupLocation,
    required this.pickupTime,
    required this.attendance,
    required this.paymentStatus,
    required this.avatarColor,
    this.linkedDriverId,
    // NEW FIELDS
    this.age,
    this.dropLocation,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.etaSchool,
    this.emergencyContact,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String school;
  final String pickupLocation;
  final String pickupTime;
  final AttendanceState attendance;
  final PaymentStatus paymentStatus;
  final Color avatarColor;
  final String? linkedDriverId;

  // NEW FIELDS
  final int? age;
  final String? dropLocation;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final String? etaSchool;
  final String? emergencyContact;
  final String? description;
  final String? imageUrl;

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    final name =
        (json['child_name'] as String? ?? json['childName'] as String? ?? '')
            .trim();
    return ChildProfile(
      id: json['id'] as String? ?? '',
      name: name.isEmpty ? 'Student' : name,
      school: json['school'] as String? ?? 'Unknown school',
      pickupLocation:
          json['pickup_location'] as String? ??
          json['pickupLocation'] as String? ??
          'Pickup spot',
      pickupTime:
          json['pickup_time'] as String? ??
          json['pickupTime'] as String? ??
          '06:45 AM',
      attendance: AttendanceStateApi.fromString(
        json['attendance_state'] as String? ??
            json['attendance'] as String? ??
            'coming',
      ),
      paymentStatus: PaymentStatusApi.fromString(
        json['payment_status'] as String? ??
            json['paymentStatus'] as String? ??
            'paid',
      ),
      avatarColor: _colorFromName(name),
      linkedDriverId: json['linked_driver_id'],

      // NEW PARSING LOGIC
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      dropLocation:
          json['drop_location'] as String? ?? json['dropLocation'] as String?,
      pickupLat: json['pickup_lat'] != null
          ? (json['pickup_lat'] as num).toDouble()
          : null,
      pickupLng: json['pickup_lng'] != null
          ? (json['pickup_lng'] as num).toDouble()
          : null,
      dropLat: json['drop_lat'] != null
          ? (json['drop_lat'] as num).toDouble()
          : null,
      dropLng: json['drop_lng'] != null
          ? (json['drop_lng'] as num).toDouble()
          : null,
      etaSchool: json['eta_school'] as String? ?? json['etaSchool'] as String?,
      emergencyContact:
          json['emergency_contact'] as String? ??
          json['emergencyContact'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  ChildProfile copyWith({
    AttendanceState? attendance,
    PaymentStatus? paymentStatus,
    String? linkedDriverId,
    int? age,
    String? dropLocation,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    String? etaSchool,
    String? emergencyContact,
    String? description,
    String? imageUrl,
  }) {
    return ChildProfile(
      id: id,
      name: name,
      school: school,
      pickupLocation: pickupLocation,
      pickupTime: pickupTime,
      attendance: attendance ?? this.attendance,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      avatarColor: avatarColor,
      linkedDriverId: linkedDriverId ?? this.linkedDriverId,

      // NEW COPY LOGIC
      age: age ?? this.age,
      dropLocation: dropLocation ?? this.dropLocation,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      etaSchool: etaSchool ?? this.etaSchool,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static Color _colorFromName(String name) {
    if (name.isEmpty) {
      return Colors.blueGrey.shade400;
    }
    final codeUnits = name.codeUnits;
    final hash = codeUnits.fold<int>(0, (acc, unit) => acc + unit);
    final palette = Colors.primaries;
    final color = palette[hash % palette.length];
    return color.shade400;
  }
}
