import 'package:flutter_test/flutter_test.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/services/analytics.dart';

TransactionModel tx(String id, double amount, TxType type, String cat, DateTime date) =>
    TransactionModel(id: id, amount: amount, type: type, categoryId: cat, date: date);

void main() {
  final may = DateTime(2025, 5);
  final data = [
    tx('1', 1000, TxType.expense, 'food', DateTime(2025, 5, 2)),
    tx('2', 500, TxType.expense, 'food', DateTime(2025, 5, 9)),
    tx('3', 500, TxType.expense, 'bills', DateTime(2025, 5, 12)),
    tx('4', 5000, TxType.income, 'in_salary', DateTime(2025, 5, 1)),
    tx('5', 700, TxType.expense, 'food', DateTime(2025, 4, 20)),
  ];

  test('inMonth filters by year and month', () {
    expect(Analytics.inMonth(data, may).length, 4);
    expect(Analytics.inMonth(data, DateTime(2024, 5)).length, 0);
  });

  test('summarize totals income, expense and balance', () {
    final s = Analytics.summarize(Analytics.inMonth(data, may));
    expect(s.income, 5000);
    expect(s.expense, 2000);
    expect(s.balance, 3000);
    expect(s.count, 4);
  });

  test('expenseBreakdown is sorted and shares sum to 1', () {
    final b = Analytics.expenseBreakdown(Analytics.inMonth(data, may));
    expect(b.first.categoryId, 'food');
    expect(b.first.total, 1500);
    expect(b.first.share, closeTo(0.75, 1e-9));
    expect(b.fold<double>(0, (a, e) => a + e.share), closeTo(1, 1e-9));
  });

  test('trailing returns n months oldest first and crosses year boundary', () {
    final t = Analytics.trailing(data, DateTime(2025, 1), 3);
    expect(t.map((m) => m.month!.month).toList(), [11, 12, 1]);
    final t2 = Analytics.trailing(data, may, 2);
    expect(t2.first.expense, 700);
    expect(t2.last.expense, 2000);
  });

  test('daily average uses elapsed days for the current month', () {
    expect(Analytics.dailyAverage(1000, may, DateTime(2025, 5, 10)), 100);
  });

  test('daily average uses full month length for past months', () {
    expect(Analytics.dailyAverage(3100, may, DateTime(2025, 8, 15)), 100);
  });

  test('projection extrapolates the run rate, only for current month', () {
    expect(Analytics.projectedExpense(1000, may, DateTime(2025, 5, 10)), closeTo(3100, 1e-9));
    expect(Analytics.projectedExpense(1000, may, DateTime(2025, 6, 10)), isNull);
  });
}
