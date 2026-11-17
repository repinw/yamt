import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_week_card_constants.dart';

/// Paints a dashed outline inside its box: the empty field of a coming day and
/// the extra piece of a day with more budget.
class DiaryWeekDashedPainter extends CustomPainter {
  /// Creates a painter with a dashed outline in [color] and corners of
  /// [radius].
  const new({required this.color, required this.radius});

  /// Color of the dashes.
  final Color color;

  /// Corner radius of the outline.
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AppWeekCard.outlineWidth / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - AppWeekCard.outlineWidth,
            size.height - AppWeekCard.outlineWidth,
          ),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppWeekCard.outlineWidth;
    for (final metric in outline.computeMetrics()) {
      for (
        var at = 0.0;
        at < metric.length;
        at += AppWeekCard.dashLength + AppWeekCard.dashGap
      ) {
        canvas.drawPath(
          metric.extractPath(at, at + AppWeekCard.dashLength),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DiaryWeekDashedPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Paints the hatching of a pause day over [background].
class DiaryWeekHatchPainter extends CustomPainter {
  /// Creates a painter with stripes in [color] on [background].
  const new({required this.color, required this.background});

  /// Color of the stripes.
  final Color color;

  /// Color of the field under the stripes.
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final stripe = Paint()
      ..color = color
      ..strokeWidth = AppWeekCard.hatchStroke;
    for (var x = -size.height; x < size.width; x += AppWeekCard.hatchSpacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(DiaryWeekHatchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.background != background;
}
