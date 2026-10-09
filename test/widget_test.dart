import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneytrail/data/transaction_repository.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/providers/settings_provider.dart';
import 'package:moneytrail/providers/transaction_provider.dart';
import 'package:moneytrail/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TransactionProvider> pumpHome(
  WidgetTester tester,
  List<TransactionModel> items,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = (await tester.runAsync(SharedPreferences.getInstance))!;
  final transactions = TransactionProvider(InMemoryTransactionRepository(items));
  await tester.runAsync(transactions.init);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: SettingsProvider(prefs)),
        ChangeNotifierProvider<TransactionProvider>.value(value: transactions),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return transactions;
}

TransactionModel tx(String id, TxType type, String cat, String note) {
  final now = DateTime.now();
  return TransactionModel(
    id: id,
    amount: type == TxType.income ? 5000 : 200,
    type: type,
    categoryId: cat,
    date: DateTime(now.year, now.month, now.day, 9),
    note: note,
  );
}

void main() {
  testWidgets('Income/Expense cards filter the list and toggle back to all',
      (tester) async {
    final provider = await pumpHome(tester, [
      tx('1', TxType.income, 'in_salary', 'Pay day'),
      tx('2', TxType.expense, 'food', 'Lunch out'),
    ]);
    final balanceBefore = provider.summary.balance;

    // Default: everything is shown.
    expect(find.text('Pay day'), findsOneWidget);
    expect(find.text('Lunch out'), findsOneWidget);

    // Income only.
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Pay day'), findsOneWidget);
    expect(find.text('Lunch out'), findsNothing);

    // Tap the selected card again: filter cleared.
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Pay day'), findsOneWidget);
    expect(find.text('Lunch out'), findsOneWidget);

    // Expense only.
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Pay day'), findsNothing);
    expect(find.text('Lunch out'), findsOneWidget);

    // Filtering is display-only: the underlying totals never change.
    expect(provider.summary.balance, balanceBefore);
  });

  testWidgets('shows a type-specific message when nothing matches the filter',
      (tester) async {
    await pumpHome(tester, [
      tx('1', TxType.income, 'in_salary', 'Pay day'),
    ]);

    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();

    expect(find.text('No expense transactions this month'), findsOneWidget);
    expect(find.text('Pay day'), findsNothing);
  });
}
