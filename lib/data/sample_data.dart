import 'dart:math';

import 'package:moneytrail/models/transaction.dart';

/// Deterministic demo data so the app looks alive in a demo/interview.
class SampleData {
  SampleData._();

  static const _notes = <String, List<String>>{
    'food': ['Lunch with team', 'Dinner out', 'Food delivery', 'Breakfast', 'Cafe'],
    'transportation': ['Metro card recharge', 'Auto fare', 'Cab ride', 'Petrol'],
    'snacks': ['Chips & cola', 'Evening chai', 'Ice cream'],
    'vegetables': ['Weekly sabzi', 'Local market'],
    'entertainment': ['Movie tickets', 'Streaming subscription', 'Gaming'],
    'shopping': ['Online order', 'Headphones', 'Household items', 'Shoes'],
    'health': ['Pharmacy', 'Doctor visit', 'Gym supplements'],
    'travel': ['Weekend trip', 'Train tickets'],
  };

  static List<TransactionModel> generate({DateTime? now, int months = 4}) {
    final today = now ?? DateTime.now();
    final rnd = Random(7);
    final out = <TransactionModel>[];
    var seq = 0;

    void add(DateTime d, TxType t, String cat, int amount, String note) {
      if (d.isAfter(today)) return;
      out.add(TransactionModel(
        id: 'sample_${seq++}',
        amount: amount.toDouble(),
        type: t,
        categoryId: cat,
        date: d,
        note: note,
      ));
    }

    for (var m = months - 1; m >= 0; m--) {
      final first = DateTime(today.year, today.month - m, 1);
      final y = first.year;
      final mo = first.month;
      final days = DateTime(y, mo + 1, 0).day;

      add(DateTime(y, mo, 1, 9, 30), TxType.income, 'in_salary', 65000, 'Monthly salary');
      if (m.isEven) {
        add(DateTime(y, mo, 12, 18, 0), TxType.income, 'in_freelance',
            4000 + rnd.nextInt(8000), 'Freelance project');
      }
      add(DateTime(y, mo, 20, 11, 0), TxType.income, 'in_investment', 1500, 'Dividend');

      add(DateTime(y, mo, 3, 10, 0), TxType.expense, 'home', 18000, 'House rent');
      add(DateTime(y, mo, 5, 12, 0), TxType.expense, 'bills',
          1800 + rnd.nextInt(800), 'Electricity bill');
      add(DateTime(y, mo, 7, 9, 0), TxType.expense, 'telephone', 599, 'Mobile recharge');
      add(DateTime(y, mo, 10, 14, 0), TxType.expense, 'insurance', 2100, 'Health insurance');

      for (var d = 1; d <= days; d++) {
        DateTime at() => DateTime(y, mo, d, 8 + rnd.nextInt(14), rnd.nextInt(60));
        String note(String cat) {
          final list = _notes[cat]!;
          return list[rnd.nextInt(list.length)];
        }

        if (rnd.nextDouble() < 0.70) {
          add(at(), TxType.expense, 'food', 120 + rnd.nextInt(430), note('food'));
        }
        if (rnd.nextDouble() < 0.50) {
          add(at(), TxType.expense, 'transportation', 40 + rnd.nextInt(260),
              note('transportation'));
        }
        if (rnd.nextDouble() < 0.25) {
          add(at(), TxType.expense, 'snacks', 30 + rnd.nextInt(150), note('snacks'));
        }
        if (rnd.nextDouble() < 0.20) {
          add(at(), TxType.expense, 'vegetables', 150 + rnd.nextInt(300),
              note('vegetables'));
        }
        if (rnd.nextDouble() < 0.08) {
          add(at(), TxType.expense, 'entertainment', 200 + rnd.nextInt(700),
              note('entertainment'));
        }
        if (rnd.nextDouble() < 0.06) {
          add(at(), TxType.expense, 'shopping', 500 + rnd.nextInt(3000),
              note('shopping'));
        }
        if (rnd.nextDouble() < 0.04) {
          add(at(), TxType.expense, 'health', 200 + rnd.nextInt(1300), note('health'));
        }
        if (rnd.nextDouble() < 0.03) {
          add(at(), TxType.expense, 'travel', 800 + rnd.nextInt(2500), note('travel'));
        }
      }
    }
    return out;
  }
}
