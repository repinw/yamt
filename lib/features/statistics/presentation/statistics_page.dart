import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/statistics/domain/statistics_metrics.dart';
import 'package:yamt/features/statistics/domain/statistics_models.dart';
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

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  StatisticsTab _selectedTab = StatisticsTab.spending;
  StatisticsTimeframe _selectedTimeframe = StatisticsTimeframe.week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final inventoryAsync = ref.watch(inventoryItemsControllerProvider);
    final mealsAsync = ref.watch(preparedMealsControllerProvider);
    final calorieAsync = _selectedTab == StatisticsTab.calories
        ? ref.watch(statisticsCalorieDataProvider(_selectedTimeframe))
        : null;
    final spendingSnapshot = _resolveSpendingSnapshot(
      inventoryAsync: inventoryAsync,
      mealsAsync: mealsAsync,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        140,
      ),
      children: [
        _StatisticsHeroCard(
          subtitle: l10n.statisticsPageSubtitle,
          contextLabel:
              _selectedTab.contextKind == StatisticsContextKind.personal
              ? l10n.statisticsContextPersonal
              : l10n.statisticsContextHousehold,
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildTimeframeSelector(l10n),
        const SizedBox(height: AppSpacing.lg),
        _buildTabSelector(l10n),
        const SizedBox(height: AppSpacing.lg),
        if (_selectedTab != StatisticsTab.calories)
          _StatisticsInfoBanner(
            icon: Icons.dataset_linked_rounded,
            title: l10n.statisticsHouseholdHintTitle,
            message: l10n.statisticsHouseholdHintBody,
          ),
        if (_selectedTab != StatisticsTab.calories)
          const SizedBox(height: AppSpacing.lg),
        ...switch (_selectedTab) {
          StatisticsTab.spending => _buildSpendingContent(
            l10n: l10n,
            locale: locale,
            inventoryAsync: inventoryAsync,
            mealsAsync: mealsAsync,
            snapshot: spendingSnapshot,
          ),
          StatisticsTab.waste => _buildWasteContent(
            l10n: l10n,
            inventoryAsync: inventoryAsync,
            mealsAsync: mealsAsync,
          ),
          StatisticsTab.calories => _buildCaloriesContent(
            l10n: l10n,
            calorieAsync: calorieAsync!,
          ),
        },
      ],
    );
  }

  List<Widget> _buildSpendingContent({
    required AppLocalizations l10n,
    required String locale,
    required AsyncValue<List<InventoryItem>> inventoryAsync,
    required AsyncValue<List<PreparedMeal>> mealsAsync,
    required StatisticsSpendingSnapshot? snapshot,
  }) {
    if (inventoryAsync.isLoading || mealsAsync.isLoading) {
      return const [LinearProgressIndicator()];
    }
    if (inventoryAsync.hasError || mealsAsync.hasError || snapshot == null) {
      return [_StatisticsErrorCard(onRetry: _retryHouseholdData)];
    }

    final currency = buildCurrencyFormat(
      locale: locale,
      currencyCode: snapshot.currencyCode,
    );
    final topStore = snapshot.topStores.isEmpty
        ? null
        : snapshot.topStores.first;
    final topItem = snapshot.expensiveEntries.isEmpty
        ? null
        : snapshot.expensiveEntries.first;
    final topTrend = snapshot.priceTrends.isEmpty
        ? null
        : snapshot.priceTrends.first;
    final leadingSource = _leadingSource(snapshot.costSources);
    final spendChartData = snapshot.dailySpendValues
        .take(7)
        .map((day) {
          return StatisticsBarChartDatum(
            label: DateFormat.Md(locale).format(day.date),
            value: day.value,
            valueLabel: currency.format(day.value),
          );
        })
        .toList(growable: false);

    return [
      _StatisticsChartCard(
        title: l10n.statisticsSpendingChartTitle,
        subtitle: l10n.statisticsSpendingChartSubtitle,
        child: spendChartData.isEmpty
            ? _ChartEmptyState(message: l10n.statisticsSpendingChartEmpty)
            : StatisticsVerticalBarChart(data: spendChartData),
      ),
      const SizedBox(height: AppSpacing.lg),
      StatisticsMetricCard(
        title: l10n.statisticsSpendingTotalTitle,
        value: currency.format(snapshot.totalValue),
        subtitle: l10n.statisticsSpendingTotalSubtitle,
      ),
      const SizedBox(height: AppSpacing.lg),
      StatisticsMetricCard(
        title: l10n.statisticsSpendingTrendTitle,
        value: topTrend == null
            ? l10n.statisticsMetricNoTrend
            : _formatSignedPercent(topTrend.changeRatio),
        subtitle: topTrend == null
            ? l10n.statisticsSpendingTrendEmpty
            : '${topTrend.title} · ${currency.format(topTrend.latestPrice)}',
      ),
      const SizedBox(height: AppSpacing.lg),
      StatisticsMetricCard(
        title: l10n.statisticsSpendingStoresTitle,
        value: topStore == null
            ? l10n.statisticsMetricNoData
            : currency.format(topStore.value),
        subtitle: topStore == null
            ? l10n.statisticsTopStoresEmpty
            : '${topStore.storeName} · ${topStore.itemCount}',
      ),
      const SizedBox(height: AppSpacing.lg),
      StatisticsMetricCard(
        title: l10n.statisticsSpendingItemsTitle,
        value: topItem == null
            ? l10n.statisticsMetricNoData
            : currency.format(topItem.value),
        subtitle: topItem == null
            ? l10n.statisticsExpensiveItemsEmpty
            : topItem.title,
      ),
      const SizedBox(height: AppSpacing.lg),
      StatisticsMetricCard(
        title: l10n.statisticsSpendingSourcesTitle,
        value: leadingSource == null
            ? l10n.statisticsMetricNoData
            : _formatPercent(_sourceShare(leadingSource, snapshot.costSources)),
        subtitle: leadingSource == null
            ? l10n.statisticsCostSourcesEmpty
            : _localizedSourceLabel(l10n, leadingSource.type),
      ),
    ];
  }

  List<Widget> _buildWasteContent({
    required AppLocalizations l10n,
    required AsyncValue<List<InventoryItem>> inventoryAsync,
    required AsyncValue<List<PreparedMeal>> mealsAsync,
  }) {
    if (inventoryAsync.isLoading || mealsAsync.isLoading) {
      return const [LinearProgressIndicator()];
    }
    if (inventoryAsync.hasError || mealsAsync.hasError) {
      return [_StatisticsErrorCard(onRetry: _retryHouseholdData)];
    }

    return [
      StatisticsMetricCard(
        title: l10n.statisticsWasteOverviewTitle,
        value: l10n.statisticsWasteTrackingMissingValue,
        subtitle: l10n.statisticsWasteTrackingMissingMessage,
      ),
      const SizedBox(height: AppSpacing.lg),
      StatisticsMetricCard(
        title: l10n.statisticsWasteRatioTitle,
        value: l10n.statisticsWasteTrackingMissingValue,
        subtitle: l10n.statisticsWasteMoneyLossMissing,
      ),
      const SizedBox(height: AppSpacing.lg),
      StatisticsMetricCard(
        title: l10n.statisticsWasteReasonsTitle,
        value: l10n.statisticsMetricNoData,
        subtitle: l10n.statisticsWasteReasonsMissing,
      ),
      const SizedBox(height: AppSpacing.lg),
      StatisticsMetricCard(
        title: l10n.statisticsWasteItemsTitle,
        value: l10n.statisticsMetricNoData,
        subtitle: l10n.statisticsWasteItemsMissing,
      ),
    ];
  }

  List<Widget> _buildCaloriesContent({
    required AppLocalizations l10n,
    required AsyncValue<StatisticsCalorieSnapshot> calorieAsync,
  }) {
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
                label: DateFormat.E(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(day.date),
                value: day.totalKcal,
                goalValue: day.goalKcal,
                valueLabel: day.entryCount == 0
                    ? '0'
                    : day.totalKcal.round().toString(),
              );
            })
            .toList(growable: false);
        final percentFormat = NumberFormat.percentPattern(
          Localizations.localeOf(context).toLanguageTag(),
        );

        return [
          _StatisticsChartCard(
            title: l10n.statisticsCaloriesChartTitle,
            subtitle: l10n.statisticsCaloriesChartSubtitle,
            legend: l10n.statisticsChartGoalLegend,
            child: dailyChartData.every((item) => item.value <= 0)
                ? _ChartEmptyState(message: l10n.statisticsCaloriesChartEmpty)
                : StatisticsVerticalBarChart(data: dailyChartData),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatisticsChartCard(
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
            value: '$averageKcal ${l10n.inventoryNutritionCaloriesShortLabel}',
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
                : _formatPercent(topMacro.share),
          ),
        ];
      },
      loading: () => const [LinearProgressIndicator()],
      error: (_, _) => [_StatisticsErrorCard(onRetry: _retryCalorieData)],
    );
  }

  Widget _buildTimeframeSelector(AppLocalizations l10n) {
    return StatisticsSurfaceCard(
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final timeframe in StatisticsTimeframe.values)
            ChoiceChip(
              label: Text(timeframe.localizedLabel(l10n)),
              selected: _selectedTimeframe == timeframe,
              onSelected: (selected) {
                if (!selected) {
                  return;
                }
                setState(() {
                  _selectedTimeframe = timeframe;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(AppLocalizations l10n) {
    return StatisticsSurfaceCard(
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final tab in StatisticsTab.values)
            ChoiceChip(
              label: Text(tab.localizedLabel(l10n)),
              selected: _selectedTab == tab,
              onSelected: (selected) {
                if (!selected) {
                  return;
                }
                setState(() {
                  _selectedTab = tab;
                });
              },
            ),
        ],
      ),
    );
  }

  StatisticsSpendingSnapshot? _resolveSpendingSnapshot({
    required AsyncValue<List<InventoryItem>> inventoryAsync,
    required AsyncValue<List<PreparedMeal>> mealsAsync,
  }) {
    final inventoryItems = inventoryAsync.asData?.value;
    final meals = mealsAsync.asData?.value;
    if (inventoryItems == null || meals == null) {
      return null;
    }

    final startDate = _resolveHouseholdStartDate(
      items: inventoryItems,
      meals: meals,
    );
    return buildStatisticsSpendingSnapshot(
      items: inventoryItems,
      meals: meals,
      startDate: startDate,
      endDate: DateUtils.dateOnly(DateTime.now()),
    );
  }

  DateTime _resolveHouseholdStartDate({
    required List<InventoryItem> items,
    required List<PreparedMeal> meals,
  }) {
    final itemDates = items
        .where((item) => !item.isReviewOnly)
        .map((item) => item.receiptDate ?? item.entryDate);
    final resolvedItemDates = itemDates.toList(growable: false);
    final spendingDates = resolvedItemDates.isNotEmpty
        ? resolvedItemDates
        : meals.map((meal) => meal.createdAt).toList(growable: false);
    if (spendingDates.isEmpty) {
      return _selectedTimeframe.startDate(now: DateTime.now());
    }
    return resolveSpendingWindowStartDate(
      spendingDates: spendingDates,
      maxVisibleDays: _selectedTimeframe.dayCount,
      fallbackDate: DateTime.now(),
    );
  }

  void _retryHouseholdData() {
    ref.read(inventoryItemsControllerProvider.notifier).refresh();
    ref.read(preparedMealsControllerProvider.notifier).refresh();
  }

  void _retryCalorieData() {
    ref.invalidate(statisticsCalorieDataProvider(_selectedTimeframe));
  }

  StatisticsCostSourceValue? _leadingSource(
    List<StatisticsCostSourceValue> values,
  ) {
    final positiveValues = values.where((value) => value.value > 0).toList();
    if (positiveValues.isEmpty) {
      return null;
    }
    positiveValues.sort((left, right) => right.value.compareTo(left.value));
    return positiveValues.first;
  }

  double _sourceShare(
    StatisticsCostSourceValue leadingSource,
    List<StatisticsCostSourceValue> values,
  ) {
    final total = values.fold<double>(0, (sum, value) => sum + value.value);
    if (total <= 0) {
      return 0;
    }
    return leadingSource.value / total;
  }

  String _localizedSourceLabel(
    AppLocalizations l10n,
    StatisticsCostSourceType type,
  ) {
    return switch (type) {
      StatisticsCostSourceType.inventory => l10n.statisticsCostSourceInventory,
      StatisticsCostSourceType.preparedMeals =>
        l10n.statisticsCostSourcePreparedMeals,
      StatisticsCostSourceType.eatingOut => l10n.statisticsCostSourceEatingOut,
      StatisticsCostSourceType.spices => l10n.statisticsCostSourceSpices,
    };
  }

  String _localizedMacroLabel(AppLocalizations l10n, StatisticsMacroType type) {
    return switch (type) {
      StatisticsMacroType.carbs => l10n.caloriesCarbsLabel,
      StatisticsMacroType.protein => l10n.caloriesProteinLabel,
      StatisticsMacroType.fat => l10n.caloriesFatLabel,
    };
  }

  String _formatPercent(double ratio) {
    final format = NumberFormat.percentPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return format.format(ratio.clamp(0.0, 1.0));
  }

  String _formatSignedPercent(double ratio) {
    final percent = (ratio * 100).round();
    if (percent > 0) {
      return '+$percent %';
    }
    return '$percent %';
  }

  String _formatSignedKcal(int value) {
    if (value > 0) {
      return '+$value kcal';
    }
    return '$value kcal';
  }
}

class _StatisticsHeroCard extends StatelessWidget {
  const _StatisticsHeroCard({
    required this.subtitle,
    required this.contextLabel,
  });

  final String subtitle;
  final String contextLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppInventoryEditorialSurfaces.backdropGradient(colors),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatisticsContextBadge(label: contextLabel),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.homeStatistics,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppInventoryEditorial.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsContextBadge extends StatelessWidget {
  const _StatisticsContextBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatisticsInfoBanner extends StatelessWidget {
  const _StatisticsInfoBanner({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StatisticsSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppInventoryEditorial.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsErrorCard extends StatelessWidget {
  const _StatisticsErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StatisticsSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statisticsLoadFailed,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: onRetry,
            child: Text(l10n.inventoryRetryAction),
          ),
        ],
      ),
    );
  }
}

class _StatisticsChartCard extends StatelessWidget {
  const _StatisticsChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.legend,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? legend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StatisticsSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (legend != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const SizedBox(width: 16, height: 2),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  legend!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
