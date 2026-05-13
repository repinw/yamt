import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Sparkline painter for compact diary metric cards.
class DiaryMetricSparklinePainter extends CustomPainter {
  /// Creates a metric sparkline painter.
  const DiaryMetricSparklinePainter({
    required this.values,
    required this.color,
    required this.backgroundColor,
  });

  /// Seven day metric values.
  final List<double?> values;

  /// Sparkline color.
  final Color color;

  /// Dot fill color.
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final indexedValues = <({int index, double value})>[
      for (var index = 0; index < values.length; index += 1)
        if (values[index] != null) (index: index, value: values[index]!),
    ];
    if (indexedValues.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final minValue = indexedValues.map((point) => point.value).reduce(math.min);
    final maxValue = indexedValues.map((point) => point.value).reduce(math.max);
    final valueRange = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;
    final path = Path();

    for (
      var pointIndex = 0;
      pointIndex < indexedValues.length;
      pointIndex += 1
    ) {
      final point = indexedValues[pointIndex];
      final x = values.length <= 1
          ? 0.0
          : (point.index / (values.length - 1)) * size.width;
      final y =
          size.height -
          ((point.value - minValue) / valueRange) * (size.height - 8) -
          4;
      if (pointIndex == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final lastPoint = indexedValues.last;
    final lastX = (lastPoint.index / (values.length - 1)) * size.width;
    final lastY =
        size.height -
        ((lastPoint.value - minValue) / valueRange) * (size.height - 8) -
        4;
    final dotFill = Paint()..color = backgroundColor;
    final dotStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas
      ..drawCircle(Offset(lastX, lastY), 3.2, dotFill)
      ..drawCircle(Offset(lastX, lastY), 3.2, dotStroke);
  }

  @override
  bool shouldRepaint(covariant DiaryMetricSparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
