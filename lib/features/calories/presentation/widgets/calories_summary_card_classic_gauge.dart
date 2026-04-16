import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints the classic summary half-circle gauge.
class ClassicSummaryGauge extends StatelessWidget {
  /// Creates the classic summary half-circle gauge.
  const ClassicSummaryGauge({
    required this.strokeWidth,
    required this.color,
    required this.consumedKcal,
    required this.baseGoalKcal,
    required this.activityDeltaKcal,
    required this.availableActivityDeltaKcal,
    required this.carryoverKcal,
    required this.availableCarryoverKcal,
    required this.trackColor,
    super.key,
  });

  /// Visual thickness of the gauge stroke.
  final double strokeWidth;

  /// Base goal color used for the main segment.
  final Color color;

  /// Calories consumed so far on the selected day.
  final double consumedKcal;

  /// Base goal calories before optional daily adjustments.
  final double baseGoalKcal;

  /// Activity calories currently included in the classic target.
  final double activityDeltaKcal;

  /// Activity calories available to include in the classic target.
  final double availableActivityDeltaKcal;

  /// Carryover calories currently included in the classic target.
  final double carryoverKcal;

  /// Carryover calories available to include in the classic target.
  final double availableCarryoverKcal;

  /// Track color shown behind each gauge segment.
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ClassicSummaryGaugePainter(
          strokeWidth: strokeWidth,
          trackColor: trackColor,
          segments: _segments,
          consumedKcal: consumedKcal,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  List<_GaugeSegment> get _segments {
    return <_GaugeSegment>[
      _GaugeSegment(
        kcal: _positivePart(baseGoalKcal),
        color: color,
      ),
      if (activityDeltaKcal > 0)
        _GaugeSegment(
          kcal: activityDeltaKcal,
          color: const Color(0xFFF59E0B),
        ),
      if (carryoverKcal > 0)
        _GaugeSegment(
          kcal: carryoverKcal,
          color: const Color(0xFF3B82F6),
        ),
    ];
  }
}

class _ClassicSummaryGaugePainter extends CustomPainter {
  const _ClassicSummaryGaugePainter({
    required this.strokeWidth,
    required this.trackColor,
    required this.segments,
    required this.consumedKcal,
  });

  final double strokeWidth;
  final Color trackColor;
  final List<_GaugeSegment> segments;
  final double consumedKcal;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) {
      return;
    }

    final width = size.width;
    final height = size.height;
    final radius = math.max(1, (width / 2) - strokeWidth - 24).toDouble();
    final center = Offset(width / 2, height * 0.75);
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final totalKcal = segments.fold<double>(0, (sum, segment) {
      return sum + segment.kcal;
    });
    final safeTotalKcal = math.max(1, totalKcal).toDouble();
    final capAngle = strokeWidth / radius;
    final gapAngle = capAngle + 0.028;
    final totalGapAngle = gapAngle * math.max(0, segments.length - 1);
    final totalUsableAngle = math.max(0, math.pi - totalGapAngle).toDouble();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    var currentAngle = math.pi;
    var currentKcal = 0.0;

    for (final segment in segments) {
      final segmentAngle = (segment.kcal / safeTotalKcal) * totalUsableAngle;
      final startAngle = currentAngle;
      final endAngle = currentAngle + math.max(segmentAngle, 0.01);
      final startKcal = currentKcal;
      final endKcal = currentKcal + segment.kcal;

      paint.color = trackColor;
      canvas.drawArc(arcRect, startAngle, endAngle - startAngle, false, paint);

      if (consumedKcal > startKcal) {
        var progressEndAngle = endAngle;
        if (consumedKcal < endKcal && segment.kcal > 0) {
          final progressRatio = (consumedKcal - startKcal) / segment.kcal;
          progressEndAngle =
              startAngle + ((endAngle - startAngle) * progressRatio);
        }

        final shadowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4
          ..strokeCap = StrokeCap.round
          ..color = segment.color.withValues(alpha: 0.16);
        canvas.drawArc(
          arcRect,
          startAngle,
          progressEndAngle - startAngle,
          false,
          shadowPaint,
        );

        paint.color = segment.color;
        canvas.drawArc(
          arcRect,
          startAngle,
          progressEndAngle - startAngle,
          false,
          paint,
        );
      }

      currentAngle = endAngle + gapAngle;
      currentKcal = endKcal;
    }
  }

  @override
  bool shouldRepaint(covariant _ClassicSummaryGaugePainter oldDelegate) {
    return strokeWidth != oldDelegate.strokeWidth ||
        trackColor != oldDelegate.trackColor ||
        consumedKcal != oldDelegate.consumedKcal ||
        segments != oldDelegate.segments;
  }
}

class _GaugeSegment {
  const _GaugeSegment({
    required this.kcal,
    required this.color,
  });

  final double kcal;
  final Color color;
}

double _positivePart(double value) => value > 0 ? value : 0.0;
