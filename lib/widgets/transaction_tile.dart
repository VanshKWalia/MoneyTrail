import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneytrail/core/theme.dart';
import 'package:moneytrail/data/categories.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/providers/settings_provider.dart';
import 'package:moneytrail/widgets/category_avatar.dart';
import 'package:provider/provider.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, required this.onTap});

  final TransactionModel transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final category = Categories.byId(transaction.categoryId);
    final scheme = Theme.of(context).colorScheme;
    final color = transaction.isExpense
        ? AppTheme.expense(context)
        : AppTheme.income(context);
    final sign = transaction.isExpense ? '-' : '+';
    final subtitle = transaction.note.isEmpty
        ? DateFormat('h:mm a').format(transaction.date)
        : transaction.note;

    return ListTile(
      onTap: onTap,
      leading: CategoryAvatar(category: category),
      title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.onSurface.withAlpha(150)),
      ),
      trailing: Text(
        '$sign${settings.money(transaction.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
