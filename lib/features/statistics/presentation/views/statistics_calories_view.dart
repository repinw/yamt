import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_health_trend_provider.dart';
import 'package:yamt/features/statistics/domain/calorie_metrics.dart';
import 'package:yamt/features/statistics/domain/statistics_models.dart';
import 'package:yamt/features/statistics/presentation/statistics_page_keys.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_chart_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_error_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_macro_share_chart.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_metric_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_surface_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_vertical_bar_chart.dart';
import 'package:yamt/features/statistics/provider/'
    'statistics_calorie_data_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines statistics calories view.
class StatisticsCaloriesView extends ConsumerWidget {
  /// The statistics calories view.
  const StatisticsCaloriesView({
    required this.timeframe,
    required this.onRetry,
    super.key,
  });

  /// The timeframe.
  final StatisticsTimeframe timeframe;

  /// The on retry.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final calorieAsync = ref.watch(statisticsCalorieDataProvider(timeframe));
    final trendSnapshotAsync = ref.watch(calorieHealthTrendSnapshotProvider);

    return calorieAsync.when(
      data: (snapshot) {
        final averageKcal = snapshot.averageTrackedKcal.round();
        final balance = snapshot.balanceRemainingKcal.round();
        final chartDays = snapshot.days.length <= 7
            ? snapshot.days
            : snapshot.days.sublist(snapshot.days.length - 7);
        final hasMacroData = snapshot.macroShares.any((item) => item.share > 0);
        final topMacro = !hasMacroData
            ? null
            : snapshot.macroShares.reduce(
                (current, next) => current.share >= next.share ? current : next,
              );
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
        final latestWeightKg = trendSnapshotAsync.asData?.value.points.reversed
            .map((point) => point.weightKg)
            .whereType<double>()
            .cast<double?>()
            .firstOrNull;

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
              valueColor: balance >= 0 ? colors.primary : colors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            _StatisticsWeightCard(
              latestWeightKg: latestWeightKg,
              onTap: () => context.push(AppRoutes.homeStatisticsWeight),
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

class _StatisticsWeightCard extends StatelessWidget {
  const _StatisticsWeightCard({
    required this.latestWeightKg,
    required this.onTap,
  });

  final double? latestWeightKg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final value = latestWeightKg == null
        ? l10n.statisticsMetricNoData
        : '${latestWeightKg!.toStringAsFixed(1)} ${l10n.caloriesUnitKg}';

    return Semantics(
      button: true,
      child: GestureDetector(
        key: StatisticsPageKeys.weightCard,
        onTap: onTap,
        child: StatisticsSurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.caloriesHealthTrendsLegendWeight,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.caloriesHealthTrendsChartSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
