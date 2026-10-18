import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_chart_marker.dart';

/// One column of a [ProgressDayChart]: a small muted square for `dot` and a
/// point of the line for `line`, each `null` when the day has none.
typedef ProgressChartDay = ({DateTime day, double? dot, double? line});

/// Daily values as small squares and a smoothed line, one column per day,
/// with a dashed line at the start of each goal, an ink square on the line
/// for each marked day, and a dashed level line for the goal weight.
///
/// Short periods get a tick per day and a long tick per week; long periods
/// fewer ticks.
class ProgressDayChart extends StatelessWidget {
  /// Creates a day chart.
  const new({
    required this.days,
    required this.goalStarts,
    required this.minRange,
    this.markedDays = const {},
    this.target,
    super.key,
  });

  /// Days of the chart, oldest first, ending today.
  final List<ProgressChartDay> days;

  /// Goal starts inside the chart, with their labels.
  final List<(DateTime, String)> goalStarts;

  /// Days whose line point gets a square, such as check-ins.
  final Set<DateTime> markedDays;

  /// Smallest value range that the chart spans, so small changes do not look
  /// steep.
  final double minRange;

  /// A level drawn as a dashed line with its label, such as the goal weight.
  final (double, String)? target;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return SizedBox(
      height: AppProgress.chartHeight,
      child: CustomPaint(
        size: Size.infinite,
        painter: _DayChartPainter(
          days: days,
          goalStarts: goalStarts,
          markedDays: markedDays,
          minRange: minRange,
          target: target,
          ink: colors.ink,
          muted: colors.muted,
          targetColor: colors.low,
          labelStyle: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _DayChartPainter extends CustomPainter {
  const new({
    required this.days,
    required this.goalStarts,
    required this.markedDays,
    required this.minRange,
    required this.target,
    required this.ink,
    required this.muted,
    required this.targetColor,
    required this.labelStyle,
  });

  final List<ProgressChartDay> days;
  final List<(DateTime, String)> goalStarts;
  final Set<DateTime> markedDays;
  final double minRange;
  final (double, String)? target;
  final Color ink;
  final Color muted;
  final Color targetColor;
  final TextStyle? labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      for (final day in days) ...[?day.dot, ?day.line],
    ];
    final target = this.target;
    final baseY = size.height - AppProgress.chartBottomInset;
    const inset = AppProgress.latestPointSize;
    double x(int index) => days.length < 2
        ? size.width / 2
        : inset / 2 + index * (size.width - inset) / (days.length - 1);
    _paintAxis(canvas, size, baseY, x);
    for (final (day, label) in goalStarts) {
      final index = days.indexWhere((entry) => entry.day == day);
      if (index < 0) continue;
      paintProgressGoalMarker(
        canvas,
        x: x(index),
        bottom: baseY,
        width: size.width,
        label: label,
        style: labelStyle,
        color: muted,
      );
    }
    if (values.isEmpty) return;

    final top = goalStarts.isEmpty ? inset / 2 : AppProgress.markerLabelSpace;
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final range = math.max(high - low, minRange);
    final middle = (high + low) / 2;
    double y(double value) =>
        top + (middle + range / 2 - value) / range * (baseY - top - inset);

    // A far goal stays at the edge, so it does not flatten the weights.
    if (target != null) {
      _paintTarget(
        canvas,
        size,
        y(target.$1).clamp(top, baseY - inset),
        target.$2,
      );
    }

    final dot = Paint()..color = muted;
    final line = Path();
    var started = false;
    Offset? latest;
    final marked = <Offset>[];
    for (final (index, day) in days.indexed) {
      if (day.dot case final value?) {
        _paintSquare(
          canvas,
          Offset(x(index), y(value)),
          dot,
          AppProgress.weighInSize,
        );
      }
      final value = day.line;
      if (value == null) continue;
      final point = Offset(x(index), y(value));
      started
          ? line.lineTo(point.dx, point.dy)
          : line.moveTo(point.dx, point.dy);
      started = true;
      latest = point;
      if (markedDays.contains(day.day)) marked.add(point);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppProgress.trendStroke
        ..strokeJoin = StrokeJoin.round,
    );
    final fill = Paint()..color = ink;
    for (final point in marked) {
      _paintSquare(canvas, point, fill, AppProgress.checkInPointSize);
    }
    if (latest != null) {
      _paintSquare(canvas, latest, fill, AppProgress.latestPointSize);
    }
  }

  void _paintTarget(Canvas canvas, Size size, double y, String label) {
    final paint = Paint()
      ..color = targetColor
      ..strokeWidth = AppProgress.thinStroke;
    for (var x = 0.0; x < size.width; x += AppProgress.dash * 2) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + AppProgress.dash, size.width), y),
        paint,
      );
    }
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: labelStyle?.copyWith(color: targetColor),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    // Above the line, or below it when the line runs along the top.
    final above = y - AppProgress.markerLabelGap - text.height;
    text.paint(
      canvas,
      Offset(
        size.width - text.width,
        above < 0 ? y + AppProgress.markerLabelGap : above,
      ),
    );
  }

  void _paintSquare(Canvas canvas, Offset center, Paint paint, double size) {
    canvas.drawRect(
      Rect.fromCenter(center: center, width: size, height: size),
      paint,
    );
  }

  void _paintAxis(
    Canvas canvas,
    Size size,
    double baseY,
    double Function(int index) x,
  ) {
    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      Paint()
        ..color = ink
        ..strokeWidth = AppProgress.baseStroke,
    );
    final tick = Paint()
      ..color = ink
      ..strokeWidth = AppProgress.thinStroke;
    final daily = days.length <= AppProgress.dailyTickMaxDays;
    final weekly = days.length <= AppProgress.weeklyTickMaxDays;
    for (var index = 0; index < days.length; index++) {
      final isLast = index == days.length - 1;
      final isWeek = weekly && index % DateTime.daysPerWeek == 0;
      if (!daily && !isWeek && !isLast) continue;
      final length = isWeek || isLast
          ? AppProgress.longTick
          : AppProgress.shortTick;
      canvas.drawLine(
        Offset(x(index), baseY),
        Offset(x(index), baseY - length),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_DayChartPainter oldDelegate) {
    // The sections build new lists on every build, so compare contents.
    return !listEquals(oldDelegate.days, days) ||
        !listEquals(oldDelegate.goalStarts, goalStarts) ||
        !setEquals(oldDelegate.markedDays, markedDays) ||
        oldDelegate.minRange != minRange ||
        oldDelegate.target != target ||
        oldDelegate.targetColor != targetColor ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.ink != ink ||
        oldDelegate.muted != muted;
  }
}
