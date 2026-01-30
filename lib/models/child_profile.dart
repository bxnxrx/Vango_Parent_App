import 'package:flutter/material.dart';

enum AttendanceState { coming, notComing, pending }

enum PaymentStatus { paid, due, overdue }

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.school,
    required this.pickupTime,
    required this.avatarColor,
    this.attendance = AttendanceState.coming,
    this.paymentStatus = PaymentStatus.paid,
  });

  final String id;
  final String name;
  final String school;
  final String pickupTime;
  final Color avatarColor;
  final AttendanceState attendance;
  final PaymentStatus paymentStatus;

  ChildProfile copyWith({
    AttendanceState? attendance,
    PaymentStatus? paymentStatus,
  }) {
    return ChildProfile(
      id: id,
      name: name,
      school: school,
      pickupTime: pickupTime,
      avatarColor: avatarColor,
      attendance: attendance ?? this.attendance,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
