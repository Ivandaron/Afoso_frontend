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

class InitiateDepositRequest {
  final double amount;
  final String paymentPhone;
  final String paymentMethod;

  InitiateDepositRequest({
    required this.amount,
    required this.paymentPhone,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'paymentPhone': paymentPhone,
    'paymentMethod': paymentMethod,
  };
}

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
