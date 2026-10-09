import 'package:flutter_test/flutter_test.dart';
import 'package:moneytrail/data/transaction_repository.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/providers/transaction_provider.dart';

TransactionModel make(String id, double amount, {DateTime? date, String note = ''}) =>
    TransactionModel(
      id: id,
      amount: amount,
      type: TxType.expense,
      categoryId: 'food',
      date: date ?? DateTime.now(),
      note: note,
    );

void main() {
  late InMemoryTransactionRepository repo;
  late TransactionProvider provider;

  setUp(() async {
    repo = InMemoryTransactionRepository();
    provider = TransactionProvider(repo);
    await provider.init();
  });

  test('add persists and notifies', () async {
    var notified = 0;
    provider.addListener(() => notified++);
    await provider.add(make('a', 100));
    expect(provider.all.length, 1);
    expect(repo.stored.length, 1);
    expect(notified, greaterThan(0));
  });

  test('delete and restore (undo) round-trip', () async {
    final t = make('a', 100);
    await provider.add(t);
    await provider.delete('a');
    expect(provider.all, isEmpty);
    await provider.restore(t);
    expect(provider.byId('a'), isNotNull);
  });

  test('update replaces the matching transaction', () async {
    await provider.add(make('a', 100));
    await provider.update(make('a', 250, note: 'edited'));
    expect(provider.byId('a')!.amount, 250);
    expect(provider.byId('a')!.note, 'edited');
    expect(provider.all.length, 1);
  });

  test('list is sorted newest first', () async {
    await provider.add(make('old', 1, date: DateTime(2020, 1, 1)));
    await provider.add(make('new', 1, date: DateTime(2021, 1, 1)));
    expect(provider.all.first.id, 'new');
  });

  test('search filters by note and category name', () async {
    await provider.add(make('a', 100, note: 'Pizza night'));
    await provider.add(make('b', 100, note: 'Taxi'));
    provider.setQuery('pizza');
    expect(provider.visibleTransactions.map((t) => t.id), ['a']);
    provider.setQuery('food'); // category name
    expect(provider.visibleTransactions.length, 2);
  });

  test('month navigation cannot go past the current month', () {
    expect(provider.isCurrentMonth, isTrue);
    provider.nextMonth();
    expect(provider.isCurrentMonth, isTrue);
    provider.previousMonth();
    expect(provider.isCurrentMonth, isFalse);
    provider.nextMonth();
    expect(provider.isCurrentMonth, isTrue);
  });

  test('loadSampleData fills the store and clearAll empties it', () async {
    await provider.loadSampleData();
    expect(provider.isEmpty, isFalse);
    await provider.clearAll();
    expect(provider.isEmpty, isTrue);
    expect(repo.stored, isEmpty);
  });

  test('data survives a restart (new provider, same repository)', () async {
    await provider.add(make('a', 100));
    final reopened = TransactionProvider(repo);
    await reopened.init();
    expect(reopened.all.length, 1);
  });
}
