class MessageThread {
  const MessageThread({
    required this.id,
    required this.name,
    required this.snippet,
    required this.time,
    required this.unread,
    required this.tags,
    required this.messages,
  });

  final String id;
  final String name;
  final String snippet;
  final String time;
  final bool unread;
  final List<String> tags;
  final List<Message> messages;
}

class Message {
  const Message({
    required this.sender,
    required this.body,
    required this.time,
    this.isParent = true,
  });

  final String sender;
  final String body;
  final String time;
  final bool isParent;
}
