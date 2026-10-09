import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moneytrail/core/currency.dart';
import 'package:moneytrail/providers/settings_provider.dart';
import 'package:moneytrail/providers/transaction_provider.dart';
import 'package:moneytrail/services/csv_exporter.dart';
import 'package:provider/provider.dart';

/// Shared by Home (tap on budget bar) and Settings.
Future<void> showBudgetDialog(BuildContext context) {
  return showDialog<void>(context: context, builder: (_) => const _BudgetDialog());
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog();

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final b = context.read<SettingsProvider>().monthlyBudget;
    _controller = TextEditingController(
      text: b <= 0 ? '' : (b == b.roundToDouble() ? b.toStringAsFixed(0) : b.toString()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final v = double.tryParse(_controller.text.trim()) ?? 0;
    context.read<SettingsProvider>().setMonthlyBudget(v);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.read<SettingsProvider>().currency.symbol;
    return AlertDialog(
      title: const Text('Monthly budget'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(
          prefixText: '$symbol ',
          hintText: 'e.g. 30000',
          helperText: 'Leave empty to remove the budget',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final tx = context.watch<TransactionProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _SectionTitle('Budget & currency'),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Monthly budget'),
            subtitle: Text(settings.hasBudget ? settings.money(settings.monthlyBudget) : 'Not set'),
            onTap: () => showBudgetDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: Text('${settings.currency.name} (${settings.currency.symbol})'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: const Text('Choose currency'),
                children: [
                  for (final c in Currency.all)
                    SimpleDialogOption(
                      onPressed: () {
                        settings.setCurrency(c);
                        Navigator.pop(ctx);
                      },
                      child: Text('${c.symbol}  ${c.name}'),
                    ),
                ],
              ),
            ),
          ),
          const _SectionTitle('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
          ),
          const _SectionTitle('Data'),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export as CSV'),
            subtitle: const Text('Copies all transactions to the clipboard'),
            enabled: !tx.isEmpty,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: CsvExporter.build(tx.all)));
              messenger
                ..clearSnackBars()
                ..showSnackBar(const SnackBar(
                  content: Text('CSV copied. Paste it into Excel or Google Sheets.'),
                ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Load demo data'),
            subtitle: const Text('Replaces current data with 4 months of samples'),
            onTap: () async {
              final go = await _confirm(
                context,
                title: 'Load demo data?',
                message: 'This replaces all existing transactions with sample data.',
                action: 'Load',
              );
              if (!go) return;
              await tx.loadSampleData();
              if (context.mounted) _toast(context, 'Demo data loaded');
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
            title: Text('Delete all data', style: TextStyle(color: scheme.error)),
            enabled: !tx.isEmpty,
            onTap: () async {
              final go = await _confirm(
                context,
                title: 'Delete everything?',
                message: 'All transactions will be permanently removed.',
                action: 'Delete',
              );
              if (!go) return;
              await tx.clearAll();
              if (context.mounted) _toast(context, 'All data deleted');
            },
          ),
          const _SectionTitle('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('MoneyTrail 1.0.0'),
            subtitle: Text(
              'Offline-first expense tracker. All data stays on this device.',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
