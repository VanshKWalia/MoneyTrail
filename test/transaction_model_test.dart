import 'package:flutter_test/flutter_test.dart';
import 'package:moneytrail/models/transaction.dart';

void main() {
  test('JSON round trip preserves every field', () {
    final t = TransactionModel(
      id: 'x',
      amount: 12.34,
      type: TxType.income,
      categoryId: 'in_salary',
      date: DateTime(2025, 3, 4, 5, 6),
      note: 'bonus',
    );
    final back = TransactionModel.fromJson(t.toJson());
    expect(back.id, t.id);
    expect(back.amount, t.amount);
    expect(back.type, t.type);
    expect(back.categoryId, t.categoryId);
    expect(back.date, t.date);
    expect(back.note, t.note);
  });

  test('unknown type falls back to expense', () {
    final t = TransactionModel.fromJson({
      'id': '1',
      'amount': 5,
      'type': 'nonsense',
      'categoryId': 'food',
      'date': DateTime(2025, 1, 1).toIso8601String(),
    });
    expect(t.type, TxType.expense);
  });
}
