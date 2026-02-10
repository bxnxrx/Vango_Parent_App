class MessageThread {
  const MessageThread({
    required this.id,
    required this.name,
    required this.snippet,
    required this.lastActivity,
    required this.unreadCount,
  });

  final String id;
  final String name;
  final String snippet;
  final DateTime lastActivity;
  final int unreadCount;

  bool get unread => unreadCount > 0;

  String get timeLabel {
    final now = DateTime.now();
    final delta = now.difference(lastActivity);
    if (delta.inMinutes < 1) {
      return 'now';
    }
    if (delta.inMinutes < 60) {
      return '${delta.inMinutes}m';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours}h';
    }
    return '${delta.inDays}d';
  }

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    return MessageThread(
      id: json['id'] as String,
      name: json['title'] as String? ?? 'Route chat',
      snippet: json['last_message'] as String? ?? 'Start chatting with your driver',
      lastActivity: DateTime.tryParse(json['last_activity'] as String? ?? '') ?? DateTime.now(),
      unreadCount: (json['unread_parent_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class Message {
  const Message({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.isParent,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final bool isParent;

  String get timeLabel {
    final hours = createdAt.hour.toString().padLeft(2, '0');
    final minutes = createdAt.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      isParent: (json['sender_type'] as String? ?? 'parent') == 'parent',
    );
  }
}
