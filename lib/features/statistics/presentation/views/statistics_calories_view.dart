import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/statistics/domain/calorie_metrics.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_chart_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_error_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_macro_share_chart.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_metric_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_vertical_bar_chart.dart';
import 'package:yamt/l10n/app_localizations.dart';

class StatisticsCaloriesView extends StatelessWidget {
  const StatisticsCaloriesView({
    super.key,
    required this.calorieAsync,
    required this.onRetry,
  });

  final AsyncValue<StatisticsCalorieSnapshot> calorieAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return calorieAsync.when(
      data: (snapshot) {
        final averageKcal = snapshot.averageTrackedKcal.round();
        final balance = snapshot.balanceRemainingKcal.round();
        final chartDays = snapshot.days.length <= 7
            ? snapshot.days
            : snapshot.days.sublist(snapshot.days.length - 7);
        final topMacro = snapshot.macroShares.isEmpty
            ? null
            : (List<StatisticsMacroShare>.from(snapshot.macroShares)
                    ..sort((left, right) => right.share.compareTo(left.share)))
                  .first;
        final dailyChartData = chartDays
            .map((day) {
              return StatisticsBarChartDatum(
                label: DateFormat.E(locale).format(day.date),
                value: day.totalKcal,
                goalValue: day.goalKcal,
                valueLabel: day.entryCount == 0
                    ? '0'
                    : day.totalKcal.round().toString(),
              );
            })
            .toList(growable: false);
        final percentFormat = NumberFormat.percentPattern(locale);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatisticsChartCard(
              title: l10n.statisticsCaloriesChartTitle,
              subtitle: l10n.statisticsCaloriesChartSubtitle,
              legend: l10n.statisticsChartGoalLegend,
              child: dailyChartData.every((item) => item.value <= 0)
                  ? StatisticsChartEmptyState(
                      message: l10n.statisticsCaloriesChartEmpty,
                    )
                  : StatisticsVerticalBarChart(data: dailyChartData),
            ),
            const SizedBox(height: AppSpacing.lg),
            StatisticsChartCard(
              title: l10n.statisticsCaloriesMacrosTitle,
              subtitle: l10n.statisticsCaloriesMacroChartSubtitle,
              child: StatisticsMacroShareChart(
                items: snapshot.macroShares,
                labelBuilder: (item) => _localizedMacroLabel(l10n, item.type),
                valueLabelBuilder: (item) {
                  final grams = item.grams.round();
                  return '$grams g · ${percentFormat.format(item.share)}';
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StatisticsMetricCard(
              title: l10n.statisticsCaloriesOverviewTitle,
              value:
                  '$averageKcal ${l10n.inventoryNutritionCaloriesShortLabel}',
              subtitle: l10n.statisticsCaloriesOverviewSummary(
                snapshot.trackedDayCount,
                snapshot.totalEntries,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StatisticsMetricCard(
              title: l10n.statisticsCaloriesStreakTitle,
              value: '${snapshot.goalMetDayCount}/${snapshot.trackedDayCount}',
              subtitle: l10n.statisticsCaloriesStreakSummary(
                snapshot.goalMetDayCount,
                snapshot.trackedDayCount,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StatisticsMetricCard(
              title: l10n.statisticsCaloriesBufferTitle,
              value: _formatSignedKcal(balance),
              subtitle: l10n.statisticsCaloriesBufferSubtitle,
              valueColor: balance >= 0
                  ? AppInventoryEditorial.primary
                  : AppInventoryEditorial.warning,
            ),
            const SizedBox(height: AppSpacing.lg),
            StatisticsMetricCard(
              title: l10n.statisticsCaloriesMacrosTitle,
              value: topMacro == null
                  ? l10n.statisticsMetricNoData
                  : _localizedMacroLabel(l10n, topMacro.type),
              subtitle: topMacro == null
                  ? l10n.statisticsCaloriesNoEntries
                  : percentFormat.format(topMacro.share.clamp(0.0, 1.0)),
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => StatisticsErrorCard(onRetry: onRetry),
    );
  }

  String _localizedMacroLabel(AppLocalizations l10n, StatisticsMacroType type) {
    return switch (type) {
      StatisticsMacroType.carbs => l10n.caloriesCarbsLabel,
      StatisticsMacroType.protein => l10n.caloriesProteinLabel,
      StatisticsMacroType.fat => l10n.caloriesFatLabel,
    };
  }

  String _formatSignedKcal(int value) {
    if (value > 0) {
      return '+$value kcal';
    }
    return '$value kcal';
  }
}
