import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_axis_labels.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_day_chart.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The weigh-ins and the trend line of [trend] with the goal starts, the
/// goal weight when given, and the day labels below.
class ProgressWeightChart extends StatelessWidget {
  /// Creates the weight chart.
  const new({
    required this.trend,
    required this.goalStarts,
    this.targetWeightKg,
    this.ignored = const [],
    this.endsToday = true,
    super.key,
  });

  /// Weigh-ins and trend weight per day, oldest first.
  final RecentWeightTrend trend;

  /// First day of each goal in the chart, oldest first.
  final List<ProgressGoalStart> goalStarts;

  /// The goal weight, drawn as a dashed line.
  final double? targetWeightKg;

  /// Weighings the user left out of every count, drawn hollow.
  final List<ProgressWeighing> ignored;

  /// Whether the last day is today, labelled so below the chart.
  final bool endsToday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final target = targetWeightKg;
    final days = trend.days;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressDayChart(
          days: [
            for (final day in days)
              (day: day.day, dot: day.weightKg, line: day.trendWeightKg),
          ],
          minRange: _minRangeKg,
          hollowDots: [
            for (final weighing in ignored) (weighing.day, weighing.weightKg),
          ],
          goalStarts: [
            for (final start in goalStarts)
              (start.day, l10n.progressGoalMarker(start.number)),
          ],
          target: target == null
              ? null
              : (
                  target,
                  l10n.progressWeightsTarget(
                    NumberFormat('0.0', locale).format(target),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        ProgressAxisLabels.forDays(
          days: [for (final day in days) day.day],
          todayLabel: endsToday ? l10n.progressToday : null,
          locale: locale,
        ),
      ],
    );
  }
}

/// Smallest kg range of the chart.
const _minRangeKg = 1.0;
