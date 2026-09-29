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
import 'package:yamt/features/progress/presentation/widgets/progress_legend.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_chart.dart';
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
    final dayFormat = days.length > _daysPerYear
        ? DateFormat.yMMM(locale)
        : DateFormat.MMMd(locale);
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
          ProgressWeightChart(
            days: days,
            goalStarts: [
              for (final start in weight.goalStarts)
                (start.day, l10n.progressGoalMarker(start.number)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          ProgressAxisLabels(
            labels: [
              for (final index in _labelIndexes(days.length))
                if (index == days.length - 1)
                  l10n.progressToday
                else
                  dayFormat.format(days[index].day),
            ],
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

const _daysPerYear = 365;

/// Indexes of up to five evenly spread axis labels over [count] days.
List<int> _labelIndexes(int count) {
  if (count <= 1) return [0];
  const parts = 4;
  return {
    for (var part = 0; part <= parts; part++)
      ((count - 1) * part / parts).round(),
  }.toList();
}
