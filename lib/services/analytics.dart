import 'package:moneytrail/models/transaction.dart';

class MonthSummary {
  const MonthSummary({this.month, this.income = 0, this.expense = 0, this.count = 0});

  final DateTime? month;
  final double income;
  final double expense;
  final int count;

  double get balance => income - expense;
}

class CategoryTotal {
  const CategoryTotal(this.categoryId, this.total, this.share);

  final String categoryId;
  final double total;

  /// 0..1 share of total expenses.
  final double share;
}

/// Pure, side-effect-free calculations over a list of transactions.
/// Everything takes `now` as a parameter so behaviour is deterministic in tests.
class Analytics {
  Analytics._();

  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static DateTime previousMonth(DateTime m) => DateTime(m.year, m.month - 1);

  static int daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  static List<TransactionModel> inMonth(
      Iterable<TransactionModel> all, DateTime month) {
    return all.where((t) => sameMonth(t.date, month)).toList();
  }

  static MonthSummary summarize(Iterable<TransactionModel> txs, [DateTime? month]) {
    double income = 0;
    double expense = 0;
    var count = 0;
    for (final t in txs) {
      count++;
      if (t.isExpense) {
        expense += t.amount;
      } else {
        income += t.amount;
      }
    }
    return MonthSummary(month: month, income: income, expense: expense, count: count);
  }

  /// Expense totals per category, largest first.
  static List<CategoryTotal> expenseBreakdown(Iterable<TransactionModel> txs) {
    final totals = <String, double>{};
    var sum = 0.0;
    for (final t in txs) {
      if (!t.isExpense) continue;
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
      sum += t.amount;
    }
    final list = totals.entries
        .map((e) => CategoryTotal(e.key, e.value, sum == 0 ? 0 : e.value / sum))
        .toList();
    list.sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  /// Last [n] months ending at [endMonth], oldest first.
  static List<MonthSummary> trailing(
      Iterable<TransactionModel> all, DateTime endMonth, int n) {
    final out = <MonthSummary>[];
    for (var i = n - 1; i >= 0; i--) {
      final m = DateTime(endMonth.year, endMonth.month - i);
      out.add(summarize(inMonth(all, m), m));
    }
    return out;
  }

  static double dailyAverage(double expense, DateTime month, DateTime now) {
    final int days;
    if (sameMonth(month, now)) {
      days = now.day;
    } else if (month.isBefore(DateTime(now.year, now.month))) {
      days = daysInMonth(month);
    } else {
      days = 1;
    }
    return days == 0 ? 0 : expense / days;
  }

  /// Linear run-rate projection. Only meaningful for the current month.
  static double? projectedExpense(double expense, DateTime month, DateTime now) {
    if (!sameMonth(month, now) || now.day == 0) return null;
    return expense / now.day * daysInMonth(month);
  }
}
