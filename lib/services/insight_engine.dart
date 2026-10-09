import 'package:flutter/material.dart';
import 'package:moneytrail/data/categories.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/services/analytics.dart';

class Insight {
  const Insight(this.icon, this.text, {this.positive});

  final IconData icon;
  final String text;

  /// true = good news, false = warning, null = neutral.
  final bool? positive;
}

/// Rule-based "smart insights". Deliberately transparent heuristics rather
/// than a black box, so each line can be explained and tested.
class InsightEngine {
  InsightEngine._();

  static List<Insight> generate({
    required List<TransactionModel> all,
    required DateTime month,
    required double budget,
    required String Function(double) money,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final monthTx = Analytics.inMonth(all, month);
    final s = Analytics.summarize(monthTx);
    final prev = Analytics.summarize(Analytics.inMonth(all, Analytics.previousMonth(month)));
    final isCurrent = Analytics.sameMonth(month, today);
    final out = <Insight>[];

    if (s.expense > 0) {
      final breakdown = Analytics.expenseBreakdown(monthTx);
      final top = breakdown.first;
      out.add(Insight(
        Icons.pie_chart_outline,
        '${Categories.byId(top.categoryId).name} is your biggest expense: '
        '${(top.share * 100).round()}% of spending (${money(top.total)}).',
      ));

      if (prev.expense > 0) {
        final change = (s.expense - prev.expense) / prev.expense * 100;
        if (change.abs() >= 1) {
          final up = change > 0;
          out.add(Insight(
            up ? Icons.trending_up : Icons.trending_down,
            'Spending is ${change.abs().round()}% ${up ? 'higher' : 'lower'} than last month.',
            positive: !up,
          ));
        }
      }

      final expenses = monthTx.where((t) => t.isExpense).toList();
      expenses.sort((a, b) => b.amount.compareTo(a.amount));
      final big = expenses.first;
      out.add(Insight(
        Icons.receipt_long,
        'Largest single expense: ${money(big.amount)} on ${Categories.byId(big.categoryId).name}.',
      ));
    }

    if (s.income > 0) {
      final rate = (s.income - s.expense) / s.income * 100;
      if (rate >= 0) {
        out.add(Insight(
          Icons.savings_outlined,
          'You saved ${rate.round()}% of your income this month.',
          positive: rate >= 20,
        ));
      } else {
        out.add(const Insight(
          Icons.warning_amber_rounded,
          'You spent more than you earned this month.',
          positive: false,
        ));
      }
    }

    if (budget > 0) {
      if (s.expense > budget) {
        out.add(Insight(
          Icons.error_outline,
          'Over budget by ${money(s.expense - budget)}.',
          positive: false,
        ));
      } else if (isCurrent) {
        final daysLeft = Analytics.daysInMonth(month) - today.day + 1;
        final perDay = (budget - s.expense) / daysLeft;
        out.add(Insight(
          Icons.flag_outlined,
          'Spend about ${money(perDay)}/day for the remaining $daysLeft days to stay within budget.',
          positive: true,
        ));
      } else if (s.expense > 0) {
        out.add(Insight(
          Icons.check_circle_outline,
          'You stayed within budget with ${money(budget - s.expense)} to spare.',
          positive: true,
        ));
      }
    }

    if (isCurrent && s.expense > 0) {
      final projected = Analytics.projectedExpense(s.expense, month, today);
      if (projected != null) {
        final overBudget = budget > 0 && projected > budget;
        out.add(Insight(
          Icons.timeline,
          'At this pace you will spend about ${money(projected)} by month end'
          '${overBudget ? ', which exceeds your budget.' : '.'}',
          positive: overBudget ? false : null,
        ));
      }
    }
    return out;
  }
}
