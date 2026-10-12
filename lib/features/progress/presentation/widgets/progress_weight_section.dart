import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/progress/application/progress_weight_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_weight.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_axis_labels.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_day_chart.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_legend.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The weight trend of the period of a scope with the goal starts and the
/// forecast for the goal weight.
class ProgressWeightSection extends ConsumerWidget {
  /// Creates the weight section for [scope].
  const new({required this.scope, super.key});

  /// Which goals the chart covers.
  final ProgressScope scope;

  /// Stable key of the section.
  static const sectionKey = ValueKey<String>('progress-weight-section');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(progressWeightProvider(scope))
        .when(
          data: (weight) => _WeightContent(key: sectionKey, weight: weight),
          loading: () => const ProgressSectionLoading(),
          error: (_, _) => const ProgressSectionError(),
        );
  }
}

class _WeightContent extends StatelessWidget {
  const new({required this.weight, super.key});

  final ProgressWeight weight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final locale = Localizations.localeOf(context).toString();
    final kg = NumberFormat('0.0', locale);
    final signedKg = NumberFormat('+0.0;−0.0', locale);
    final trend = weight.trend;
    final trendKg = trend.trendWeightKg;
    final perWeek = trend.trendKgPerWeek;
    final projected = weight.projectedGoalDate;
    final days = trend.days;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressSectionHeader(
          kicker: l10n.progressWeightKicker,
          value: trendKg == null ? '–' : kg.format(trendKg),
          unit: l10n.caloriesUnitKg,
          lines: [
            if (perWeek != null)
              l10n.progressWeightPerWeek(signedKg.format(perWeek)),
            if (weight.isGoalReached)
              l10n.progressWeightGoalReached
            else if (projected != null)
              l10n.progressWeightForecast(
                projected.year == days.last.day.year
                    ? DateFormat.MMMd(locale).format(projected)
                    : DateFormat.yMMM(locale).format(projected),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (trendKg == null)
          ProgressSectionNote(text: l10n.progressWeightEmpty)
        else ...[
          ProgressDayChart(
            days: [
              for (final day in days)
                (day: day.day, dot: day.weightKg, line: day.trendWeightKg),
            ],
            minRange: _minRangeKg,
            goalStarts: [
              for (final start in weight.goalStarts)
                (start.day, l10n.progressGoalMarker(start.number)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          ProgressAxisLabels.forDays(
            days: [for (final day in days) day.day],
            todayLabel: l10n.progressToday,
            locale: locale,
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressLegend(
            items: [
              ProgressLegendItem(
                swatch: SizedBox.square(
                  dimension: AppProgress.weighInSize,
                  child: ColoredBox(color: colors.muted),
                ),
                label: l10n.progressWeightLegendWeighIn,
              ),
              ProgressLegendItem(
                swatch: SizedBox(
                  width: AppProgress.legendSwatch * 2,
                  height: AppProgress.trendStroke,
                  child: ColoredBox(color: colors.ink),
                ),
                label: l10n.progressWeightLegendTrend,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Smallest kg range of the chart.
const _minRangeKg = 1.0;
