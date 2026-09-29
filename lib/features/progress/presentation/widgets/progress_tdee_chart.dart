import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/progress/domain/progress_tdee.dart';

/// The TDEE as a step line: the start estimate, one square per confirmed
/// check-in, and a dashed run-out to the next check-in.
///
/// A check-in whose new value the user declined shows the calculated value
/// as a hollow muted square next to the kept one.
class ProgressTdeeChart extends StatelessWidget {
  /// Creates the TDEE chart.
  const new({required this.tdee, super.key});

  /// The TDEE progress to draw.
  final ProgressTdee tdee;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return SizedBox(
      height: AppProgress.chartHeight,
      child: CustomPaint(
        size: Size.infinite,
        painter: _TdeeChartPainter(
          tdee: tdee,
          ink: colors.ink,
          muted: colors.muted,
          paper: colors.paper,
        ),
      ),
    );
  }
}

class _TdeeChartPainter extends CustomPainter {
  const new({
    required this.tdee,
    required this.ink,
    required this.muted,
    required this.paper,
  });

  final ProgressTdee tdee;
  final Color ink;
  final Color muted;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final checkIns = tdee.checkIns;
    final start = tdee.startTdeeKcal;
    final values = [
      ?start,
      for (final checkIn in checkIns) ...[
        checkIn.tdeeKcal,
        checkIn.calculatedTdeeKcal,
      ],
    ];
    final baseY = size.height - AppProgress.chartBottomInset;
    const inset = AppProgress.latestPointSize;
    // Slot 0 is the start, then one slot per check-in, then the open week.
    final slots = checkIns.length + 2;
    double x(int slot) => inset / 2 + slot * (size.width - inset) / (slots - 1);
    _paintAxis(canvas, size, baseY, x, checkIns.length);
    if (values.isEmpty) return;

    // Keep a minimum range around the values, so a single value sits in the
    // middle and small changes do not look steep.
    final middle = (values.reduce(math.min) + values.reduce(math.max)) / 2;
    final half = math.max(
      (values.reduce(math.max) - values.reduce(math.min)) / 2,
      AppProgress.tdeeMinRangeKcal / 2,
    );
    final high = middle + half;
    final range = half * 2;
    double y(double kcal) =>
        inset / 2 + (high - kcal) / range * (baseY - inset * 1.5);

    final first = start ?? checkIns.first.tdeeKcal;
    final line = Path()..moveTo(x(0), y(first));
    var previousY = y(first);
    for (final (index, checkIn) in checkIns.indexed) {
      final nextY = y(checkIn.tdeeKcal);
      line
        ..lineTo(x(index + 1), previousY)
        ..lineTo(x(index + 1), nextY);
      previousY = nextY;
    }
    canvas.drawPath(line, _stroke(ink, AppProgress.trendStroke));

    final current = checkIns.lastOrNull?.tdeeKcal ?? first;
    _paintDashed(
      canvas,
      Offset(x(checkIns.length), y(current)),
      Offset(x(slots - 1), y(current)),
      muted,
    );

    for (final (index, checkIn) in checkIns.indexed) {
      final center = Offset(x(index + 1), y(checkIn.tdeeKcal));
      if (checkIn.isRejected) {
        final ghost = Offset(center.dx, y(checkIn.calculatedTdeeKcal));
        _paintDashed(canvas, center, ghost, muted);
        _paintSquare(canvas, ghost, AppProgress.checkInPointSize, muted, true);
      }
      final isLatest = index == checkIns.length - 1;
      _paintSquare(
        canvas,
        center,
        isLatest ? AppProgress.latestPointSize : AppProgress.checkInPointSize,
        ink,
        false,
      );
    }
    if (start != null) {
      _paintSquare(
        canvas,
        Offset(x(0), y(start)),
        AppProgress.checkInPointSize,
        muted,
        true,
      );
    }
  }

  Paint _stroke(Color color, double width) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round;
  }

  void _paintSquare(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
    bool hollow,
  ) {
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    if (hollow) {
      canvas
        ..drawRect(rect, Paint()..color = paper)
        ..drawRect(rect, _stroke(color, AppProgress.baseStroke));
    } else {
      canvas.drawRect(rect, Paint()..color = color);
    }
  }

  void _paintDashed(Canvas canvas, Offset from, Offset to, Color color) {
    final distance = (to - from).distance;
    if (distance == 0) return;
    final direction = (to - from) / distance;
    final paint = _stroke(color, AppProgress.baseStroke);
    for (var d = 0.0; d < distance; d += AppProgress.dash * 2) {
      final end = math.min(d + AppProgress.dash, distance);
      canvas.drawLine(from + direction * d, from + direction * end, paint);
    }
  }

  void _paintAxis(
    Canvas canvas,
    Size size,
    double baseY,
    double Function(int slot) x,
    int checkInCount,
  ) {
    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      _stroke(ink, AppProgress.baseStroke),
    );
    final tick = _stroke(ink, AppProgress.thinStroke);
    for (var slot = 0; slot <= checkInCount; slot++) {
      canvas.drawLine(
        Offset(x(slot), baseY),
        Offset(x(slot), baseY - AppProgress.shortTick),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_TdeeChartPainter oldDelegate) {
    return oldDelegate.tdee != tdee ||
        oldDelegate.ink != ink ||
        oldDelegate.muted != muted ||
        oldDelegate.paper != paper;
  }
}
