import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneytrail/core/theme.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/providers/settings_provider.dart';
import 'package:moneytrail/providers/transaction_provider.dart';
import 'package:moneytrail/screens/add_edit_screen.dart';
import 'package:moneytrail/screens/detail_screen.dart';
import 'package:moneytrail/screens/settings_screen.dart';
import 'package:moneytrail/widgets/empty_state.dart';
import 'package:moneytrail/widgets/month_switcher.dart';
import 'package:moneytrail/widgets/transaction_tile.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();
  bool _searching = false;

  /// null = show everything; otherwise only this type is listed.
  /// Display-only: the summary numbers and budget are never affected.
  TxType? _filter;

  @override
  void initState() {
    super.initState();
    // Restore search UI if a query is still active (e.g. after switching tabs).
    final q = context.read<TransactionProvider>().query;
    _searching = q.isNotEmpty;
    _search.text = q;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    final tx = context.read<TransactionProvider>();
    setState(() => _searching = !_searching);
    if (!_searching) {
      _search.clear();
      tx.setQuery('');
    }
  }

  /// Tapping the active card again clears the filter.
  void _toggleFilter(TxType type) {
    setState(() => _filter = _filter == type ? null : type);
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final summary = tx.summary;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context, tx, settings, scheme, summary.balance, summary.income, summary.expense),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    // Keyed by the filter so only filter changes animate,
                    // not deletes, searches or month changes.
                    child: KeyedSubtree(
                      key: ValueKey<TxType?>(_filter),
                      child: _body(context, tx),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    TransactionProvider tx,
    SettingsProvider settings,
    ColorScheme scheme,
    double balance,
    double income,
    double expense,
  ) {
    final on = scheme.onPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _searching
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: TextField(
                          controller: _search,
                          autofocus: true,
                          onChanged: tx.setQuery,
                          cursorColor: on,
                          style: TextStyle(color: on, fontSize: 17),
                          decoration: InputDecoration(
                            hintText: 'Search notes or categories',
                            hintStyle: TextStyle(color: on.withAlpha(150)),
                            border: InputBorder.none,
                          ),
                        ),
                      )
                    : MonthSwitcher(color: on),
              ),
              IconButton(
                tooltip: _searching ? 'Close search' : 'Search',
                icon: Icon(_searching ? Icons.close : Icons.search, color: on),
                onPressed: _toggleSearch,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('Balance', style: TextStyle(color: on.withAlpha(190))),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                settings.money(balance),
                style: TextStyle(color: on, fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statChip(
                  on,
                  Icons.south_west,
                  'Income',
                  settings.money(income),
                  selected: _filter == TxType.income,
                  onTap: () => _toggleFilter(TxType.income),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statChip(
                  on,
                  Icons.north_east,
                  'Expense',
                  settings.money(expense),
                  selected: _filter == TxType.expense,
                  onTap: () => _toggleFilter(TxType.expense),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _budget(context, settings, scheme, expense),
        ],
      ),
    );
  }

  Widget _statChip(
    Color on,
    IconData icon,
    String label,
    String value, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: on.withAlpha(selected ? 64 : 32),
          borderRadius: BorderRadius.circular(16),
          // Constant width (transparent when idle) so the card never shifts.
          border: Border.all(
            color: selected ? on.withAlpha(200) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, color: on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(color: on.withAlpha(190), fontSize: 12)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            style: TextStyle(color: on, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _budget(
    BuildContext context,
    SettingsProvider settings,
    ColorScheme scheme,
    double spent,
  ) {
    final on = scheme.onPrimary;
    if (!settings.hasBudget) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: on),
          onPressed: () => showBudgetDialog(context),
          icon: const Icon(Icons.flag_outlined, size: 18),
          label: const Text('Set a monthly budget'),
        ),
      );
    }
    final budget = settings.monthlyBudget;
    final ratio = spent / budget;
    final Color bar = ratio >= 1
        ? const Color(0xFFFF8A80)
        : ratio >= 0.75
            ? const Color(0xFFFFD54F)
            : on;
    final remaining = budget - spent;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showBudgetDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Budget', style: TextStyle(color: on.withAlpha(190), fontSize: 12)),
                const Spacer(),
                Text(
                  '${(ratio * 100).round()}% used',
                  style: TextStyle(color: on.withAlpha(190), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: on.withAlpha(40),
                valueColor: AlwaysStoppedAnimation<Color>(bar),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              remaining >= 0
                  ? '${settings.money(remaining)} left of ${settings.money(budget)}'
                  : 'Over budget by ${settings.money(-remaining)}',
              style: TextStyle(color: on, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TransactionProvider tx) {
    if (tx.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions yet',
        message: 'Add your first expense, or load demo data to explore the app.',
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AddEditScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add transaction'),
          ),
          OutlinedButton.icon(
            onPressed: tx.loadSampleData,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Load demo data'),
          ),
        ],
      );
    }

    // Month + search come from the provider; the type filter is applied on top.
    final filter = _filter;
    final matches = tx.visibleTransactions;
    final visible = filter == null
        ? matches
        : matches.where((t) => t.type == filter).toList();
    if (visible.isEmpty) {
      if (filter != null) {
        final label = filter == TxType.income ? 'income' : 'expense';
        return EmptyState(
          icon: filter == TxType.income ? Icons.south_west : Icons.north_east,
          title: 'No $label transactions this month',
          message: tx.query.isEmpty ? null : 'Try a different search term.',
        );
      }
      return EmptyState(
        icon: tx.query.isEmpty ? Icons.event_busy_outlined : Icons.search_off,
        title: tx.query.isEmpty ? 'Nothing this month' : 'No matches',
        message: tx.query.isEmpty
            ? 'No transactions recorded for this month.'
            : 'Try a different search term.',
      );
    }

    final rows = <_Row>[];
    String? lastKey;
    for (final t in visible) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      if (key != lastKey) {
        final dayTx = visible.where((e) => DateFormat('yyyy-MM-dd').format(e.date) == key);
        var net = 0.0;
        for (final e in dayTx) {
          net += e.isExpense ? -e.amount : e.amount;
        }
        rows.add(_Row.header(t.date, net));
        lastKey = key;
      }
      rows.add(_Row.tx(t));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        if (row.transaction == null) {
          return _dayHeader(context, row.date!, row.net);
        }
        final t = row.transaction!;
        return Dismissible(
          key: ValueKey(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: AppTheme.expense(context).withAlpha(60),
            child: Icon(Icons.delete_outline, color: AppTheme.expense(context)),
          ),
          onDismissed: (_) {
            final provider = context.read<TransactionProvider>();
            final messenger = ScaffoldMessenger.of(context);
            provider.delete(t.id);
            messenger
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: const Text('Transaction deleted'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () => provider.restore(t),
                  ),
                ),
              );
          },
          child: TransactionTile(
            transaction: t,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => DetailScreen(transactionId: t.id)),
            ),
          ),
        );
      },
    );
  }

  Widget _dayHeader(BuildContext context, DateTime date, double net) {
    final settings = context.read<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    String label;
    if (_sameDay(date, today)) {
      label = 'Today';
    } else if (_sameDay(date, yesterday)) {
      label = 'Yesterday';
    } else {
      label = DateFormat('EEE, MMM d').format(date);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withAlpha(170),
            ),
          ),
          const Spacer(),
          Text(
            '${net >= 0 ? '+' : '-'}${settings.money(net.abs())}',
            style: TextStyle(color: scheme.onSurface.withAlpha(140), fontSize: 13),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Row {
  _Row.header(this.date, this.net) : transaction = null;
  _Row.tx(TransactionModel t)
      : transaction = t,
        date = null,
        net = 0;

  final TransactionModel? transaction;
  final DateTime? date;
  final double net;
}
