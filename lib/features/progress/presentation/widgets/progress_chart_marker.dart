import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';

/// Draws the start of a goal into a chart: a dashed vertical line from the
/// top to [bottom] at [x], with [label] beside its top.
void paintProgressGoalMarker(
  Canvas canvas, {
  required double x,
  required double bottom,
  required double width,
  required String label,
  required TextStyle? style,
  required Color color,
}) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = AppProgress.thinStroke;
  for (var y = 0.0; y < bottom; y += AppProgress.dash * 2) {
    canvas.drawLine(
      Offset(x, y),
      Offset(x, math.min(y + AppProgress.dash, bottom)),
      paint,
    );
  }
  final text = TextPainter(
    text: TextSpan(
      text: label,
      style: style?.copyWith(color: color),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  // Keep the label inside the chart: right of the line, or left of it at the
  // right edge.
  final left = x + AppProgress.markerLabelGap + text.width > width
      ? x - AppProgress.markerLabelGap - text.width
      : x + AppProgress.markerLabelGap;
  text.paint(canvas, Offset(left, 0));
}
