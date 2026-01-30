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
}
