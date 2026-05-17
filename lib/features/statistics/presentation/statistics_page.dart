import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/statistics/domain/statistics_models.dart';
import 'package:yamt/features/statistics/presentation/views/'
    'statistics_calories_view.dart';
import 'package:yamt/features/statistics/presentation/views/'
    'statistics_spending_view.dart';
import 'package:yamt/features/statistics/presentation/views/'
    'statistics_waste_view.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_surface_card.dart';
import 'package:yamt/features/statistics/provider/'
    'statistics_calorie_data_provider.dart';
import 'package:yamt/features/statistics/provider/'
    'statistics_waste_data_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines statistics page.
@Dependencies([InventoryItemsController])
class StatisticsPage extends ConsumerStatefulWidget {
  /// The statistics page.
  const StatisticsPage({super.key, this.includeHomeShellChrome = false});

  /// Whether to render the shared home shell app bar as a sliver.
  final bool includeHomeShellChrome;

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  StatisticsTab _selectedTab = StatisticsTab.spending;
  StatisticsTimeframe _selectedTimeframe = StatisticsTimeframe.week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inventoryAsync = ref.watch(inventoryItemsControllerProvider);

    return CustomScrollView(
      slivers: [
        if (widget.includeHomeShellChrome)
          HomeShellTabTopChrome(title: l10n.homeStatistics),
        SliverPadding(
          padding: responsivePagePadding(
            context,
            top: AppSpacing.lg,
            bottom: homeShellPageBottomPadding(context),
          ),
          sliver: SliverList.list(
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
              switch (_selectedTab) {
                StatisticsTab.spending => StatisticsSpendingView(
                  timeframe: _selectedTimeframe,
                  inventoryAsync: inventoryAsync,
                  onRetry: _retryHouseholdData,
                ),
                StatisticsTab.waste => StatisticsWasteView(
                  timeframe: _selectedTimeframe,
                  onRetry: _retryWasteData,
                ),
                StatisticsTab.calories => StatisticsCaloriesView(
                  timeframe: _selectedTimeframe,
                  onRetry: _retryCalorieData,
                ),
              },
            ],
          ),
        ),
      ],
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

  void _retryHouseholdData() {
    unawaited(ref.read(inventoryItemsControllerProvider.notifier).refresh());
  }

  void _retryCalorieData() {
    ref.invalidate(statisticsCalorieDataProvider(_selectedTimeframe));
  }

  void _retryWasteData() {
    ref.invalidate(statisticsWasteDataProvider(_selectedTimeframe));
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
        padding: responsiveCardPadding(
          context,
          compact: AppSpacing.xxl,
          regular: AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatisticsContextBadge(label: contextLabel),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.homeStatistics,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: colors.primary,
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
          Icon(icon, color: colors.primary),
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
