import 'package:flutter/material.dart';
import 'package:moneytrail/services/expression_evaluator.dart';

/// Calculator-style keypad. Emits raw key strings; the parent owns the state
/// and applies them with [ExpressionInput.press]. Long-press ⌫ to clear.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey, this.onClear});

  final ValueChanged<String> onKey;
  final VoidCallback? onClear;

  static const List<String> keys = [
    '7', '8', '9', '÷',
    '4', '5', '6', '×',
    '1', '2', '3', '-',
    '.', '0', ExpressionInput.backspace, '+',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var r = 0; r < 4; r++)
            Row(
              children: [
                for (var c = 0; c < 4; c++)
                  Expanded(child: _key(context, keys[r * 4 + c], scheme)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _key(BuildContext context, String k, ColorScheme scheme) {
    final isOp = ExpressionInput.isOperator(k);
    final isBack = k == ExpressionInput.backspace;
    final bg = isOp ? scheme.primary : scheme.onSurface.withAlpha(14);
    final fg = isOp ? scheme.onPrimary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onKey(k),
          onLongPress: isBack ? onClear : null,
          child: SizedBox(
            height: 50,
            child: Center(
              child: isBack
                  ? Icon(Icons.backspace_outlined, color: fg, size: 22)
                  : Text(
                      k == '-' ? '−' : k,
                      style: TextStyle(color: fg, fontSize: 24, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
