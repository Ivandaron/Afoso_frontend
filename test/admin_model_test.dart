import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyDeposit parsing', () {
    test('parses advance payment metadata from backend payload', () {
      final deposit = MonthlyDeposit.fromJson({
        'id': 42,
        'month': 7,
        'year': 2026,
        'status': 'COMPLETED',
        'amount': 5000,
        'paidAmount': 5000,
        'createdAt': '2026-07-10',
        'monthsCount': 3,
        'isAdvancePayment': true,
      });

      expect(deposit.monthsCount, 3);
      expect(deposit.isAdvancePayment, isTrue);
      expect(deposit.advanceLabel, 'Paiement anticipé • 3 mois');
    });
  });
}
