import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_chart_marker.dart';

/// Weigh-ins as small squares and the trend weight as a line, one column per
/// day, with a dashed line at the start of each goal.
///
/// Short periods get a tick per day and a long tick per week; long periods
/// fewer ticks.
class ProgressWeightChart extends StatelessWidget {
  /// Creates the weight chart.
  const new({required this.days, required this.goalStarts, super.key});

  /// Days of the chart, oldest first, ending today.
  final List<RecentWeightDay> days;

  /// Goal starts inside the chart, with their labels.
  final List<(DateTime, String)> goalStarts;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return SizedBox(
      height: AppProgress.chartHeight,
      child: CustomPaint(
        size: Size.infinite,
        painter: _WeightChartPainter(
          days: days,
          goalStarts: goalStarts,
          ink: colors.ink,
          muted: colors.muted,
          labelStyle: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  const new({
    required this.days,
    required this.goalStarts,
    required this.ink,
    required this.muted,
    required this.labelStyle,
  });

  final List<RecentWeightDay> days;
  final List<(DateTime, String)> goalStarts;
  final Color ink;
  final Color muted;
  final TextStyle? labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      for (final day in days) ...[?day.weightKg, ?day.trendWeightKg],
    ];
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
    final range = math.max(high - low, 1);
    double y(double kg) => top + (high - kg) / range * (baseY - top - inset);

    final dot = Paint()..color = muted;
    const half = AppProgress.weighInSize / 2;
    final trend = Path();
    var started = false;
    Offset? latest;
    for (final (index, day) in days.indexed) {
      final weight = day.weightKg;
      if (weight != null) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x(index), y(weight)),
            width: half * 2,
            height: half * 2,
          ),
          dot,
        );
      }
      final trendKg = day.trendWeightKg;
      if (trendKg == null) continue;
      final point = Offset(x(index), y(trendKg));
      started
          ? trend.lineTo(point.dx, point.dy)
          : trend.moveTo(point.dx, point.dy);
      started = true;
      latest = point;
    }
    canvas.drawPath(
      trend,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppProgress.trendStroke
        ..strokeJoin = StrokeJoin.round,
    );
    if (latest != null) {
      canvas.drawRect(
        Rect.fromCenter(
          center: latest,
          width: AppProgress.latestPointSize,
          height: AppProgress.latestPointSize,
        ),
        Paint()..color = ink,
      );
    }
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
  bool shouldRepaint(_WeightChartPainter oldDelegate) {
    return oldDelegate.days != days ||
        oldDelegate.goalStarts != goalStarts ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.ink != ink ||
        oldDelegate.muted != muted;
  }
}
