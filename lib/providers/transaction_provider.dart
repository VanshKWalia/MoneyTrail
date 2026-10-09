import 'package:flutter/foundation.dart';
import 'package:moneytrail/data/categories.dart';
import 'package:moneytrail/data/sample_data.dart';
import 'package:moneytrail/data/transaction_repository.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/services/analytics.dart';

/// Single source of truth for transactions + which month the UI is looking at.
class TransactionProvider extends ChangeNotifier {
  TransactionProvider(this._repo) {
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
  }

  final TransactionRepository _repo;
  List<TransactionModel> _all = [];
  late DateTime _month;
  String _query = '';

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> init() async {
    _all = await _repo.load();
    _sort();
    notifyListeners();
  }

  // ---- reads -------------------------------------------------------------
  List<TransactionModel> get all => List.unmodifiable(_all);
  bool get isEmpty => _all.isEmpty;
  DateTime get selectedMonth => _month;
  String get query => _query;

  bool get isCurrentMonth {
    final n = DateTime.now();
    return !_month.isBefore(DateTime(n.year, n.month));
  }

  List<TransactionModel> get monthTransactions => Analytics.inMonth(_all, _month);

  /// Month transactions after applying the search query.
  List<TransactionModel> get visibleTransactions {
    final txs = monthTransactions;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return txs;
    return txs.where((t) {
      return t.note.toLowerCase().contains(q) ||
          Categories.byId(t.categoryId).name.toLowerCase().contains(q);
    }).toList();
  }

  MonthSummary get summary => Analytics.summarize(monthTransactions, _month);

  TransactionModel? byId(String id) {
    for (final t in _all) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ---- navigation / filter -----------------------------------------------
  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void previousMonth() {
    _month = DateTime(_month.year, _month.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    if (isCurrentMonth) return;
    _month = DateTime(_month.year, _month.month + 1);
    notifyListeners();
  }

  void goToCurrentMonth() {
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
    notifyListeners();
  }

  void showMonthOf(DateTime d) {
    _month = DateTime(d.year, d.month);
    notifyListeners();
  }

  // ---- writes ------------------------------------------------------------
  Future<void> add(TransactionModel t) async {
    _all.add(t);
    await _commit();
  }

  Future<void> update(TransactionModel t) async {
    final i = _all.indexWhere((e) => e.id == t.id);
    if (i == -1) return;
    _all[i] = t;
    await _commit();
  }

  Future<void> delete(String id) async {
    _all.removeWhere((e) => e.id == id);
    await _commit();
  }

  /// Used by the "Undo" snackbar.
  Future<void> restore(TransactionModel t) => add(t);

  Future<void> clearAll() async {
    _all = [];
    await _commit();
  }

  Future<void> loadSampleData() async {
    _all = SampleData.generate();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
    await _commit();
  }

  Future<void> _commit() async {
    _sort();
    notifyListeners();
    await _repo.save(_all);
  }

  void _sort() => _all.sort((a, b) => b.date.compareTo(a.date));
}
