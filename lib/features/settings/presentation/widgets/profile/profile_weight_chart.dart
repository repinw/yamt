import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';

/// The recent weigh-ins as dots and the trend weight as a line.
class ProfileWeightChart extends StatelessWidget {
  /// Creates the chart for [days].
  const new({required this.days, super.key});

  /// One entry per day, oldest first.
  final List<RecentWeightDay> days;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        height: AppSizes.profileWeightChart,
        width: double.infinity,
        child: CustomPaint(
          painter: _WeightChartPainter(
            days: days,
            dotColor: colors.onSurfaceVariant.withValues(
              alpha: AppOpacities.weightChartScaleDot,
            ),
            lineColor: colors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  new({required this.days, required this.dotColor, required this.lineColor});

  final List<RecentWeightDay> days;
  final Color dotColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      for (final day in days) ...[?day.weightKg, ?day.trendWeightKg],
    ];
    if (values.isEmpty || days.length < 2) {
      return;
    }
    const inset = AppSizes.weightChartScaleDotRadius;
    var low = values.reduce((a, b) => a < b ? a : b);
    var high = values.reduce((a, b) => a > b ? a : b);
    if (high - low < AppSizes.profileWeightChartMinRangeKg) {
      final middle = (high + low) / 2;
      low = middle - AppSizes.profileWeightChartMinRangeKg / 2;
      high = middle + AppSizes.profileWeightChartMinRangeKg / 2;
    }
    Offset point(int index, double weight) => Offset(
      inset + index * (size.width - 2 * inset) / (days.length - 1),
      inset + (high - weight) / (high - low) * (size.height - 2 * inset),
    );

    final dotPaint = Paint()..color = dotColor;
    for (var index = 0; index < days.length; index++) {
      final weight = days[index].weightKg;
      if (weight != null) {
        canvas.drawCircle(
          point(index, weight),
          AppSizes.weightChartScaleDotRadius,
          dotPaint,
        );
      }
    }

    final line = Path();
    var started = false;
    for (var index = 0; index < days.length; index++) {
      final trend = days[index].trendWeightKg;
      if (trend == null) {
        continue;
      }
      final offset = point(index, trend);
      if (started) {
        line.lineTo(offset.dx, offset.dy);
      } else {
        line.moveTo(offset.dx, offset.dy);
        started = true;
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.weightChartTrendLineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_WeightChartPainter oldDelegate) {
    return oldDelegate.days != days ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.lineColor != lineColor;
  }
}
