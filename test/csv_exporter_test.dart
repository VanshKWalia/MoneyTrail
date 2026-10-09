import 'package:flutter_test/flutter_test.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/services/csv_exporter.dart';

void main() {
  test('writes a header and one row per transaction, oldest first', () {
    final csv = CsvExporter.build([
      TransactionModel(
        id: '2',
        amount: 20,
        type: TxType.income,
        categoryId: 'in_salary',
        date: DateTime(2025, 1, 2, 9, 5),
      ),
      TransactionModel(
        id: '1',
        amount: 10.5,
        type: TxType.expense,
        categoryId: 'food',
        date: DateTime(2025, 1, 1, 13, 30),
        note: 'Lunch',
      ),
    ]);
    final lines = csv.trim().split('\n');
    expect(lines[0], 'Date,Time,Type,Category,Amount,Note');
    expect(lines[1], '2025-01-01,13:30,expense,Food,10.50,Lunch');
    expect(lines[2], '2025-01-02,09:05,income,Salary,20.00,');
  });

  test('escapes commas and quotes', () {
    final csv = CsvExporter.build([
      TransactionModel(
        id: '1',
        amount: 1,
        type: TxType.expense,
        categoryId: 'food',
        date: DateTime(2025, 1, 1),
        note: 'He said "hi", twice',
      ),
    ]);
    expect(csv.contains('"He said ""hi"", twice"'), isTrue);
  });
}
