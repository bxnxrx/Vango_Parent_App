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
    // NEW FIELDS BELOW
    this.age,
    this.dropLocation,
    this.etaSchool,
    this.emergencyContact,
    this.description,
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

  // NEW FIELDS BELOW
  final int? age;
  final String? dropLocation;
  final String? etaSchool;
  final String? emergencyContact;
  final String? description;

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    final name = (json['child_name'] as String? ?? '').trim();
    return ChildProfile(
      id: json['id'] as String,
      name: name.isEmpty ? 'Student' : name,
      school: json['school'] as String? ?? 'Unknown school',
      pickupLocation: json['pickup_location'] as String? ?? 'Pickup spot',
      pickupTime: json['pickup_time'] as String? ?? '06:45 AM',
      attendance: AttendanceStateApi.fromString(
        json['attendance_state'] as String? ?? 'coming',
      ),
      paymentStatus: PaymentStatusApi.fromString(
        json['payment_status'] as String? ?? 'paid',
      ),
      avatarColor: _colorFromName(name),
      linkedDriverId: json['linked_driver_id'],

      // NEW PARSING LOGIC BELOW
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      dropLocation: json['drop_location'] as String?,
      etaSchool: json['eta_school'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      description: json['description'] as String?,
    );
  }

  ChildProfile copyWith({
    AttendanceState? attendance,
    PaymentStatus? paymentStatus,
    String? linkedDriverId,
    int? age,
    String? dropLocation,
    String? etaSchool,
    String? emergencyContact,
    String? description,
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

      // NEW COPY LOGIC BELOW
      age: age ?? this.age,
      dropLocation: dropLocation ?? this.dropLocation,
      etaSchool: etaSchool ?? this.etaSchool,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      description: description ?? this.description,
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
