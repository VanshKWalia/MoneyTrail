import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneytrail/core/theme.dart';
import 'package:moneytrail/data/categories.dart';
import 'package:moneytrail/models/category.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/providers/settings_provider.dart';
import 'package:moneytrail/providers/transaction_provider.dart';
import 'package:moneytrail/services/expression_evaluator.dart';
import 'package:moneytrail/widgets/amount_keypad.dart';
import 'package:moneytrail/widgets/category_avatar.dart';
import 'package:provider/provider.dart';

/// Add a new transaction, or edit [existing] when provided.
class AddEditScreen extends StatefulWidget {
  const AddEditScreen({super.key, this.existing});

  final TransactionModel? existing;

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  late TxType _type;
  String? _categoryId;
  late DateTime _date;
  late String _expression;
  final TextEditingController _note = TextEditingController();
  final FocusNode _noteFocus = FocusNode();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? TxType.expense;
    _categoryId = e?.categoryId;
    _date = e?.date ?? DateTime.now();
    _expression = e == null ? '' : _plain(e.amount);
    _note.text = e?.note ?? '';
    _noteFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _note.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(_date.year, _date.month, _date.day, picked.hour, picked.minute);
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _save() {
    final value = ExpressionEvaluator.tryEvaluateLenient(_expression);
    if (value == null || value <= 0) {
      _toast('Enter an amount greater than zero');
      return;
    }
    if (_categoryId == null) {
      _toast('Pick a category');
      return;
    }
    final tx = TransactionModel(
      id: widget.existing?.id ?? TransactionProvider.newId(),
      amount: (value * 100).round() / 100,
      type: _type,
      categoryId: _categoryId!,
      date: _date,
      note: _note.text.trim(),
    );
    final provider = context.read<TransactionProvider>();
    if (_isEdit) {
      provider.update(tx);
    } else {
      provider.add(tx);
    }
    provider.showMonthOf(tx.date);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final preview = ExpressionEvaluator.tryEvaluateLenient(_expression);
    final color = _type == TxType.expense
        ? AppTheme.expense(context)
        : AppTheme.income(context);
    final categories = Categories.forType(_type);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit transaction' : 'Add transaction')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<TxType>(
                  segments: const [
                    ButtonSegment<TxType>(
                      value: TxType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.north_east),
                    ),
                    ButtonSegment<TxType>(
                      value: TxType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.south_west),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() {
                    _type = s.first;
                    if (_categoryId != null && Categories.byId(_categoryId!).type != _type) {
                      _categoryId = null;
                    }
                  }),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression.isEmpty ? ' ' : _expression,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurface.withAlpha(150), fontSize: 15),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      settings.money(preview ?? 0),
                      style: TextStyle(color: color, fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.9,
                        children: [
                          for (final c in categories) _categoryTile(c, scheme),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.calendar_month, size: 18),
                            label: Text(DateFormat('EEE, MMM d, yyyy').format(_date)),
                            onPressed: _pickDate,
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.access_time, size: 18),
                            label: Text(DateFormat('h:mm a').format(_date)),
                            onPressed: _pickTime,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _note,
                        focusNode: _noteFocus,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.edit_note),
                          labelText: 'Note (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_noteFocus.hasFocus)
              AmountKeypad(
                onKey: (k) => setState(() => _expression = ExpressionInput.press(_expression, k)),
                onClear: () => setState(() => _expression = ''),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(_isEdit ? 'Save changes' : 'Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTile(Category c, ColorScheme scheme) {
    final selected = c.id == _categoryId;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _categoryId = c.id);
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? scheme.primary.withAlpha(30) : Colors.transparent,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CategoryAvatar(category: c, size: 40),
            const SizedBox(height: 4),
            Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
