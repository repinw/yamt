import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/progress/domain/progress_tdee.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_chart_marker.dart';

/// One column of the TDEE chart: the start of a goal or one check-in.
typedef _Slot = ({double? kcal, double? ghostKcal, bool isGoalStart});

/// The TDEE as a step line: per goal the start estimate and one square per
/// confirmed check-in, then a dashed run-out to the next check-in.
///
/// A check-in whose new value the user declined shows the calculated value
/// as a hollow muted square next to the kept one. With several goals, a
/// dashed line with the goal's label marks where each goal starts.
class ProgressTdeeChart extends StatelessWidget {
  /// Creates the TDEE chart.
  const new({required this.tdee, required this.goalLabel, super.key});

  /// The TDEE progress to draw.
  final ProgressTdee tdee;

  /// Label of the goal with the given number, such as "Ziel 2".
  final String Function(int number) goalLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return SizedBox(
      height: AppProgress.chartHeight,
      child: CustomPaint(
        size: Size.infinite,
        painter: _TdeeChartPainter(
          slots: _slots(tdee),
          goalLabels: [
            for (var index = 0; index < tdee.goals.length; index++)
              goalLabel(tdee.firstGoalNumber + index),
          ],
          ink: colors.ink,
          muted: colors.muted,
          paper: colors.paper,
          labelStyle: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }

  static List<_Slot> _slots(ProgressTdee tdee) {
    return [
      for (final goal in tdee.goals) ...[
        (kcal: goal.startTdeeKcal, ghostKcal: null, isGoalStart: true),
        for (final checkIn in goal.checkIns)
          (
            kcal: checkIn.tdeeKcal,
            ghostKcal: checkIn.isRejected ? checkIn.calculatedTdeeKcal : null,
            isGoalStart: false,
          ),
      ],
    ];
  }
}

class _TdeeChartPainter extends CustomPainter {
  const new({
    required this.slots,
    required this.goalLabels,
    required this.ink,
    required this.muted,
    required this.paper,
    required this.labelStyle,
  });

  final List<_Slot> slots;
  final List<String> goalLabels;
  final Color ink;
  final Color muted;
  final Color paper;
  final TextStyle? labelStyle;

  bool get _hasMarkers => goalLabels.length > 1;

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height - AppProgress.chartBottomInset;
    const inset = AppProgress.latestPointSize;
    // One column per slot, plus one for the week up to the next check-in.
    final columns = slots.length + 1;
    double x(int column) =>
        inset / 2 + column * (size.width - inset) / math.max(columns - 1, 1);
    _paintAxis(canvas, size, baseY, x);
    _paintMarkers(canvas, size, baseY, x);
    final values = [
      for (final slot in slots) ...[?slot.kcal, ?slot.ghostKcal],
    ];
    if (values.isEmpty) return;

    // Keep a minimum range around the values, so a single value sits in the
    // middle and small changes do not look steep.
    final high = values.reduce(math.max);
    final low = values.reduce(math.min);
    final half = math.max((high - low) / 2, AppProgress.tdeeMinRangeKcal / 2);
    final top = (_hasMarkers ? AppProgress.markerLabelSpace : inset / 2);
    final middle = (high + low) / 2;
    double y(double kcal) =>
        top + (middle + half - kcal) / (half * 2) * (baseY - top - inset);

    final line = Path();
    double? previousY;
    var lastColumn = 0;
    for (final (column, slot) in slots.indexed) {
      final kcal = slot.kcal;
      if (kcal == null) continue;
      final nextY = y(kcal);
      if (previousY == null) {
        line.moveTo(x(column), nextY);
      } else {
        line
          ..lineTo(x(column), previousY)
          ..lineTo(x(column), nextY);
      }
      previousY = nextY;
      lastColumn = column;
    }
    canvas.drawPath(line, _stroke(ink, AppProgress.trendStroke));
    if (previousY != null) {
      _paintDashed(
        canvas,
        Offset(x(lastColumn), previousY),
        Offset(x(columns - 1), previousY),
        muted,
      );
    }
    _paintPoints(canvas, x, y, lastColumn);
  }

  void _paintPoints(
    Canvas canvas,
    double Function(int column) x,
    double Function(double kcal) y,
    int lastColumn,
  ) {
    for (final (column, slot) in slots.indexed) {
      final kcal = slot.kcal;
      if (kcal == null) continue;
      final center = Offset(x(column), y(kcal));
      final ghost = slot.ghostKcal;
      if (ghost != null) {
        final ghostCenter = Offset(center.dx, y(ghost));
        _paintDashed(canvas, center, ghostCenter, muted);
        _paintSquare(canvas, ghostCenter, muted, hollow: true);
      }
      if (slot.isGoalStart) {
        _paintSquare(canvas, center, muted, hollow: true);
      } else {
        _paintSquare(
          canvas,
          center,
          ink,
          hollow: false,
          size: column == lastColumn
              ? AppProgress.latestPointSize
              : AppProgress.checkInPointSize,
        );
      }
    }
  }

  void _paintMarkers(
    Canvas canvas,
    Size size,
    double baseY,
    double Function(int column) x,
  ) {
    if (!_hasMarkers) return;
    var goal = 0;
    for (final (column, slot) in slots.indexed) {
      if (!slot.isGoalStart) continue;
      paintProgressGoalMarker(
        canvas,
        x: x(column),
        bottom: baseY,
        width: size.width,
        label: goalLabels[goal],
        style: labelStyle,
        color: muted,
      );
      goal++;
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
    Color color, {
    required bool hollow,
    double size = AppProgress.checkInPointSize,
  }) {
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
    double Function(int column) x,
  ) {
    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      _stroke(ink, AppProgress.baseStroke),
    );
    final tick = _stroke(ink, AppProgress.thinStroke);
    for (var column = 0; column < slots.length; column++) {
      canvas.drawLine(
        Offset(x(column), baseY),
        Offset(x(column), baseY - AppProgress.shortTick),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_TdeeChartPainter oldDelegate) {
    return oldDelegate.slots != slots ||
        oldDelegate.goalLabels != goalLabels ||
        oldDelegate.ink != ink ||
        oldDelegate.muted != muted ||
        oldDelegate.paper != paper ||
        oldDelegate.labelStyle != labelStyle;
  }
}
