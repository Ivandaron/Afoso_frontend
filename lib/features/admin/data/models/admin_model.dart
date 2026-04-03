class DashboardStats {
  final double totalDeposits;
  final int activeMembers;
  final int pendingRegistrations;
  final int failedTransactions;
  final int totalLoans;
  final double totalLoanAmount;
  final double
  totalRegistrationFees; // depuis /registration-fees/total (montant réel)

  DashboardStats({
    required this.totalDeposits,
    required this.activeMembers,
    required this.pendingRegistrations,
    required this.failedTransactions,
    required this.totalLoans,
    required this.totalLoanAmount,
    this.totalRegistrationFees = 0.0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalDeposits: (json['totalDeposits'] as num?)?.toDouble() ?? 0.0,
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
      pendingRegistrations:
          (json['pendingRegistrations'] as num?)?.toInt() ?? 0,
      failedTransactions: (json['failedTransactions'] as num?)?.toInt() ?? 0,
      totalLoans: (json['totalLoans'] as num?)?.toInt() ?? 0,
      totalLoanAmount: (json['totalLoanAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  DashboardStats withRegistrationFees(double fees) => DashboardStats(
    totalDeposits: totalDeposits,
    activeMembers: activeMembers,
    pendingRegistrations: pendingRegistrations,
    failedTransactions: failedTransactions,
    totalLoans: totalLoans,
    totalLoanAmount: totalLoanAmount,
    totalRegistrationFees: fees,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RÉSUMÉ FINANCIER PAR PÉRIODE — /financial-overview/period
// ─────────────────────────────────────────────────────────────────────────────
class PeriodOverview {
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final double totalMonthlyPayments; // cotisations mensuelles
  final double totalRegistrationPayments; // frais d'inscription sur la période
  final int newMembers;

  PeriodOverview({
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.totalMonthlyPayments,
    required this.totalRegistrationPayments,
    required this.newMembers,
  });

  factory PeriodOverview.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? {};
    return PeriodOverview(
      startDate:
          DateTime.tryParse(period['start']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(period['end']?.toString() ?? '') ?? DateTime.now(),
      days: (json['days'] as num?)?.toInt() ?? 0,
      totalMonthlyPayments:
          (json['totalMonthlyPayments'] as num?)?.toDouble() ?? 0.0,
      totalRegistrationPayments:
          (json['totalRegistrationPayments'] as num?)?.toDouble() ?? 0.0,
      newMembers: (json['newMembers'] as num?)?.toInt() ?? 0,
    );
  }

  double get totalRevenue => totalMonthlyPayments + totalRegistrationPayments;
}

// ─────────────────────────────────────────────────────────────────────────────
// RÉSUMÉ DÉPÔTS PAR MEMBRE — /members/deposits-summary
// ─────────────────────────────────────────────────────────────────────────────
class DepositsSummaryItem {
  final int memberId;
  final String memberName;
  final String? matricule;
  final String phone;
  final double totalDeposits;
  final int depositCount;
  final String? lastDepositDate;
  final bool isActive;

  DepositsSummaryItem({
    required this.memberId,
    required this.memberName,
    required this.phone,
    this.matricule,
    required this.totalDeposits,
    required this.depositCount,
    this.lastDepositDate,
    required this.isActive,
  });

  factory DepositsSummaryItem.fromJson(Map<String, dynamic> json) {
    // memberName peut être une String ou un Map {firstName, lastName}
    String resolveName(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) return raw;
      if (raw is Map) {
        final fn = raw['firstName']?.toString() ?? '';
        final ln = raw['lastName']?.toString() ?? '';
        return '$fn $ln'.trim();
      }
      return raw.toString();
    }

    // matricule peut être un objet {value: "..."} ou une String directe
    String? resolveMatricule(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return raw;
      if (raw is Map) return raw['value']?.toString();
      return raw.toString();
    }

    // lastDepositDate : JPA peut retourner {year, month, day} ou "YYYY-MM-DD" ou null
    String? resolveDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return raw;
      if (raw is Map) {
        // Format JPA LocalDate sérialisé : {year, monthValue, dayOfMonth}
        final y = raw['year'] ?? raw['Year'];
        final m = raw['monthValue'] ?? raw['month'] ?? raw['Month'];
        final d = raw['dayOfMonth'] ?? raw['day'] ?? raw['Day'];
        if (y != null && m != null && d != null) {
          return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
        }
        return raw.toString();
      }
      return raw.toString();
    }

    // isActive : peut être bool true/false ou int 1/0 selon le driver MySQL
    bool resolveBool(dynamic raw) {
      if (raw == null) return true;
      if (raw is bool) return raw;
      if (raw is int) return raw != 0;
      if (raw is String) return raw == '1' || raw.toLowerCase() == 'true';
      return true;
    }

    return DepositsSummaryItem(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      memberName: resolveName(json['memberName']),
      phone: json['phone']?.toString() ?? '',
      matricule: resolveMatricule(json['matricule']),
      totalDeposits: (json['totalDeposits'] as num?)?.toDouble() ?? 0.0,
      depositCount: (json['depositCount'] as num?)?.toInt() ?? 0,
      lastDepositDate: resolveDate(json['lastDepositDate']),
      isActive: resolveBool(json['isActive']),
    );
  }

  String get initials {
    final parts = memberName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return memberName.isNotEmpty ? memberName[0].toUpperCase() : '?';
  }
}

class PendingRegistration {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? city;
  final String createdAt;
  final String currentStep;
  final String paymentStatus;
  final double? registrationFee;

  PendingRegistration({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.city,
    required this.createdAt,
    required this.currentStep,
    required this.paymentStatus,
    this.registrationFee,
  });

  factory PendingRegistration.fromJson(Map<String, dynamic> json) {
    // RegistrationResponseDTO retourne : firstName, lastName, phone, email, city
    // Fallback sur memberName/memberPhone si jamais l'entité brute est retournée
    final memberName = json['memberName'] as String? ?? '';
    final parts = memberName.split(' ');

    return PendingRegistration(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName:
          json['firstName'] as String? ?? (parts.isNotEmpty ? parts.first : ''),
      lastName:
          json['lastName'] as String? ??
          (parts.length > 1 ? parts.sublist(1).join(' ') : ''),
      phone: json['phone'] as String? ?? json['memberPhone'] as String? ?? '',
      email: json['email'] as String? ?? json['memberEmail'] as String?,
      city: json['city'] as String? ?? json['memberCity'] as String?,
      createdAt: json['createdAt']?.toString() ?? '',
      currentStep:
          json['currentStep'] as String? ??
          json['status'] as String? ??
          'PENDING_ADMIN_REVIEW',
      paymentStatus:
          json['paymentStatus'] as String? ??
          json['transactionStatus'] as String? ??
          'COMPLETED',
      registrationFee:
          (json['registrationFee'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble(),
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

class AdminMember {
  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final String? matricule;
  final String status;
  final bool active;
  final String? city;
  final String createdAt;
  final double? balance;

  AdminMember({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.matricule,
    required this.status,
    required this.active,
    this.city,
    required this.createdAt,
    this.balance,
  });

  factory AdminMember.fromJson(Map<String, dynamic> json) {
    return AdminMember(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName:
          json['fullName'] as String? ??
          '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      matricule: json['matricule'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      active: json['active'] as bool? ?? true,
      city: json['city'] as String?,
      createdAt: json['createdAt']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble(),
    );
  }

  bool get isActive => active && status == 'ACTIVE';
}

class CreateSolidarityFundRequest {
  final String description;
  final double amountPerMember;
  final DateTime deadlineDate;
  final int? beneficiaryId;
  final String? messageToMembers;
  final bool? disableNotifications;

  CreateSolidarityFundRequest({
    required this.description,
    required this.amountPerMember,
    required this.deadlineDate,
    this.beneficiaryId,
    this.messageToMembers,
    this.disableNotifications,
  });

  // Fonction pour nettoyer les emojis et caractères non-ASCII
  String _cleanText(String text) {
    // Supprime les emojis et caractères non-ASCII
    return text.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');
  }

  Map<String, dynamic> toJson() => {
    'description': _cleanText(description),
    'amountPerMember': amountPerMember,
    'deadlineDate': '${deadlineDate.year}-${deadlineDate.month.toString().padLeft(2, '0')}-${deadlineDate.day.toString().padLeft(2, '0')}',
    if (beneficiaryId != null) 'beneficiaryId': beneficiaryId,
    if (messageToMembers != null) 'messageToMembers': _cleanText(messageToMembers!),
    if (disableNotifications != null) 'disableNotifications': disableNotifications,
  };
}
