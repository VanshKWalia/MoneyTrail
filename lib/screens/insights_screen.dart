import 'package:flutter/material.dart';
import 'package:moneytrail/core/theme.dart';
import 'package:moneytrail/data/categories.dart';
import 'package:moneytrail/models/transaction.dart';
import 'package:moneytrail/providers/settings_provider.dart';
import 'package:moneytrail/providers/transaction_provider.dart';
import 'package:moneytrail/services/analytics.dart';
import 'package:moneytrail/services/insight_engine.dart';
import 'package:moneytrail/widgets/donut_chart.dart';
import 'package:moneytrail/widgets/empty_state.dart';
import 'package:moneytrail/widgets/month_switcher.dart';
import 'package:moneytrail/widgets/trend_bar_chart.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final month = tx.selectedMonth;
    final monthTx = tx.monthTransactions;
    final summary = tx.summary;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: tx.isEmpty
          ? const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No data to analyse yet',
              message: 'Add some transactions (or load demo data from the Transactions tab) to see charts and insights.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                MonthSwitcher(color: scheme.onSurface),
                if (monthTx.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'Nothing recorded this month',
                    ),
                  )
                else ...[
                  _statTiles(context, tx, settings, summary, month, now),
                  const SizedBox(height: 12),
                  _breakdownCard(context, settings, monthTx, summary.expense, month),
                  const SizedBox(height: 12),
                  _trendCard(context, tx, settings, month),
                  const SizedBox(height: 12),
                  _insightsCard(context, tx, settings, month),
                ],
              ],
            ),
    );
  }

  Widget _statTiles(
    BuildContext context,
    TransactionProvider tx,
    SettingsProvider settings,
    MonthSummary s,
    DateTime month,
    DateTime now,
  ) {
    final prev = Analytics.summarize(
        Analytics.inMonth(tx.all, Analytics.previousMonth(month)));
    String? changeText;
    Color? changeColor;
    if (prev.expense > 0) {
      final change = (s.expense - prev.expense) / prev.expense * 100;
      final up = change > 0;
      changeText = '${up ? '▲' : '▼'} ${change.abs().round()}% vs last month';
      changeColor = up ? AppTheme.expense(context) : AppTheme.income(context);
    }
    final projected = Analytics.projectedExpense(s.expense, month, now);
    final avg = Analytics.dailyAverage(s.expense, month, now);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                title: 'Spent',
                value: settings.money(s.expense),
                subtitle: changeText,
                subtitleColor: changeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                title: 'Net savings',
                value: settings.money(s.balance),
                valueColor: s.balance >= 0
                    ? AppTheme.income(context)
                    : AppTheme.expense(context),
                subtitle: 'Income ${settings.money(s.income)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                title: 'Daily average',
                value: settings.money(avg),
                subtitle: 'Spending per day',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: projected != null
                  ? _StatTile(
                      title: 'Projected spend',
                      value: settings.money(projected),
                      subtitle: 'By end of month',
                    )
                  : _StatTile(
                      title: 'Transactions',
                      value: '${s.count}',
                      subtitle: 'This month',
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _breakdownCard(
    BuildContext context,
    SettingsProvider settings,
    List<TransactionModel> monthTx,
    double totalExpense,
    DateTime month,
  ) {
    final breakdown = Analytics.expenseBreakdown(monthTx);
    if (breakdown.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No expenses this month.'),
        ),
      );
    }

    // Top 6 categories + one merged "Other" slice.
    final top = breakdown.take(6).toList();
    final restTotal = breakdown.skip(6).fold<double>(0, (a, b) => a + b.total);
    final entries = <_LegendEntry>[
      for (var i = 0; i < top.length; i++)
        _LegendEntry(
          Categories.byId(top[i].categoryId).name,
          top[i].total,
          top[i].share,
          AppTheme.chartPalette[i],
        ),
      if (restTotal > 0)
        _LegendEntry(
          'Other categories',
          restTotal,
          restTotal / totalExpense,
          AppTheme.chartPalette[6],
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spending by category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Center(
              child: DonutChart(
                key: ValueKey('donut-${month.year}-${month.month}'),
                slices: [for (final e in entries) DonutSlice(e.total, e.color)],
                centerTop: 'Total spent',
                centerBottom: settings.money(totalExpense),
              ),
            ),
            const SizedBox(height: 16),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: e.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.label)),
                    Text(
                      '${(e.share * 100).round()}%',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 84,
                      child: Text(
                        settings.money(e.total),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _trendCard(
    BuildContext context,
    TransactionProvider tx,
    SettingsProvider settings,
    DateTime month,
  ) {
    final data = Analytics.trailing(tx.all, month, 6);
    final income = AppTheme.income(context);
    final expense = AppTheme.expense(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last 6 months', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _dot(income),
                const SizedBox(width: 6),
                const Text('Income'),
                const SizedBox(width: 16),
                _dot(expense),
                const SizedBox(width: 6),
                const Text('Expense'),
              ],
            ),
            const SizedBox(height: 16),
            TrendBarChart(
              key: ValueKey('trend-${month.year}-${month.month}'),
              data: data,
              incomeColor: income,
              expenseColor: expense,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
      );

  Widget _insightsCard(
    BuildContext context,
    TransactionProvider tx,
    SettingsProvider settings,
    DateTime month,
  ) {
    final insights = InsightEngine.generate(
      all: tx.all,
      month: month,
      budget: settings.monthlyBudget,
      money: settings.money,
    );
    if (insights.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Smart insights', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            for (final i in insights)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      i.icon,
                      size: 22,
                      color: i.positive == null
                          ? scheme.primary
                          : i.positive!
                              ? AppTheme.income(context)
                              : AppTheme.expense(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(i.text, style: const TextStyle(height: 1.3))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendEntry {
  const _LegendEntry(this.label, this.total, this.share, this.color);

  final String label;
  final double total;
  final double share;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.subtitleColor,
  });

  final String title;
  final String value;
  final Color? valueColor;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: scheme.onSurface.withAlpha(150), fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor ?? scheme.onSurface.withAlpha(130),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
