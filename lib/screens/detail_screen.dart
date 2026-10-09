import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneytrail/core/theme.dart';
import 'package:moneytrail/data/categories.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/providers/settings_provider.dart';
import 'package:moneytrail/providers/transaction_provider.dart';
import 'package:moneytrail/screens/add_edit_screen.dart';
import 'package:moneytrail/widgets/category_avatar.dart';
import 'package:provider/provider.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.transactionId});

  final String transactionId;

  Future<void> _confirmDelete(BuildContext context, TransactionModel t) async {
    final provider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('You can undo this right after.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    navigator.pop();
    provider.delete(t.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Transaction deleted'),
          action: SnackBarAction(label: 'UNDO', onPressed: () => provider.restore(t)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final t = context.watch<TransactionProvider>().byId(transactionId);
    if (t == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: Text('Transaction not found')),
      );
    }

    final category = Categories.byId(t.categoryId);
    final color = t.isExpense ? AppTheme.expense(context) : AppTheme.income(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, t),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  CategoryAvatar(category: category, size: 64),
                  const SizedBox(height: 12),
                  Text(category.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${t.isExpense ? '-' : '+'}${settings.money(t.amount)}',
                      style: TextStyle(color: color, fontSize: 38, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _row(context, Icons.swap_vert, 'Type', t.isExpense ? 'Expense' : 'Income'),
                const Divider(height: 1),
                _row(context, Icons.calendar_month, 'Date',
                    DateFormat('EEE, MMM d, yyyy').format(t.date)),
                const Divider(height: 1),
                _row(context, Icons.access_time, 'Time', DateFormat('h:mm a').format(t.date)),
                const Divider(height: 1),
                _row(context, Icons.notes, 'Note', t.note.isEmpty ? '—' : t.note),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => AddEditScreen(existing: t)),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: swipe a transaction left on the list to delete it quickly.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurface.withAlpha(120), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
