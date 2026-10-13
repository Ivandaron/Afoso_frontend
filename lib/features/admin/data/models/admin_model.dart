// =============================================================================
// ADMIN MODELS — Version enrichie pour les paiements anticipés
// =============================================================================

class DashboardStats {
  final double totalDeposits;
  final int activeMembers;
  final int pendingRegistrations;
  final int failedTransactions;
  final int totalLoans;
  final double totalLoanAmount;
  final double totalRegistrationFees;

  // 🔥 NOUVEAU : Statistiques des paiements anticipés
  final AdvancePaymentStats advancePayments;

  DashboardStats({
    required this.totalDeposits,
    required this.activeMembers,
    required this.pendingRegistrations,
    required this.failedTransactions,
    required this.totalLoans,
    required this.totalLoanAmount,
    this.totalRegistrationFees = 0.0,
    this.advancePayments = const AdvancePaymentStats.empty(),
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
      advancePayments: AdvancePaymentStats.fromJson(
        json['advancePayments'] as Map<String, dynamic>?,
      ),
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
    advancePayments: advancePayments,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔥 NOUVEAU : Statistiques des paiements anticipés
// ─────────────────────────────────────────────────────────────────────────────
class AdvancePaymentStats {
  final int totalAdvancePayments;
  final int distinctMembers;
  final int totalAdvanceMonths;
  final double totalAdvanceAmount;
  final double averageMonthsPerPayment;

  const AdvancePaymentStats({
    this.totalAdvancePayments = 0,
    this.distinctMembers = 0,
    this.totalAdvanceMonths = 0,
    this.totalAdvanceAmount = 0.0,
    this.averageMonthsPerPayment = 0.0,
  });

  const AdvancePaymentStats.empty()
    : totalAdvancePayments = 0,
      distinctMembers = 0,
      totalAdvanceMonths = 0,
      totalAdvanceAmount = 0.0,
      averageMonthsPerPayment = 0.0;

  factory AdvancePaymentStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AdvancePaymentStats.empty();
    return AdvancePaymentStats(
      totalAdvancePayments:
          (json['totalAdvancePayments'] as num?)?.toInt() ?? 0,
      distinctMembers: (json['distinctMembers'] as num?)?.toInt() ?? 0,
      totalAdvanceMonths: (json['totalAdvanceMonths'] as num?)?.toInt() ?? 0,
      totalAdvanceAmount:
          (json['totalAdvanceAmount'] as num?)?.toDouble() ?? 0.0,
      averageMonthsPerPayment:
          (json['averageMonthsPerPayment'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get hasData => totalAdvancePayments > 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// RÉSUMÉ FINANCIER PAR PÉRIODE — /financial-overview/period
// ─────────────────────────────────────────────────────────────────────────────
class PeriodOverview {
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final double totalMonthlyPayments;
  final double totalRegistrationPayments;
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

    String? resolveMatricule(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return raw;
      if (raw is Map) return raw['value']?.toString();
      return raw.toString();
    }

    String? resolveDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return raw;
      if (raw is Map) {
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

// ─────────────────────────────────────────────────────────────────────────────
// INSCRIPTIONS EN ATTENTE
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// 🔥 AdminMember ENRICHI — avec paiements anticipés + statut mois courant
// ─────────────────────────────────────────────────────────────────────────────
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

  // 🔥 NOUVEAU : Paiements anticipés
  final bool hasAdvancePayment;
  final int advanceMonthsCount;
  final double advanceAmount;

  // 🔥 NOUVEAU : Situation du mois courant
  final bool currentMonthPaid;
  final String? lastPaymentDate;
  final String currentMonthStatus;

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
    this.hasAdvancePayment = false,
    this.advanceMonthsCount = 0,
    this.advanceAmount = 0.0,
    this.currentMonthPaid = false,
    this.lastPaymentDate,
    this.currentMonthStatus = 'NOT_PAID',
  });

  factory AdminMember.fromJson(Map<String, dynamic> json) {
    // Gestion des booléens polymorphiques (bool / int / string)
    bool parseBool(dynamic raw, {bool defaultValue = false}) {
      if (raw == null) return defaultValue;
      if (raw is bool) return raw;
      if (raw is int) return raw != 0;
      if (raw is String) {
        final v = raw.toLowerCase();
        return v == 'true' || v == '1' || v == 'yes';
      }
      return defaultValue;
    }

    return AdminMember(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName:
          json['fullName'] as String? ??
          '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      matricule: json['matricule'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      active: parseBool(json['active'], defaultValue: true),
      city: json['city'] as String?,
      createdAt: json['createdAt']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble(),
      // 🔥 Nouveaux champs
      hasAdvancePayment: parseBool(json['hasAdvancePayment']),
      advanceMonthsCount: (json['advanceMonthsCount'] as num?)?.toInt() ?? 0,
      advanceAmount: (json['advanceAmount'] as num?)?.toDouble() ?? 0.0,
      currentMonthPaid: parseBool(json['currentMonthPaid']),
      lastPaymentDate: json['lastPaymentDate']?.toString(),
      currentMonthStatus: json['currentMonthStatus'] as String? ?? 'NOT_PAID',
    );
  }

  bool get isActive => active && status == 'ACTIVE';

  // 🔥 Indicateur de statut du mois courant avec libellé
  String get currentMonthStatusLabel {
    switch (currentMonthStatus.toUpperCase()) {
      case 'COMPLETED':
      case 'PAID':
        return 'Payé ce mois';
      case 'PENDING':
        return 'En attente';
      case 'PARTIAL':
        return 'Partiel';
      case 'OVERDUE':
        return 'En retard';
      case 'NOT_PAID':
      default:
        return 'Non payé';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HISTORIQUE COMPLET D'UN MEMBRE
// ─────────────────────────────────────────────────────────────────────────────
class MemberContributionHistory {
  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final String? matricule;
  final String? city;
  final String status;
  final bool active;
  final String? birthDate;
  final String createdAt;
  final double accountBalance;
  final double totalDeposited;
  final double totalContributed;
  final int totalCompletedPayments;
  final int totalPendingPayments;
  final int totalPartialPayments;
  final int totalLatePayments;
  final int totalAdvancePayments;
  final List<MonthlyContribution> contributions;
  final List<MonthlyDeposit> monthlyDeposits;
  final List<MissingMonth> missingMonths;

  MemberContributionHistory({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.matricule,
    this.city,
    required this.status,
    required this.active,
    this.birthDate,
    required this.createdAt,
    required this.accountBalance,
    required this.totalDeposited,
    required this.totalContributed,
    required this.totalCompletedPayments,
    required this.totalPendingPayments,
    required this.totalPartialPayments,
    required this.totalLatePayments,
    this.totalAdvancePayments = 0,
    required this.contributions,
    required this.monthlyDeposits,
    required this.missingMonths,
  });

  int get advancePaymentCount => totalAdvancePayments;

  int get totalAdvanceMonths => contributions.fold(
    0,
    (sum, item) => sum + (item.isAdvancePayment ? item.monthsInAdvance : 0),
  );

  factory MemberContributionHistory.fromJson(Map<String, dynamic> json) {
    return MemberContributionHistory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      matricule: json['matricule'] as String?,
      city: json['city'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      active: json['active'] as bool? ?? true,
      birthDate: json['birthDate'] as String?,
      createdAt: json['createdAt']?.toString() ?? '',
      accountBalance: (json['accountBalance'] as num?)?.toDouble() ?? 0.0,
      totalDeposited: (json['totalDeposited'] as num?)?.toDouble() ?? 0.0,
      totalContributed: (json['totalContributed'] as num?)?.toDouble() ?? 0.0,
      totalCompletedPayments:
          (json['totalCompletedPayments'] as num?)?.toInt() ?? 0,
      totalPendingPayments:
          (json['totalPendingPayments'] as num?)?.toInt() ?? 0,
      totalPartialPayments:
          (json['totalPartialPayments'] as num?)?.toInt() ?? 0,
      totalLatePayments: (json['totalLatePayments'] as num?)?.toInt() ?? 0,
      totalAdvancePayments:
          (json['totalAdvancePayments'] as num?)?.toInt() ?? 0,
      contributions:
          (json['contributions'] as List<dynamic>?)
              ?.map(
                (e) => MonthlyContribution.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      monthlyDeposits:
          (json['monthlyDeposits'] as List<dynamic>?)
              ?.map((e) => MonthlyDeposit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      missingMonths:
          (json['missingMonths'] as List<dynamic>?)
              ?.map((e) => MissingMonth.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTRIBUTION MENSUELLE
// ─────────────────────────────────────────────────────────────────────────────
class MonthlyContribution {
  final int id;
  final int month;
  final int year;
  final String status;
  final double amount;
  final double paidAmount;
  final int? daysLate;
  final bool isAdvancePayment;
  final int monthsInAdvance;
  final String createdAt;

  MonthlyContribution({
    required this.id,
    required this.month,
    required this.year,
    required this.status,
    required this.amount,
    required this.paidAmount,
    this.daysLate,
    this.isAdvancePayment = false,
    this.monthsInAdvance = 0,
    required this.createdAt,
  });

  factory MonthlyContribution.fromJson(Map<String, dynamic> json) {
    return MonthlyContribution(
      id: (json['id'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'UNKNOWN',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      daysLate: (json['daysLate'] as num?)?.toInt(),
      isAdvancePayment: json['isAdvance'] as bool? ?? false,
      monthsInAdvance: (json['monthsInAdvance'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  String get monthLabel {
    final yearString = year.toString();
    if (yearString.length >= 2) {
      return '$month/${yearString.substring(yearString.length - 2)}';
    }
    return '$month/$yearString';
  }

  String get advanceLabel =>
      isAdvancePayment
          ? (monthsInAdvance > 0 ? '+$monthsInAdvance mois' : 'Paiement anticipé')
          : 'Paiement standard';

  String get title => 'Cotisation $month/$year';
  String get subtitle => '$status • payé ${paidAmount.toStringAsFixed(0)} FCFA';
  String get amountLabel => '${paidAmount.toStringAsFixed(0)} FCFA';
}

class MonthlyDeposit extends MonthlyContribution {
  MonthlyDeposit({
    required int id,
    required int month,
    required int year,
    required String status,
    required double amount,
    required double paidAmount,
    int? daysLate,
    bool isAdvancePayment = false,
    int monthsInAdvance = 0,
    required String createdAt,
  }) : super(
         id: id,
         month: month,
         year: year,
         status: status,
         amount: amount,
         paidAmount: paidAmount,
         daysLate: daysLate,
         isAdvancePayment: isAdvancePayment,
         monthsInAdvance: monthsInAdvance,
         createdAt: createdAt,
       );

  factory MonthlyDeposit.fromJson(Map<String, dynamic> json) {
    return MonthlyDeposit(
      id: (json['id'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'UNKNOWN',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      daysLate: (json['daysLate'] as num?)?.toInt(),
      isAdvancePayment: json['isAdvance'] as bool? ?? false,
      monthsInAdvance: (json['monthsInAdvance'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOIS MANQUANTS
// ─────────────────────────────────────────────────────────────────────────────
class MissingMonth {
  final int year;
  final int month;
  final String monthName;

  MissingMonth({
    required this.year,
    required this.month,
    required this.monthName,
  });

  factory MissingMonth.fromJson(Map<String, dynamic> json) {
    return MissingMonth(
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      monthName:
          json['monthName'] as String? ??
          _monthName((json['month'] as num?)?.toInt() ?? 0),
    );
  }

  String get formattedMonth =>
      monthName.isNotEmpty ? '$monthName $year' : '$month/$year';

  static String _monthName(int month) {
    const names = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    if (month < 1 || month > 12) return '';
    return names[month];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔥 NOUVEAU : Paiement anticipé (endpoint /payments/advance)
// ─────────────────────────────────────────────────────────────────────────────
class AdvancePayment {
  final int paymentId;
  final int? memberId;
  final String? memberName;
  final int month;
  final int year;
  final double targetAmount;
  final double paidAmount;
  final String status;
  final bool isAdvance;
  final int monthsInAdvance;
  final String? paymentDate;
  final String? dueDate;
  final bool isCompleted;

  AdvancePayment({
    required this.paymentId,
    this.memberId,
    this.memberName,
    required this.month,
    required this.year,
    required this.targetAmount,
    required this.paidAmount,
    required this.status,
    required this.isAdvance,
    required this.monthsInAdvance,
    this.paymentDate,
    this.dueDate,
    required this.isCompleted,
  });

  factory AdvancePayment.fromJson(Map<String, dynamic> json) {
    return AdvancePayment(
      paymentId: (json['paymentId'] as num?)?.toInt() ?? 0,
      memberId: (json['memberId'] as num?)?.toInt(),
      memberName: json['memberName'] as String?,
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'UNKNOWN',
      isAdvance: json['isAdvance'] as bool? ?? true,
      monthsInAdvance: (json['monthsInAdvance'] as num?)?.toInt() ?? 0,
      paymentDate: json['paymentDate']?.toString(),
      dueDate: json['dueDate']?.toString(),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  String get monthLabel {
    const months = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    if (month < 1 || month > 12) return '$month/$year';
    return '${months[month]} $year';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔥 NOUVEAU : Top membre par avance
// ─────────────────────────────────────────────────────────────────────────────
class TopAdvanceMember {
  final int memberId;
  final String firstName;
  final String lastName;
  final String fullName;
  final int totalMonthsInAdvance;

  TopAdvanceMember({
    required this.memberId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.totalMonthsInAdvance,
  });

  factory TopAdvanceMember.fromJson(Map<String, dynamic> json) {
    final fn = json['firstName'] as String? ?? '';
    final ln = json['lastName'] as String? ?? '';
    return TopAdvanceMember(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      firstName: fn,
      lastName: ln,
      fullName: json['fullName'] as String? ?? '$fn $ln'.trim(),
      totalMonthsInAdvance:
          (json['totalMonthsInAdvance'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔥 NOUVEAU : Membre avec cycle parfait
// ─────────────────────────────────────────────────────────────────────────────
class PerfectCycleMember {
  final int memberId;
  final String fullName;
  final String phone;
  final String? city;
  final String? matricule;

  PerfectCycleMember({
    required this.memberId,
    required this.fullName,
    required this.phone,
    this.city,
    this.matricule,
  });

  factory PerfectCycleMember.fromJson(Map<String, dynamic> json) {
    return PerfectCycleMember(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String?,
      matricule: json['matricule'] as String?,
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔥 NOUVEAU : Résultat de vérification de cycle parfait (1 membre)
// ─────────────────────────────────────────────────────────────────────────────
class PerfectCycleCheck {
  final int memberId;
  final String fullName;
  final int year;
  final int paidMonths;
  final int totalMonths;
  final bool isPerfectCycle;
  final String completionRate;

  PerfectCycleCheck({
    required this.memberId,
    required this.fullName,
    required this.year,
    required this.paidMonths,
    required this.totalMonths,
    required this.isPerfectCycle,
    required this.completionRate,
  });

  factory PerfectCycleCheck.fromJson(Map<String, dynamic> json) {
    return PerfectCycleCheck(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      paidMonths: (json['paidMonths'] as num?)?.toInt() ?? 0,
      totalMonths: (json['totalMonths'] as num?)?.toInt() ?? 12,
      isPerfectCycle: json['isPerfectCycle'] as bool? ?? false,
      completionRate: json['completionRate'] as String? ?? '0%',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CRÉATION DE CAGNOTTE SOLIDAIRE (existant)
// ─────────────────────────────────────────────────────────────────────────────
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

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');
  }

  Map<String, dynamic> toJson() => {
    'description': _cleanText(description),
    'amountPerMember': amountPerMember,
    'deadlineDate':
        '${deadlineDate.year}-${deadlineDate.month.toString().padLeft(2, '0')}-${deadlineDate.day.toString().padLeft(2, '0')}',
    if (beneficiaryId != null) 'beneficiaryId': beneficiaryId,
    if (messageToMembers != null)
      'messageToMembers': _cleanText(messageToMembers!),
    if (disableNotifications != null)
      'disableNotifications': disableNotifications,
  };
}
