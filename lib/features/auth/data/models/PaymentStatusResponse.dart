/// Statut du paiement — GET /registration/payment/status/{ref}
class PaymentStatusResponse {
  final String status; // PENDING | SUCCESS | FAILURE
  final String transactionReference;
  final int? memberId;
  final String? failureReason;

  PaymentStatusResponse({
    required this.status,
    required this.transactionReference,
    this.memberId,
    this.failureReason,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      status: json['status'] as String? ?? 'PENDING',
      transactionReference: json['transactionReference'] as String? ?? '',
      memberId: json['memberId'] as int?,
      failureReason: json['failureReason'] as String?,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isSuccess => status == 'SUCCESS';
  bool get isFailure => status == 'FAILURE';
}

/// Méthodes de paiement disponibles
enum PaymentMethod {
  campay('CAMPAY', 'Campay', '💰'),
  orangeMoney('ORANGE_MONEY', 'Orange Money', '🟠'),
  mtnMoney('MOBILE_MONEY', 'MTN Money', '🟡'),
  moovMoney('MOOV_MONEY', 'Moov Money', '🔵');

  final String value;
  final String label;
  final String emoji;

  const PaymentMethod(this.value, this.label, this.emoji);
}
