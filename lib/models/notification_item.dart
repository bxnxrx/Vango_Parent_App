enum NotificationCategory { ride, payment, safety }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      category: _parseCategory(json['category'] as String? ?? 'ride'),
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      read: (json['read_at'] as String?) != null,
    );
  }

  String get relativeTime {
    final now = DateTime.now();
    final delta = now.difference(createdAt);
    if (delta.inMinutes < 1) {
      return 'Just now';
    }
    if (delta.inMinutes < 60) {
      return '${delta.inMinutes}m ago';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours}h ago';
    }
    return '${delta.inDays}d ago';
  }

  static NotificationCategory _parseCategory(String value) {
    switch (value) {
      case 'payment':
        return NotificationCategory.payment;
      case 'safety':
        return NotificationCategory.safety;
      default:
        return NotificationCategory.ride;
    }
  }
}
