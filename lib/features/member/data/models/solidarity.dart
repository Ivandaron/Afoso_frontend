class SolidarityFund {
  final int id;
  final String title;
  final String? description;
  final double targetAmount;
  final double contributionAmount;
  final double collectedAmount;
  final String status; // ACTIVE | CLOSED | DISBURSED
  final String? beneficiaryName;
  final String? beneficiaryReason;
  final String createdAt;
  final int contributionCount;
  final bool? hasContributed;

  SolidarityFund({
    required this.id,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.contributionAmount,
    required this.collectedAmount,
    required this.status,
    this.beneficiaryName,
    this.beneficiaryReason,
    required this.createdAt,
    this.contributionCount = 0,
    this.hasContributed,
  });

  factory SolidarityFund.fromJson(Map<String, dynamic> json) {
    return SolidarityFund(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      contributionAmount:
          (json['contributionAmount'] as num?)?.toDouble() ?? 0.0,
      collectedAmount: (json['collectedAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ACTIVE',
      beneficiaryName: json['beneficiaryName'] as String?,
      beneficiaryReason: json['beneficiaryReason'] as String?,
      createdAt: json['createdAt']?.toString() ?? '',
      contributionCount: (json['contributionCount'] as num?)?.toInt() ?? 0,
      hasContributed: json['hasContributed'] as bool?,
    );
  }

  bool get isActive => status == 'ACTIVE';
  double get progressPercent =>
      targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
}

class SolidarityContribution {
  final int id;
  final double amount;
  final String paymentPhone;
  final String paymentMethod;
  final String? transactionReference;

  SolidarityContribution({
    required this.id,
    required this.amount,
    required this.paymentPhone,
    required this.paymentMethod,
    this.transactionReference,
  });

  factory SolidarityContribution.fromJson(Map<String, dynamic> json) {
    return SolidarityContribution(
      id: (json['id'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentPhone: json['paymentPhone'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      transactionReference: json['transactionReference'] as String?,
    );
  }
}

class ContributeSolidarityRequest {
  final String paymentPhone;
  final String paymentMethod;

  ContributeSolidarityRequest({
    required this.paymentPhone,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    'paymentPhone': paymentPhone,
    'paymentMethod': paymentMethod,
  };
}
