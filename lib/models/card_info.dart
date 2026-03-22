class CardInfo {
  final String id;
  final String cardNo;
  final String cardType;
  final String cardExpiry;
  final bool isDefault;

  CardInfo({
    required this.id,
    required this.cardNo,
    required this.cardType,
    required this.cardExpiry,
    required this.isDefault,
  });

  factory CardInfo.fromJson(Map<String, dynamic> json) {
    // Mask logic: take last 4 digits from "************1292"
    String lastFour = json['card_no'].toString().length >= 4
        ? json['card_no'].toString().substring(
            json['card_no'].toString().length - 4,
          )
        : "****";

    return CardInfo(
      id: json['id'],
      cardNo: "**** $lastFour",
      cardType: json['card_type'] ?? 'VISA',
      cardExpiry: json['card_expiry'] ?? '--/--',
      isDefault: json['is_default'] ?? false,
    );
  }
}
