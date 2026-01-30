enum NotificationCategory { ride, payment, safety }

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.category,
  });

  final String title;
  final String body;
  final String timeAgo;
  final NotificationCategory category;
}
