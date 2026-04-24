import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_budget_details_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_classic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_controls.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_macros.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_meta.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_summary_classic_adjustments_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_summary_view_mode_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

export 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_macros.dart'
    show doesCaloriesSummaryTextFitWidth, resolveMacroLabelForWidth;

/// Defines calories summary card.
class CaloriesSummaryCard extends ConsumerWidget {
  /// The calories summary card.
  const CaloriesSummaryCard({
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
    super.key,
  });

  /// The consumed kcal.
  final double consumedKcal;

  /// The goal kcal.
  final double goalKcal;

  /// The remaining kcal.
  final double remainingKcal;

  /// The progress.
  final double progress;

  /// The total protein.
  final double totalProtein;

  /// The total carbs.
  final double totalCarbs;

  /// The total fat.
  final double totalFat;

  /// The consumed label.
  final String consumedLabel;

  /// The goal label.
  final String goalLabel;

  /// The remaining label.
  final String remainingLabel;

  /// The protein label.
  final String proteinLabel;

  /// The carbs label.
  final String carbsLabel;

  /// The fat label.
  final String fatLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final kcalUnit = l10n.caloriesUnitKcal;
    final gramUnit = l10n.caloriesUnitGram;
    final macroGoals = CaloriesSummaryMacroGoals.fromGoalKcal(goalKcal);
    final consumedValue =
        '${numberFormat.format(consumedKcal.round())} $kcalUnit';
    final viewMode = ref.watch(calorieSummaryViewModeControllerProvider);
    final balanceData = ref.watch(calorieBalanceSummaryProvider).value;
    final classicAdjustments = ref.watch(
      calorieSummaryClassicAdjustmentsControllerProvider,
    );
    final includeClassicActivityDelta = classicAdjustments.includeActivityDelta;
    final includeClassicCarryover = classicAdjustments.includeCarryover;
    final availableClassicActivityDeltaKcal =
        balanceData?.activityDeltaKcal ?? 0.0;
    final availableClassicCarryoverKcal = balanceData?.carryoverKcal ?? 0.0;
    final classicBudget = CalorieBudgetCalculator.calculateClassicBudget(
      storedGoalKcal: balanceData?.storedGoalKcal ?? goalKcal,
      activityDeltaKcal: availableClassicActivityDeltaKcal,
      carryoverKcal: availableClassicCarryoverKcal,
      consumedKcal: consumedKcal,
      includeActivityDelta: includeClassicActivityDelta,
      includeCarryover: includeClassicCarryover,
    );
    final classicGoalKcal = classicBudget.goalKcal;
    final classicActivityDeltaKcal = classicBudget.includedActivityDeltaKcal;
    final classicCarryoverKcal = classicBudget.includedCarryoverKcal;
    final classicBaseGoalKcal = classicBudget.baseGoalKcal;
    final classicRemainingKcal = classicBudget.remainingKcal;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SummaryModeToggle(
                  viewMode: viewMode,
                  onChanged: ref
                      .read(calorieSummaryViewModeControllerProvider.notifier)
                      .setMode,
                ),
                if (viewMode == CalorieSummaryViewMode.classic) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ClassicHeaderStats(
                        consumedLabel: consumedLabel,
                        consumedValue: consumedValue,
                        goalLabel: goalLabel,
                        goalValue:
                            '${numberFormat.format(classicGoalKcal.round())} '
                            '$kcalUnit',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      unawaited(
                        _showClassicBudgetDetails(
                          context: context,
                          l10n: l10n,
                          numberFormat: numberFormat,
                          kcalUnit: kcalUnit,
                          budget: classicBudget,
                          availableActivityDeltaKcal:
                              availableClassicActivityDeltaKcal,
                          availableCarryoverKcal: availableClassicCarryoverKcal,
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline_rounded),
                    tooltip: l10n.calorieBudgetDetailsInfoTooltip,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (viewMode) {
                CalorieSummaryViewMode.balance => const BurnWeekLiveOverview(
                  key: ValueKey<String>('burn_week_live_overview'),
                ),
                CalorieSummaryViewMode.classic => ClassicSummaryHero(
                  key: const ValueKey<String>('classic_summary_hero'),
                  remainingKcal: classicRemainingKcal,
                  color: classicRemainingKcal < 0
                      ? colorScheme.error
                      : colorScheme.primary,
                  consumedKcal: consumedKcal,
                  baseGoalKcal: classicBaseGoalKcal,
                  activityDeltaKcal: classicActivityDeltaKcal,
                  availableActivityDeltaKcal: availableClassicActivityDeltaKcal,
                  carryoverKcal: classicCarryoverKcal,
                  availableCarryoverKcal: availableClassicCarryoverKcal,
                  label: remainingLabel,
                  numberFormat: numberFormat,
                ),
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: MacroProgressCard(
                    macroId: 'carbs',
                    label: carbsLabel,
                    current: totalCarbs,
                    target: macroGoals.carbs,
                    color: const Color(0xFF3B82F6),
                    unitLabel: gramUnit,
                    numberFormat: numberFormat,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MacroProgressCard(
                    macroId: 'protein',
                    label: proteinLabel,
                    current: totalProtein,
                    target: macroGoals.protein,
                    color: const Color(0xFFF97316),
                    unitLabel: gramUnit,
                    numberFormat: numberFormat,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MacroProgressCard(
                    macroId: 'fat',
                    label: fatLabel,
                    current: totalFat,
                    target: macroGoals.fat,
                    color: const Color(0xFFEF4444),
                    unitLabel: gramUnit,
                    numberFormat: numberFormat,
                  ),
                ),
              ],
            ),
            if (viewMode == CalorieSummaryViewMode.classic) ...[
              const SizedBox(height: AppSpacing.lg),
              ClassicSummaryMetaToggles(
                data: balanceData,
                numberFormat: numberFormat,
                kcalUnit: kcalUnit,
                includeActivityDelta: includeClassicActivityDelta,
                includeCarryover: includeClassicCarryover,
                onToggleActivityDelta: (value) => ref
                    .read(
                      calorieSummaryClassicAdjustmentsControllerProvider
                          .notifier,
                    )
                    .setIncludeActivityDelta(value: value),
                onToggleCarryover: (value) => ref
                    .read(
                      calorieSummaryClassicAdjustmentsControllerProvider
                          .notifier,
                    )
                    .setIncludeCarryover(value: value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _showClassicBudgetDetails({
  required BuildContext context,
  required AppLocalizations l10n,
  required NumberFormat numberFormat,
  required String kcalUnit,
  required CalorieClassicBudgetBreakdown budget,
  required double availableActivityDeltaKcal,
  required double availableCarryoverKcal,
}) {
  return showCalorieBudgetDetailsDialog(
    context: context,
    data: CalorieBudgetDetailsData(
      title: l10n.calorieBudgetDetailsClassicTitle,
      primaryLabel: l10n.calorieBudgetDetailsConsumedLabel,
      primaryValue: _formatKcal(budget.consumedKcal, numberFormat, kcalUnit),
      secondaryLabel: l10n.calorieBudgetDetailsBudgetLabel,
      secondaryValue: _formatKcal(budget.goalKcal, numberFormat, kcalUnit),
      explanation: l10n.calorieBudgetDetailsClassicExplanation,
      lines: [
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsBaseGoal,
          value: _formatKcal(budget.baseGoalKcal, numberFormat, kcalUnit),
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsActivityIncluded,
          value: _formatSignedKcal(
            budget.includedActivityDeltaKcal,
            numberFormat,
            kcalUnit,
          ),
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsActivityAvailable,
          value: _formatSignedKcal(
            availableActivityDeltaKcal,
            numberFormat,
            kcalUnit,
          ),
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsCarryoverIncluded,
          value: _formatSignedKcal(
            budget.includedCarryoverKcal,
            numberFormat,
            kcalUnit,
          ),
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsCarryoverAvailable,
          value: _formatSignedKcal(
            availableCarryoverKcal,
            numberFormat,
            kcalUnit,
          ),
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsTodayBudget,
          value: _formatKcal(budget.goalKcal, numberFormat, kcalUnit),
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsFoodToday,
          value: _formatKcal(budget.consumedKcal, numberFormat, kcalUnit),
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsRemaining,
          value: _formatSignedKcal(
            budget.remainingKcal,
            numberFormat,
            kcalUnit,
          ),
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsMinimumFloor,
          value: _formatKcal(
            minimumDailyCalorieBudgetKcal,
            numberFormat,
            kcalUnit,
          ),
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsCarryoverRule,
          value: l10n.calorieBudgetDetailsCarryoverRuleValue,
        ),
      ],
    ),
  );
}

String _formatKcal(
  double value,
  NumberFormat numberFormat,
  String kcalUnit,
) {
  return '${numberFormat.format(value.round())} $kcalUnit';
}

String _formatSignedKcal(
  double value,
  NumberFormat numberFormat,
  String kcalUnit,
) {
  final roundedValue = value.round();
  final sign = roundedValue > 0 ? '+' : '';
  return '$sign${numberFormat.format(roundedValue)} $kcalUnit';
}
