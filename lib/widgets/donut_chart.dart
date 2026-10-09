import 'dart:math' as math;

import 'package:flutter/material.dart';

class DonutSlice {
  const DonutSlice(this.value, this.color);

  final double value;
  final Color color;
}

/// Hand-drawn donut chart (CustomPainter) with an intro sweep animation.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.centerTop,
    required this.centerBottom,
    this.size = 190,
  });

  final List<DonutSlice> slices;
  final String centerTop;
  final String centerBottom;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => CustomPaint(
              size: Size(size, size),
              painter: _DonutPainter(
                slices: slices,
                progress: t,
                trackColor: scheme.onSurface.withAlpha(18),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  centerTop,
                  style: TextStyle(fontSize: 12, color: scheme.onSurface.withAlpha(150)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    centerBottom,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.progress,
    required this.trackColor,
  });

  final List<DonutSlice> slices;
  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = slices.fold<double>(0, (a, s) => a + s.value);
    if (total <= 0) return;

    final gap = slices.length > 1 ? 0.035 : 0.0;
    var start = -math.pi / 2;
    for (final s in slices) {
      final full = s.value / total * math.pi * 2;
      final sweep = math.max(0.0, full * progress - gap);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = s.color;
      if (sweep > 0) {
        canvas.drawArc(rect, start + gap / 2, sweep, false, paint);
      }
      start += full * progress;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.slices != slices || old.trackColor != trackColor;
}
