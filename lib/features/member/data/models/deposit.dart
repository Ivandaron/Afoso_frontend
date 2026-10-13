// ═══════════════════════════════════════════════════════════════════════════
// DÉPÔTS — Modèles
// ═══════════════════════════════════════════════════════════════════════════

class DepositSummary {
  final double totalSaved;
  final MonthStats currentMonth;
  final MonthStats previousMonth;
  final String progression;

  DepositSummary({
    required this.totalSaved,
    required this.currentMonth,
    required this.previousMonth,
    required this.progression,
  });

  factory DepositSummary.fromJson(Map<String, dynamic> json) {
    return DepositSummary(
      totalSaved: (json['totalSaved'] as num?)?.toDouble() ?? 0.0,
      currentMonth: MonthStats.fromJson(
        json['currentMonth'] as Map<String, dynamic>? ?? {},
      ),
      previousMonth: MonthStats.fromJson(
        json['previousMonth'] as Map<String, dynamic>? ?? {},
      ),
      progression: json['progression'] as String? ?? '0%',
    );
  }
}

class MonthStats {
  final String month;
  final double total;
  final int depositCount;

  MonthStats({
    required this.month,
    required this.total,
    required this.depositCount,
  });

  factory MonthStats.fromJson(Map<String, dynamic> json) {
    return MonthStats(
      month: json['month'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      depositCount: (json['depositCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class Deposit {
  final int id;
  final double amount;
  final int month;
  final int year;
  final String date;
  final String status;
  final bool isCompleted;

  Deposit({
    required this.id,
    required this.amount,
    required this.month,
    required this.year,
    required this.date,
    required this.status,
    required this.isCompleted,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: (json['id'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      status: json['status'] as String? ?? 'PENDING',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  bool get isPaid =>
      isCompleted || status == 'COMPLETED' || status == 'SUCCESS';
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 MonthYear — Représente un mois précis
// ═══════════════════════════════════════════════════════════════════════════

class MonthYear {
  final int month;
  final int year;

  const MonthYear({required this.month, required this.year});

  factory MonthYear.fromJson(Map<String, dynamic> json) {
    return MonthYear(
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'month': month, 'year': year};

  String get key => '$year-${month.toString().padLeft(2, '0')}';

  String get label {
    const months = [
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
    if (month < 1 || month > 12) return '$month/$year';
    return '${months[month]} $year';
  }

  String get shortLabel {
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
    return months[month];
  }

  @override
  bool operator ==(Object other) =>
      other is MonthYear && other.month == month && other.year == year;

  @override
  int get hashCode => Object.hash(month, year);
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 MultiMonthDepositRequest — Requête de paiement multi-mois
// ═══════════════════════════════════════════════════════════════════════════

class MultiMonthDepositRequest {
  final List<MonthYear> months;
  final double amountPerMonth;
  final String paymentPhone;

  MultiMonthDepositRequest({
    required this.months,
    required this.amountPerMonth,
    required this.paymentPhone,
  });

  Map<String, dynamic> toJson() => {
    'months': months.map((m) => m.toJson()).toList(),
    'amountPerMonth': amountPerMonth,
    'paymentPhone': paymentPhone,
    'paymentMethod': 'CAMPAY',
  };

  double get totalAmount => amountPerMonth * months.length;
  int get monthsCount => months.length;
  bool get isValid => months.isNotEmpty && amountPerMonth >= 5;
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 MultiMonthDepositTransaction — Réponse transaction
// ═══════════════════════════════════════════════════════════════════════════

class MultiMonthDepositTransaction {
  final String transactionReference;
  final double totalAmount;
  final double amountPerMonth;
  final int monthsCount;
  final List<MonthYear> months;
  final String paymentPhone;
  final String paymentMethod;
  final String status;

  MultiMonthDepositTransaction({
    required this.transactionReference,
    required this.totalAmount,
    required this.amountPerMonth,
    required this.monthsCount,
    required this.months,
    required this.paymentPhone,
    required this.paymentMethod,
    required this.status,
  });

  factory MultiMonthDepositTransaction.fromJson(Map<String, dynamic> json) {
    final monthsRaw = (json['months'] as List<dynamic>?) ?? [];
    return MultiMonthDepositTransaction(
      transactionReference: json['transactionReference'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      amountPerMonth: (json['amountPerMonth'] as num?)?.toDouble() ?? 0.0,
      monthsCount: (json['monthsCount'] as num?)?.toInt() ?? 0,
      months:
          monthsRaw
              .map((e) => MonthYear.fromJson(e as Map<String, dynamic>))
              .toList(),
      paymentPhone: json['paymentPhone'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}

class PaymentVerifyResult {
  final String reference;
  final String status;
  final bool isCompleted;

  PaymentVerifyResult({
    required this.reference,
    required this.status,
    required this.isCompleted,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 DepositCalendar — Calendrier d'épargne
// ═══════════════════════════════════════════════════════════════════════════

List<CalendarMonthItem> orderedOverdueMonths(List<CalendarMonthItem> months) {
  final sorted = [...months];
  sorted.sort((a, b) {
    final cmpYear = a.year.compareTo(b.year);
    return cmpYear != 0 ? cmpYear : a.month.compareTo(b.month);
  });
  return sorted;
}

String? overdueSelectionError(
  List<CalendarMonthItem> overdueMonths,
  Set<MonthYear> selectedMonths,
) {
  final ordered = orderedOverdueMonths(overdueMonths);
  if (ordered.isEmpty) return null;

  int firstMissingIndex = -1;
  for (int i = 0; i < ordered.length; i++) {
    if (!selectedMonths.contains(ordered[i].monthYear)) {
      firstMissingIndex = i;
      break;
    }
  }

  if (firstMissingIndex == -1) return null;

  final firstMissing = ordered[firstMissingIndex];

  for (int i = firstMissingIndex + 1; i < ordered.length; i++) {
    if (selectedMonths.contains(ordered[i].monthYear)) {
      return 'Réglez ${firstMissing.monthName} ${firstMissing.year} avant les mois suivants';
    }
  }

  return null;
}

class DepositCalendar {
  final int year;
  final int memberId;
  final String memberName;
  final String situation;
  final String situationLabel;
  final int overdueMonthsCount;
  final int advanceMonthsCount;
  final int paidMonthsCount;
  final double totalPaidYear;

  // 🔥 Nouveaux champs de blocage
  final bool canPayFutureMonths;
  final int blockingOverdueCount;
  final List<String> blockingOverdueMonths;
  final String? blockReason;

  final List<CalendarMonthItem> months;

  DepositCalendar({
    required this.year,
    required this.memberId,
    required this.memberName,
    required this.situation,
    required this.situationLabel,
    required this.overdueMonthsCount,
    required this.advanceMonthsCount,
    required this.paidMonthsCount,
    required this.totalPaidYear,
    this.canPayFutureMonths = true,
    this.blockingOverdueCount = 0,
    this.blockingOverdueMonths = const [],
    this.blockReason,
    required this.months,
  });

  factory DepositCalendar.fromJson(Map<String, dynamic> json) {
    return DepositCalendar(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      memberName: json['memberName'] as String? ?? '',
      situation: json['situation'] as String? ?? 'EN_COURS',
      situationLabel: json['situationLabel'] as String? ?? '',
      overdueMonthsCount: (json['overdueMonthsCount'] as num?)?.toInt() ?? 0,
      advanceMonthsCount: (json['advanceMonthsCount'] as num?)?.toInt() ?? 0,
      paidMonthsCount: (json['paidMonthsCount'] as num?)?.toInt() ?? 0,
      totalPaidYear: (json['totalPaidYear'] as num?)?.toDouble() ?? 0.0,
      canPayFutureMonths: json['canPayFutureMonths'] as bool? ?? true,
      blockingOverdueCount:
          (json['blockingOverdueCount'] as num?)?.toInt() ?? 0,
      blockingOverdueMonths:
          ((json['blockingOverdueMonths'] as List<dynamic>?) ?? [])
              .map((e) => e.toString())
              .toList(),
      blockReason: json['blockReason'] as String?,
      months:
          ((json['months'] as List<dynamic>?) ?? [])
              .map((e) => CalendarMonthItem.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  /// Liste des mois en retard (pour pré-sélection).
  List<CalendarMonthItem> get overdueMonths =>
      months.where((m) => m.status == 'OVERDUE' || m.mandatory).toList();

  /// Liste des mois obligatoires (retards).
  List<CalendarMonthItem> get mandatoryMonths =>
      months.where((m) => m.mandatory).toList();

  /// Liste des mois sélectionnables.
  List<CalendarMonthItem> get availableMonths =>
      months.where((m) => m.selectable).toList();

  /// Y a-t-il un blocage en cours ?
  bool get hasBlockingOverdue =>
      !canPayFutureMonths && blockingOverdueCount > 0;
}

class CalendarMonthItem {
  final int month;
  final int year;
  final String monthName;
  final String status;
  final String statusLabel;
  final bool selectable;
  final bool mandatory;
  final String? blockedReason;
  final double paidAmount;
  final String? paymentDate;
  final bool isAdvance;
  final int daysLate;

  CalendarMonthItem({
    required this.month,
    required this.year,
    required this.monthName,
    required this.status,
    required this.statusLabel,
    required this.selectable,
    this.mandatory = false,
    this.blockedReason,
    required this.paidAmount,
    this.paymentDate,
    required this.isAdvance,
    required this.daysLate,
  });

  factory CalendarMonthItem.fromJson(Map<String, dynamic> json) {
    return CalendarMonthItem(
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      monthName: json['monthName'] as String? ?? '',
      status: json['status'] as String? ?? 'AVAILABLE',
      statusLabel: json['statusLabel'] as String? ?? '',
      selectable: json['selectable'] as bool? ?? false,
      mandatory: json['mandatory'] as bool? ?? false,
      blockedReason: json['blockedReason'] as String?,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['paymentDate']?.toString(),
      isAdvance: json['isAdvance'] as bool? ?? false,
      daysLate: (json['daysLate'] as num?)?.toInt() ?? 0,
    );
  }

  MonthYear get monthYear => MonthYear(month: month, year: year);
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 MemberSituation — Situation globale
// ═══════════════════════════════════════════════════════════════════════════

class MemberSituation {
  final int memberId;
  final String fullName;
  final String situation;
  final String situationLabel;
  final int overdueMonthsCount;
  final int advanceMonthsCount;
  final bool currentMonthPaid;
  final double totalPaid;
  final List<String> overdueMonths;

  MemberSituation({
    required this.memberId,
    required this.fullName,
    required this.situation,
    required this.situationLabel,
    required this.overdueMonthsCount,
    required this.advanceMonthsCount,
    required this.currentMonthPaid,
    required this.totalPaid,
    required this.overdueMonths,
  });

  factory MemberSituation.fromJson(Map<String, dynamic> json) {
    return MemberSituation(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String? ?? '',
      situation: json['situation'] as String? ?? 'EN_COURS',
      situationLabel: json['situationLabel'] as String? ?? '',
      overdueMonthsCount: (json['overdueMonthsCount'] as num?)?.toInt() ?? 0,
      advanceMonthsCount: (json['advanceMonthsCount'] as num?)?.toInt() ?? 0,
      currentMonthPaid: json['currentMonthPaid'] as bool? ?? false,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      overdueMonths:
          ((json['overdueMonths'] as List<dynamic>?) ?? [])
              .map((e) => e.toString())
              .toList(),
    );
  }

  bool get isUpToDate => situation == 'A_JOUR';
  bool get isLate => situation == 'EN_RETARD';
  bool get isAhead => situation == 'EN_AVANCE';
  bool get isCurrent => situation == 'EN_COURS';
}

// ═══════════════════════════════════════════════════════════════════════════
// LEGACY — Gardé pour compatibilité (à supprimer plus tard)
// ═══════════════════════════════════════════════════════════════════════════

class DepositTransaction {
  final String transactionReference;
  final double amount;
  final String paymentPhone;
  final String paymentMethod;
  final String status;

  DepositTransaction({
    required this.transactionReference,
    required this.amount,
    required this.paymentPhone,
    required this.paymentMethod,
    required this.status,
  });

  factory DepositTransaction.fromJson(Map<String, dynamic> json) {
    return DepositTransaction(
      transactionReference: json['transactionReference'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentPhone: json['paymentPhone'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}
