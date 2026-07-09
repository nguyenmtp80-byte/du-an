class PaymentInfo {
  const PaymentInfo({
    required this.orderId,
    required this.paymentMethod,
    required this.status,
    required this.amount,
    required this.instructions,
  });

  final String orderId;
  final String paymentMethod;
  final String status;
  final int amount;
  final String instructions;

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      orderId: json['orderId']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount: _parseAmount(json['amount']),
      instructions: json['instructions']?.toString() ?? '',
    );
  }

  static int _parseAmount(Object? value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value.toString()) ?? 0;
  }
}

class PaymentQr {
  const PaymentQr({
    required this.orderId,
    required this.amount,
    required this.bankCode,
    required this.bankAccountNumber,
    required this.bankAccountName,
    required this.content,
    required this.referenceCode,
    required this.qrDataUrl,
    required this.status,
  });

  final String orderId;
  final int amount;
  final String bankCode;
  final String bankAccountNumber;
  final String bankAccountName;
  final String content;
  final String referenceCode;
  final String qrDataUrl;
  final String status;

  factory PaymentQr.fromJson(Map<String, dynamic> json) {
    return PaymentQr(
      orderId: json['orderId']?.toString() ?? '',
      amount: PaymentInfo._parseAmount(json['amount']),
      bankCode: json['bankCode']?.toString() ?? '',
      bankAccountNumber: json['bankAccountNumber']?.toString() ?? '',
      bankAccountName: json['bankAccountName']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      referenceCode: json['referenceCode']?.toString() ?? '',
      qrDataUrl: json['qrDataUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

String formatBankName(String bankCode) {
  switch (bankCode) {
    case '970422':
      return 'MB Bank';
    case '970436':
      return 'Vietcombank';
    case '970407':
      return 'Techcombank';
    default:
      return bankCode;
  }
}
