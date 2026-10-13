import 'package:afoso1/features/member/data/models/deposit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('overdue selection chain', () {
    final overdue = [
      CalendarMonthItem(
        month: 3,
        year: 2026,
        monthName: 'Mars',
        status: 'OVERDUE',
        statusLabel: 'En retard',
        selectable: true,
        mandatory: true,
        paidAmount: 0,
        isAdvance: false,
        daysLate: 15,
      ),
      CalendarMonthItem(
        month: 4,
        year: 2026,
        monthName: 'Avril',
        status: 'OVERDUE',
        statusLabel: 'En retard',
        selectable: true,
        mandatory: true,
        paidAmount: 0,
        isAdvance: false,
        daysLate: 15,
      ),
      CalendarMonthItem(
        month: 5,
        year: 2026,
        monthName: 'Mai',
        status: 'OVERDUE',
        statusLabel: 'En retard',
        selectable: true,
        mandatory: true,
        paidAmount: 0,
        isAdvance: false,
        daysLate: 15,
      ),
    ];

    test('accepts prefix selection from the oldest overdue month', () {
      final selected = {
        MonthYear(month: 3, year: 2026),
        MonthYear(month: 4, year: 2026),
      };

      expect(overdueSelectionError(overdue, selected), isNull);
    });

    test(
      'accepts the next overdue month once the earlier month is already selected',
      () {
        expect(
          overdueSelectionError(overdue, {
            MonthYear(month: 3, year: 2026),
            MonthYear(month: 4, year: 2026),
          }),
          isNull,
        );
      },
    );

    test('rejects missing older month and gap in the middle', () {
      expect(
        overdueSelectionError(overdue, {MonthYear(month: 4, year: 2026)}),
        contains('Mars 2026'),
      );

      expect(
        overdueSelectionError(overdue, {
          MonthYear(month: 3, year: 2026),
          MonthYear(month: 5, year: 2026),
        }),
        contains('Avril 2026'),
      );
    });

    test('accepts all selected overdue months as a complete prefix', () {
      final selected = {
        MonthYear(month: 3, year: 2026),
        MonthYear(month: 4, year: 2026),
        MonthYear(month: 5, year: 2026),
      };

      expect(overdueSelectionError(overdue, selected), isNull);
    });
  });
}
