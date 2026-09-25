import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_buffer_badge.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_practice_day_badge.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_balance_subtitle_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_details_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_kcal_left_header.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_kcal_ruler.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_bars.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Daily calories, macros, and pacing balance, drawn like a food label
/// ruler without a card frame.
///
/// Quiet by default: only what is left. Tapping it toggles the details
/// (eaten, target, base, carryover, and the eaten grams per macro).
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

  /// Key of the kcal ruler, used to detect when it scrolls away.
  final Key? kcalBarKey;

  /// Key of the macro bars, used to detect when they scroll away.
  final Key? macroBarsKey;

  /// First counting day when the selected day is a practice day before it.
  final DateTime? practiceStartDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Pause days explain themselves in the subtitle, so it stays visible.
    final showSubtitle = showDetails || data.isPauseDay;
    final budgetDetails = data.budgetDetails;
    final bufferLabel = data.bufferAdjustmentLabel;

    return Semantics(
      button: true,
      label: showDetails
          ? l10n.diaryBalanceHideDetails
          : l10n.diaryBalanceShowDetails,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggleDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (practiceStartDate case final startDate?) ...[
              DiaryBalancePracticeDayBadge(startDate: startDate),
              const SizedBox(height: AppSpacing.sm),
            ],
            DiaryKcalLeftHeader(data: data, showDetails: showDetails),
            const SizedBox(height: AppSpacing.lg),
            DiaryKcalRuler(
              key: kcalBarKey,
              eatenKcal: data.metrics.eatenKcal,
              targetKcal: data.metrics.targetKcal,
              scaleEndLabel: showDetails
                  ? l10n.diaryBalanceScaleTarget(
                      data.plannedWithCarryoverNumber,
                    )
                  : null,
            ),
            if (showSubtitle) ...[
              const SizedBox(height: AppSpacing.xs),
              DiaryDailyBalanceSubtitleRow(
                data: data,
                onBudgetDetailsTap: showDetails && budgetDetails != null
                    ? () => showDiaryDailyBudgetDetailsSheet(
                        context: context,
                        data: budgetDetails,
                        numberFormat: data.numberFormat,
                      )
                    : null,
              ),
            ],
            if (showDetails && bufferLabel != null) ...[
              const SizedBox(height: AppSpacing.xs),
              DiaryBalanceBufferBadge(label: bufferLabel),
            ],
            const SizedBox(height: AppSpacing.xl),
            DiaryNutritionBars.embedded(
              key: macroBarsKey,
              selectedDay: data.selectedDay,
              showTotals: showDetails,
            ),
          ],
        ),
      ),
    );
  }
}
