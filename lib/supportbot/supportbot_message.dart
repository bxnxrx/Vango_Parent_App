class SupportbotMessage {
  const SupportbotMessage({
    required this.id,
    required this.role,
    required this.content,
  });

  final String id;
  final String role;
  final String content;

  bool get isUser => role == 'user';
}