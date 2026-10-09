import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneytrail/providers/transaction_provider.dart';
import 'package:provider/provider.dart';

/// Previous / next month control. Tap the label to jump back to today's month.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransactionProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous month',
          icon: Icon(Icons.chevron_left, color: color),
          onPressed: p.previousMonth,
        ),
        GestureDetector(
          onTap: p.goToCurrentMonth,
          child: Text(
            DateFormat('MMMM yyyy').format(p.selectedMonth),
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: Icon(Icons.chevron_right, color: color),
          disabledColor: color.withAlpha(70),
          onPressed: p.isCurrentMonth ? null : p.nextMonth,
        ),
      ],
    );
  }
}
