enum PaymentState { success, pending, failed }

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.state,
    required this.method,
  });

  final String id;
  final String title;
  final double amount;
  final String date;
  final PaymentState state;
  final String method;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Payment',
      amount: _toDouble(json['amount']),
      date: json['date'] as String? ?? json['created_at'] as String? ?? '',
      state: _stateFromString(json['state'] as String? ?? json['status'] as String? ?? 'success'),
      method: json['method'] as String? ?? 'Card',
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static PaymentState _stateFromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PaymentState.pending;
      case 'failed':
      case 'error':
        return PaymentState.failed;
      default:
        return PaymentState.success;
    }
  }
}
