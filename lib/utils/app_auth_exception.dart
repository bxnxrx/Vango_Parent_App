class AppAuthException implements Exception {
  final String code;
  final String message;

  AppAuthException({required this.code, required this.message});

  @override
  String toString() => message;
}
