import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_balance_summary_view.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_summary_view_mode_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CaloriesSummaryCard extends ConsumerWidget {
  const CaloriesSummaryCard({
    super.key,
    required this.consumedKcal,
    required this.goalKcal,
    required this.remainingKcal,
    required this.progress,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.consumedLabel,
    required this.goalLabel,
    required this.remainingLabel,
    required this.proteinLabel,
    required this.carbsLabel,
    required this.fatLabel,
  });

  final double consumedKcal;
  final double goalKcal;
  final double remainingKcal;
  final double progress;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String consumedLabel;
  final String goalLabel;
  final String remainingLabel;
  final String proteinLabel;
  final String carbsLabel;
  final String fatLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final kcalUnit = l10n.caloriesUnitKcal;
    final gramUnit = l10n.caloriesUnitGram;
    final macroGoals = _MacroGoals.fromGoalKcal(goalKcal);
    final viewMode = ref.watch(calorieSummaryViewModeControllerProvider);
    final balanceState = viewMode == CalorieSummaryViewMode.balance
        ? ref.watch(calorieBalanceSummaryProvider)
        : null;
    final balanceData = balanceState?.value;

    return DecoratedBox(
      key: CaloriesPageKeys.summaryCard,
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colorScheme,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SummaryModeToggle(
              viewMode: viewMode,
              onChanged: ref
                  .read(calorieSummaryViewModeControllerProvider.notifier)
                  .setMode,
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (viewMode) {
                CalorieSummaryViewMode.classic => _ClassicSummaryHero(
                  key: const ValueKey<String>('classic_summary_hero'),
                  remainingKcal: remainingKcal,
                  progress: progress,
                  color: remainingKcal < 0
                      ? colorScheme.error
                      : AppInventoryEditorial.primary,
                  label: remainingLabel,
                  numberFormat: numberFormat,
                ),
                CalorieSummaryViewMode.balance => _BalanceSummaryHero(
                  key: const ValueKey<String>('balance_summary_hero'),
                  balanceState: balanceState!,
                  numberFormat: numberFormat,
                  kcalUnit: kcalUnit,
                ),
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            _MacroProgressRow(
              label: carbsLabel,
              current: totalCarbs,
              target: macroGoals.carbs,
              color: const Color(0xFF3B82F6),
              unitLabel: gramUnit,
              numberFormat: numberFormat,
            ),
            const SizedBox(height: AppSpacing.md),
            _MacroProgressRow(
              label: proteinLabel,
              current: totalProtein,
              target: macroGoals.protein,
              color: const Color(0xFFF97316),
              unitLabel: gramUnit,
              numberFormat: numberFormat,
            ),
            const SizedBox(height: AppSpacing.md),
            _MacroProgressRow(
              label: fatLabel,
              current: totalFat,
              target: macroGoals.fat,
              color: const Color(0xFFEAB308),
              unitLabel: gramUnit,
              numberFormat: numberFormat,
            ),
            const SizedBox(height: AppSpacing.xl),
            switch (viewMode) {
              CalorieSummaryViewMode.classic => Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: consumedLabel,
                      value:
                          '${numberFormat.format(consumedKcal.round())} '
                          '$kcalUnit',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SummaryStat(
                      label: goalLabel,
                      value:
                          '${numberFormat.format(goalKcal.round())} $kcalUnit',
                    ),
                  ),
                ],
              ),
              CalorieSummaryViewMode.balance => Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: consumedLabel,
                      value:
                          '${numberFormat.format(consumedKcal.round())} '
                          '$kcalUnit',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SummaryStat(
                      label: balanceData?.isCurrentDay == false
                          ? l10n.caloriesBalancePaceFinalLabel
                          : l10n.caloriesBalancePaceNowLabel,
                      value: balanceData == null
                          ? '...'
                          : '${numberFormat.format(balanceData.pacedGoalKcal.round())} $kcalUnit',
                    ),
                  ),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _SummaryModeToggle extends StatelessWidget {
  const _SummaryModeToggle({required this.viewMode, required this.onChanged});

  final CalorieSummaryViewMode viewMode;
  final Future<void> Function(CalorieSummaryViewMode mode) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      key: CaloriesPageKeys.summaryModeToggle,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: SegmentedButton<CalorieSummaryViewMode>(
          showSelectedIcon: false,
          style: _summarySegmentedButtonStyle(context),
          selected: <CalorieSummaryViewMode>{viewMode},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) {
              return;
            }
            onChanged(selection.first);
          },
          segments: <ButtonSegment<CalorieSummaryViewMode>>[
            ButtonSegment<CalorieSummaryViewMode>(
              value: CalorieSummaryViewMode.classic,
              label: Text(
                l10n.caloriesSummaryViewClassic,
                key: CaloriesPageKeys.summaryModeOption(
                  CalorieSummaryViewMode.classic.name,
                ),
              ),
            ),
            ButtonSegment<CalorieSummaryViewMode>(
              value: CalorieSummaryViewMode.balance,
              label: Text(
                l10n.caloriesSummaryViewBalance,
                key: CaloriesPageKeys.summaryModeOption(
                  CalorieSummaryViewMode.balance.name,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassicSummaryHero extends StatelessWidget {
  const _ClassicSummaryHero({
    super.key,
    required this.remainingKcal,
    required this.progress,
    required this.color,
    required this.label,
    required this.numberFormat,
  });

  final double remainingKcal;
  final double progress;
  final Color color;
  final String label;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayedValue = numberFormat.format(remainingKcal.round());

    return Center(
      child: SizedBox.square(
        dimension: 196,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 168,
              child: Transform.rotate(
                angle: -math.pi / 2,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  color: color,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayedValue,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSummaryHero extends StatelessWidget {
  const _BalanceSummaryHero({
    super.key,
    required this.balanceState,
    required this.numberFormat,
    required this.kcalUnit,
  });

  final AsyncValue<CalorieBalanceSummaryData> balanceState;
  final NumberFormat numberFormat;
  final String kcalUnit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return balanceState.when(
      data: (data) => CaloriesBalanceSummaryView(
        data: data,
        numberFormat: numberFormat,
        kcalUnit: kcalUnit,
      ),
      loading: () => const SizedBox(
        height: 172,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => SizedBox(
        height: 172,
        child: Center(
          child: Text(
            l10n.caloriesBalanceUnavailable,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _MacroProgressRow extends StatelessWidget {
  const _MacroProgressRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unitLabel,
    required this.numberFormat,
  });

  final String label;
  final double current;
  final double target;
  final Color color;
  final String unitLabel;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = target <= 0
        ? 0.0
        : (current / target).clamp(0.0, 1.0).toDouble();
    final currentText = numberFormat.format(current.round());
    final targetText = numberFormat.format(target.round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.05,
                ),
              ),
            ),
            Text(
              '$currentText$unitLabel / $targetText$unitLabel',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.05,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MacroGoals {
  const _MacroGoals({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  final double carbs;
  final double protein;
  final double fat;

  factory _MacroGoals.fromGoalKcal(double goalKcal) {
    return _MacroGoals(
      carbs: goalKcal * 0.45 / 4,
      protein: goalKcal * 0.25 / 4,
      fat: goalKcal * 0.30 / 9,
    );
  }
}

ButtonStyle _summarySegmentedButtonStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return ButtonStyle(
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    ),
    textStyle: WidgetStatePropertyAll(
      textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    side: const WidgetStatePropertyAll(BorderSide.none),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colors.surfaceContainerLowest;
      }
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colors.primary;
      }
      return colors.onSurfaceVariant;
    }),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    elevation: const WidgetStatePropertyAll(0),
    overlayColor: WidgetStatePropertyAll(
      colors.surfaceContainerHigh.withValues(alpha: 0.16),
    ),
  );
}
