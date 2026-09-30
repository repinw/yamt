import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/features/calories/domain/calorie_goal_progress.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Weight since the goal start and, when [showTdee] is set, the learned TDEE
/// of every finished run on the same day axis.
class DiaryWeeklyCheckInProgressChart extends StatelessWidget {
  /// Creates the progress chart of the check-in.
  const new({
    required this.progress,
    required this.formatKcal,
    this.showTdee = true,
    this.targetWeightKg,
    super.key,
  });

  /// Weight and TDEE since the goal start.
  final CalorieGoalProgress progress;

  /// Formats a TDEE label.
  final String Function(double kcal) formatKcal;

  /// Whether the TDEE row is shown.
  final bool showTdee;

  /// Goal weight drawn as a dashed line, if set.
  final double? targetWeightKg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final labelStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: colors.ink);
    final weights = progress.weights;
    final dayCount = math.max(weights.length, 1);
    double dayOffset(DateTime day) =>
        day.difference(progress.startDate).inDays.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.diaryCheckInWeightChart.toUpperCase(),
          style: context.graphitKickerStyle,
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: AppProgress.chartHeight,
          child: CustomPaint(
            painter: _WeightPainter(
              points: [
                for (final weight in weights)
                  (
                    x: dayOffset(weight.day),
                    scale: weight.scaleWeightKg,
                    trend: weight.trendWeightKg,
                  ),
              ],
              dayCount: dayCount,
              targetWeightKg: targetWeightKg,
              ink: colors.ink,
              muted: colors.muted,
            ),
          ),
        ),
        if (showTdee && progress.tdeePoints.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.diaryCheckInTdeeChart.toUpperCase(),
            style: context.graphitKickerStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: AppProgress.chartHeight / 2,
            child: CustomPaint(
              painter: _TdeePainter(
                points: [
                  for (final point in progress.tdeePoints)
                    (
                      x: dayOffset(point.runEndDate),
                      kcal: point.tdeeKcal,
                      label: formatKcal(point.tdeeKcal),
                    ),
                ],
                dayCount: dayCount,
                ink: colors.ink,
                labelStyle: labelStyle,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

double _xOf(double dayOffset, int dayCount, double width) {
  const inset = AppProgress.latestPointSize;
  if (dayCount < 2) {
    return width / 2;
  }
  return inset / 2 + dayOffset * (width - inset) / (dayCount - 1);
}

class _WeightPainter extends CustomPainter {
  const new({
    required this.points,
    required this.dayCount,
    required this.targetWeightKg,
    required this.ink,
    required this.muted,
  });

  final List<({double x, double? scale, double? trend})> points;
  final int dayCount;
  final double? targetWeightKg;
  final Color ink;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height - AppProgress.chartBottomInset;
    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      Paint()
        ..color = ink
        ..strokeWidth = AppProgress.baseStroke,
    );
    final values = [
      for (final point in points) ...[?point.scale, ?point.trend],
      ?targetWeightKg,
    ];
    if (values.isEmpty) return;
    final low = values.reduce(math.min);
    final range = math.max(values.reduce(math.max) - low, 1);
    const top = AppProgress.latestPointSize;
    double y(double kg) =>
        top + (1 - (kg - low) / range) * (baseY - top - top / 2);

    if (targetWeightKg case final target?) {
      final dash = Paint()
        ..color = muted
        ..strokeWidth = AppProgress.thinStroke;
      for (var x = 0.0; x < size.width; x += AppProgress.dash * 2) {
        canvas.drawLine(
          Offset(x, y(target)),
          Offset(x + AppProgress.dash, y(target)),
          dash,
        );
      }
    }

    final weighIn = Paint()..color = muted;
    final trend = Path();
    Offset? last;
    for (final point in points) {
      final x = _xOf(point.x, dayCount, size.width);
      if (point.scale case final kg?) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y(kg)),
            width: AppProgress.weighInSize,
            height: AppProgress.weighInSize,
          ),
          weighIn,
        );
      }
      if (point.trend case final kg?) {
        final next = Offset(x, y(kg));
        last == null
            ? trend.moveTo(next.dx, next.dy)
            : trend.lineTo(next.dx, next.dy);
        last = next;
      }
    }
    canvas.drawPath(
      trend,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppProgress.trendStroke,
    );
    if (last != null) {
      canvas.drawRect(
        Rect.fromCenter(
          center: last,
          width: AppProgress.latestPointSize,
          height: AppProgress.latestPointSize,
        ),
        Paint()..color = ink,
      );
    }
  }

  @override
  bool shouldRepaint(_WeightPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.targetWeightKg != targetWeightKg ||
      oldDelegate.ink != ink ||
      oldDelegate.muted != muted;
}

class _TdeePainter extends CustomPainter {
  const new({
    required this.points,
    required this.dayCount,
    required this.ink,
    required this.labelStyle,
  });

  final List<({double x, double kcal, String label})> points;
  final int dayCount;
  final Color ink;
  final TextStyle? labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final kcals = points.map((point) => point.kcal);
    final low = kcals.reduce(math.min);
    final range = math.max(
      kcals.reduce(math.max) - low,
      AppProgress.tdeeMinRangeKcal,
    );
    const top = AppProgress.markerLabelSpace;
    final bottom = size.height - AppProgress.checkInPointSize;
    final line = Paint()
      ..color = ink
      ..strokeWidth = AppProgress.thinStroke;
    Offset? previous;
    for (final point in points) {
      final center = Offset(
        _xOf(point.x, dayCount, size.width),
        bottom - (point.kcal - low) / range * (bottom - top),
      );
      if (previous != null) {
        canvas.drawLine(previous, center, line);
      }
      previous = center;
      canvas.drawRect(
        Rect.fromCenter(
          center: center,
          width: AppProgress.checkInPointSize,
          height: AppProgress.checkInPointSize,
        ),
        Paint()..color = ink,
      );
      final text = TextPainter(
        text: TextSpan(text: point.label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = (center.dx - text.width / 2)
          .clamp(0.0, math.max(size.width - text.width, 0.0))
          .toDouble();
      text.paint(
        canvas,
        Offset(left, center.dy - AppProgress.markerLabelGap - text.height),
      );
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(_TdeePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.ink != ink ||
      oldDelegate.labelStyle != labelStyle;
}
