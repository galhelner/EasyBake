import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dashboard_types.dart';

class DashboardHealthPieChartPainter extends CustomPainter {
  const DashboardHealthPieChartPainter({required this.slices});

  final List<DashboardHealthSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE9F1F8);
    canvas.drawCircle(center, radius, basePaint);

    final total = slices.fold<int>(0, (sum, slice) => sum + slice.count);
    if (total == 0) {
      return;
    }

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      if (slice.count == 0) {
        continue;
      }

      final sweep = (slice.count / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = slice.color;

      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;

    var dividerAngle = -math.pi / 2;
    for (final slice in slices) {
      if (slice.count == 0) {
        continue;
      }

      final x = center.dx + radius * math.cos(dividerAngle);
      final y = center.dy + radius * math.sin(dividerAngle);
      canvas.drawLine(center, Offset(x, y), borderPaint);
      dividerAngle += (slice.count / total) * math.pi * 2;
    }

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant DashboardHealthPieChartPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}