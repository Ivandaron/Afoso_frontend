// deposit.dart - Ajouter les nouveaux modèles
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

// 🔥 NOUVEAU: Request pour paiement unifié (1 mois ou plusieurs)
class UnifiedDepositRequest {
  final double amountPerMonth;
  final int monthsCount;
  final List<String> monthsToPay;
  final String paymentPhone;
  final String paymentMethod;
  final bool isAdvancePayment;

  UnifiedDepositRequest({
    required this.amountPerMonth,
    required this.monthsCount,
    required this.monthsToPay,
    required this.paymentPhone,
    required this.paymentMethod,
    this.isAdvancePayment = false,
  });

  Map<String, dynamic> toJson() => {
    'amountPerMonth': amountPerMonth,
    'monthsCount': monthsCount,
    'monthsToPay': monthsToPay,
    'paymentPhone': paymentPhone,
    'paymentMethod': paymentMethod,
    'isAdvancePayment': isAdvancePayment,
  };
  
  double get totalAmount => amountPerMonth * monthsCount;
  double get minimumRequired => 1000.0 * monthsCount;
  bool get isTotalAmountValid => totalAmount >= minimumRequired;
  bool get isSimpleDeposit => monthsCount == 1;
  bool get isMultipleDeposit => monthsCount > 1;
}

// 🔥 NOUVEAU: Transaction pour paiement multiple
class MultipleDepositTransaction {
  final String transactionReference;
  final double totalAmount;
  final double amountPerMonth;
  final int monthsCount;
  final List<String> monthsToPay;
  final String paymentPhone;
  final String paymentMethod;
  final String status;
  final bool isAdvancePayment;

  MultipleDepositTransaction({
    required this.transactionReference,
    required this.totalAmount,
    required this.amountPerMonth,
    required this.monthsCount,
    required this.monthsToPay,
    required this.paymentPhone,
    required this.paymentMethod,
    required this.status,
    this.isAdvancePayment = false,
  });

  factory MultipleDepositTransaction.fromJson(Map<String, dynamic> json) {
    return MultipleDepositTransaction(
      transactionReference: json['transactionReference'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      amountPerMonth: (json['amountPerMonth'] as num?)?.toDouble() ?? 0.0,
      monthsCount: json['monthsCount'] as int? ?? 0,
      monthsToPay: (json['monthsToPay'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      paymentPhone: json['paymentPhone'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      isAdvancePayment: json['isAdvancePayment'] as bool? ?? false,
    );
  }
}

// Garder l'ancien pour compatibilité
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