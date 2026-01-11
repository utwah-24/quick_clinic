class PaymentMethodDetails {
  final String id;
  final String type; // 'credit_card' or 'nida'
  final String? bankName;
  final String? cardNumber;
  final String? cardHolderName;
  final String? expiryDate;
  final String? cvv;
  final String? nidaNumber;
  final DateTime createdAt;
  final bool isDefault;

  PaymentMethodDetails({
    required this.id,
    required this.type,
    this.bankName,
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.cvv,
    this.nidaNumber,
    required this.createdAt,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'bankName': bankName,
        'cardNumber': cardNumber,
        'cardHolderName': cardHolderName,
        'expiryDate': expiryDate,
        'cvv': cvv,
        'nidaNumber': nidaNumber,
        'createdAt': createdAt.toIso8601String(),
        'isDefault': isDefault,
      };

  factory PaymentMethodDetails.fromJson(Map<String, dynamic> json) {
    return PaymentMethodDetails(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      bankName: json['bankName']?.toString(),
      cardNumber: json['cardNumber']?.toString(),
      cardHolderName: json['cardHolderName']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      cvv: json['cvv']?.toString(),
      nidaNumber: json['nidaNumber']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isDefault: json['isDefault'] == true,
    );
  }

  // Mask card number for display (show only last 4 digits)
  String get maskedCardNumber {
    if (cardNumber == null || cardNumber!.isEmpty) return '';
    final cleaned = cardNumber!.replaceAll(' ', '');
    if (cleaned.length < 4) return cardNumber!;
    return '**** **** **** ${cleaned.substring(cleaned.length - 4)}';
  }

  String get displayName {
    if (type == 'credit_card') {
      return '${bankName ?? "Card"} • ${maskedCardNumber}';
    } else if (type == 'nida') {
      return 'NIDA • ${nidaNumber ?? "N/A"}';
    }
    return 'Payment Method';
  }
}






















