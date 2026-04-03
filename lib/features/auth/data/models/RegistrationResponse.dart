/// Réponse de /registration/submit → RegistrationResponseDTO
class RegistrationResponse {
  final int id;
  final String status;
  final String? transactionReference;
  final String? externalReference;
  final double? registrationFee;

  RegistrationResponse({
    required this.id,
    required this.status,
    this.transactionReference,
    this.externalReference,
    this.registrationFee,
  });

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'PENDING',
      transactionReference: json['transactionReference'] as String?,
      externalReference: json['externalReference'] as String?,
      registrationFee: (json['registrationFee'] as num?)?.toDouble(),
    );
  }
}
