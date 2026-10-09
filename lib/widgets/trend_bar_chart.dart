import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneytrail/services/analytics.dart';

/// Grouped income-vs-expense bars for the last few months (CustomPainter).
class TrendBarChart extends StatelessWidget {
  const TrendBarChart({
    super.key,
    required this.data,
    required this.incomeColor,
    required this.expenseColor,
    this.height = 190,
  });

  final List<MonthSummary> data;
  final Color incomeColor;
  final Color expenseColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _BarPainter(
            data: data,
            progress: t,
            incomeColor: incomeColor,
            expenseColor: expenseColor,
            labelColor: scheme.onSurface.withAlpha(160),
            lineColor: scheme.onSurface.withAlpha(40),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.data,
    required this.progress,
    required this.incomeColor,
    required this.expenseColor,
    required this.labelColor,
    required this.lineColor,
  });

  final List<MonthSummary> data;
  final double progress;
  final Color incomeColor;
  final Color expenseColor;
  final Color labelColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const bottomPad = 24.0;
    const topPad = 8.0;

    final chartH = size.height - bottomPad - topPad;
    final baseY = topPad + chartH;

    var maxV = 0.0;

    for (final m in data) {
      maxV = math.max(maxV, math.max(m.income, m.expense));
    }

    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      Paint()
        ..color = lineColor
        ..strokeWidth = 1,
    );

    final groupW = size.width / data.length;
    final barW = math.min(groupW * 0.26, 22.0);

    final incomePaint = Paint()..color = incomeColor;
    final expensePaint = Paint()..color = expenseColor;

    for (var i = 0; i < data.length; i++) {
      final m = data[i];
      final cx = groupW * i + groupW / 2;

      void bar(double value, double left, Paint paint) {
        if (maxV <= 0 || value <= 0) return;

        final h = math.max(2.0, value / maxV * chartH * progress);

        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, baseY - h, barW, h),
            topLeft: const Radius.circular(6),
            topRight: const Radius.circular(6),
          ),
          paint,
        );
      }

      bar(m.income, cx - barW - 2, incomePaint);
      bar(m.expense, cx + 2, expensePaint);

      final label =
          m.month == null ? '' : DateFormat('MMM').format(m.month!);

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(cx - tp.width / 2, baseY + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) {
    return old.progress != progress || old.data != data;
  }
}