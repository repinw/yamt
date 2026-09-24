import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_buffer_badge.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_practice_day_badge.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_balance_metrics_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_balance_subtitle_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_details_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_goal_progress_bar.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_quiet_kcal_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_bars.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Daily calories, macros, and pacing balance card.
///
/// Quiet by default: only what is left. Tapping the card toggles the details
/// (eaten, targets, base, and carryover).
class DiaryDailyBalanceCard extends StatelessWidget {
  /// Creates the daily balance card.
  const new({
    required this.data,
    required this.showDetails,
    required this.onToggleDetails,
    this.kcalBarKey,
    this.macroBarsKey,
    this.practiceStartDate,
    super.key,
  });

  /// Render-ready daily card data.
  final DiaryDailyBalanceData data;

  /// Whether all numbers are shown.
  final bool showDetails;

  /// Called when the card is tapped.
  final VoidCallback onToggleDetails;

  /// Key of the kcal progress bar, used to detect when it scrolls away.
  final Key? kcalBarKey;

  /// Key of the macro bars, used to detect when they scroll away.
  final Key? macroBarsKey;

  /// First counting day when the selected day is a practice day before it.
  final DateTime? practiceStartDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    // Quiet cards show the kcal row like a macro row. Pause days show a word
    // instead of a number, so they keep the stacked header.
    final compactHeader = !showDetails && !data.isPauseDay;
    final kcalBar = DiaryDailyGoalProgressBar(
      key: kcalBarKey,
      eatenKcal: data.metrics.eatenKcal,
      targetKcal: data.metrics.targetKcal,
      numberFormat: data.numberFormat,
      unit: l10n.caloriesUnitKcal,
      compact: true,
    );

    return Semantics(
      button: true,
      label: showDetails
          ? l10n.diaryBalanceHideDetails
          : l10n.diaryBalanceShowDetails,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggleDetails,
        child: DiaryBalanceShell(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (practiceStartDate case final startDate?) ...[
                    DiaryBalancePracticeDayBadge(startDate: startDate),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (compactHeader)
                    DiaryQuietKcalRow(data: data, bar: kcalBar)
                  else ...[
                    DiaryDailyBalanceMetricsRow(
                      data: data,
                      showDetails: showDetails,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    kcalBar,
                  ],
                  if (showDetails) ...[
                    const SizedBox(height: AppSpacing.xs),
                    DiaryDailyBalanceSubtitleRow(
                      data: data,
                      onBudgetDetailsTap: data.budgetDetails == null
                          ? null
                          : () => showDiaryDailyBudgetDetailsSheet(
                              context: context,
                              data: data.budgetDetails!,
                              numberFormat: data.numberFormat,
                            ),
                    ),
                    if (data.bufferAdjustmentLabel != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      DiaryBalanceBufferBadge(
                        label: data.bufferAdjustmentLabel!,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Divider(
                      height: AppSizes.dividerThickness,
                      thickness: AppSizes.dividerThickness,
                      color: colors.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  DiaryNutritionBars.embedded(
                    key: macroBarsKey,
                    selectedDay: data.selectedDay,
                    showTotals: showDetails,
                  ),
                  if (showDetails)
                    Icon(
                      Icons.expand_less_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                ],
              ),
              // Quiet cards hint in the empty top-right corner that a tap
              // shows more numbers.
              if (!showDetails)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
