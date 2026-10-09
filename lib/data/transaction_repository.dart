import 'dart:convert';

import 'package:moneytrail/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage boundary. The rest of the app only knows this interface, so the
/// backing store (SharedPreferences today) can be swapped for SQLite/Firebase
/// without touching providers or UI.
abstract class TransactionRepository {
  Future<List<TransactionModel>> load();
  Future<void> save(List<TransactionModel> items);
}

class SharedPrefsTransactionRepository implements TransactionRepository {
  SharedPrefsTransactionRepository(this._prefs);

  static const _key = 'transactions_v1';
  final SharedPreferences _prefs;

  @override
  Future<List<TransactionModel>> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt payload: start clean rather than crash on launch.
      return [];
    }
  }

  @override
  Future<void> save(List<TransactionModel> items) async {
    await _prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}

/// Used by unit tests.
class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository([List<TransactionModel>? seed])
      : stored = List.of(seed ?? const []);

  List<TransactionModel> stored;

  @override
  Future<List<TransactionModel>> load() async => List.of(stored);

  @override
  Future<void> save(List<TransactionModel> items) async {
    stored = List.of(items);
  }
}
