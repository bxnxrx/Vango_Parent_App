import 'package:flutter/material.dart';

import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/driver_profile.dart';
import 'package:vango_parent_app/models/message_thread.dart';
import 'package:vango_parent_app/models/notification_item.dart';
import 'package:vango_parent_app/models/payment_record.dart';
import 'package:vango_parent_app/models/ride_status.dart';

class MockData {
  // Removing const to look more like dynamic data
  static List<ChildProfile> children = [
    ChildProfile(
      id: 'c1',
      name: 'Kavya',
      school: 'Golden International',
      pickupTime: '6:55 AM',
      avatarColor: Color(0xFF7AB6FF),
      attendance: AttendanceState.coming,
      paymentStatus: PaymentStatus.paid,
    ),
    ChildProfile(
      id: 'c2',
      name: 'Niwath',
      school: 'Royal Primary',
      pickupTime: '7:05 AM',
      avatarColor: Color(0xFFB78CFF),
      attendance: AttendanceState.coming,
      paymentStatus: PaymentStatus.due,
    ),
  ];

  static RideStatus ride = RideStatus(
    driverName: 'Chamath Perera',
    vehiclePlate: 'WP NC-4521',
    speedKph: 32,
    etaMinutes: 5,
    delayReason: null,
    timeline: [
      RideTimelineStep(label: 'Trip started', time: '6:40 AM', completed: true),
      RideTimelineStep(label: 'En route', time: '6:52 AM', completed: true),
      RideTimelineStep(label: '5 mins away', time: 'Now', completed: false),
      RideTimelineStep(label: 'Arrived', time: '7:01 AM', completed: false),
      RideTimelineStep(label: 'Dropped', time: '7:25 AM', completed: false),
    ],
  );

  static List<NotificationItem> notifications = [
    NotificationItem(
      title: 'Van 5 minutes away',
      body: 'Chamath marked a brief traffic slowdown.',
      timeAgo: 'Just now',
      category: NotificationCategory.ride,
    ),
    NotificationItem(
      title: 'Payment due soon',
      body: 'March tuition is due in 3 days.',
      timeAgo: '2h',
      category: NotificationCategory.payment,
    ),
    NotificationItem(
      title: 'Safety drill complete',
      body: 'Seat belt check logged for Route A.',
      timeAgo: 'Yesterday',
      category: NotificationCategory.safety,
    ),
  ];

  static List<DriverProfile> finderDrivers = [
    DriverProfile(
      name: 'Ishan Fernando',
      rating: 4.9,
      distance: 1.2,
      seats: 2,
      price: 18000,
      route: 'St. Peters / Bambalapitiya',
      tags: ['Verified', 'GPS enabled', 'CPR certified'],
      badges: ['Tracker', 'Insurance'],
      vehicleType: 'Van',
      vehicleImageUrl:
          'https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?auto=format&fit=crop&w=900&q=60',
    ),
    DriverProfile(
      name: 'Nilmini de Silva',
      rating: 4.7,
      distance: 2.0,
      seats: 4,
      price: 16500,
      route: 'Musaeus / Colombo 7',
      tags: ['Female driver', 'New seats'],
      badges: ['Verified'],
      vehicleType: 'Car',
      vehicleImageUrl:
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=900&q=60',
    ),
    DriverProfile(
      name: 'Akila Madushanka',
      rating: 4.8,
      distance: 3.6,
      seats: 8,
      price: 21000,
      route: 'Gateway / Nugegoda',
      tags: ['Mini bus', 'Seat belts'],
      badges: ['Verified', 'Tracker'],
      vehicleType: 'Mini Bus',
      vehicleImageUrl:
          'https://images.unsplash.com/photo-1529429617124-aee711a70412?auto=format&fit=crop&w=900&q=60',
    ),
  ];

  static List<PaymentRecord> payments = [
    PaymentRecord(
      id: 'p1',
      title: 'February fees',
      amount: 16500,
      date: '02 Mar 2025',
      state: PaymentState.success,
      method: 'Visa • 4521',
    ),
    PaymentRecord(
      id: 'p2',
      title: 'Snacks contribution',
      amount: 2500,
      date: '18 Feb 2025',
      state: PaymentState.pending,
      method: 'Cash',
    ),
    PaymentRecord(
      id: 'p3',
      title: 'January fees',
      amount: 16000,
      date: '03 Jan 2025',
      state: PaymentState.success,
      method: 'Visa • 4521',
    ),
  ];

  static List<MessageThread> threads = [
    MessageThread(
      id: 'm1',
      name: 'Chamath (Route A)',
      snippet: 'Leaving in 10 min. Please be ready.',
      time: '06:20',
      unread: true,
      tags: ['Route A'],
      messages: [
        Message(
          sender: 'Chamath',
          body: 'Leaving in 10 min. Please be ready.',
          time: '06:20',
          isParent: false,
        ),
        Message(sender: 'You', body: 'Thanks, noted!', time: '06:21'),
      ],
    ),
    MessageThread(
      id: 'm2',
      name: 'EduRide Support',
      snippet: 'Your payment receipt is ready.',
      time: 'Yesterday',
      unread: false,
      tags: ['Support'],
      messages: [
        Message(
          sender: 'Support',
          body: 'Your receipt is attached.',
          time: '16:20',
          isParent: false,
        ),
        Message(sender: 'You', body: 'Received, thank you!', time: '16:22'),
      ],
    ),
  ];
}