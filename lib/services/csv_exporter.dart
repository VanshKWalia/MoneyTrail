import 'package:intl/intl.dart';
import 'package:moneytrail/data/categories.dart';
import 'package:moneytrail/models/transaction.dart';

class CsvExporter {
  CsvExporter._();

  static String build(Iterable<TransactionModel> txs) {
    final date = DateFormat('yyyy-MM-dd');
    final time = DateFormat('HH:mm');
    final sorted = txs.toList()..sort((a, b) => a.date.compareTo(b.date));
    final buf = StringBuffer('Date,Time,Type,Category,Amount,Note\n');
    for (final t in sorted) {
      buf.writeln([
        date.format(t.date),
        time.format(t.date),
        t.type.name,
        _escape(Categories.byId(t.categoryId).name),
        t.amount.toStringAsFixed(2),
        _escape(t.note),
      ].join(','));
    }
    return buf.toString();
  }

  /// RFC 4180: wrap in quotes when needed and double any embedded quotes.
  static String _escape(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
