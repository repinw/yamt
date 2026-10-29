import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_details_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// How the kcal left come about, row by row: base, day type, buffer,
/// carryover, eaten, counted plans, and what is left. "Alle Tage" opens the
/// budget sheet with every day of the run.
class DiaryBudgetLedger extends StatelessWidget {
  /// Creates the ledger.
  const new({required this.data, required this.numberFormat, super.key});

  /// Card data.
  final DiaryBudgetCardData data;

  /// Locale number format.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final details = data.budgetDetails;
    final planned = data.countedPlannedKcal;
    final rows = _rows(l10n, colors);

    return DecoratedBox(
      key: DiaryBudgetCardKeys.ledger,
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppBudgetCard.boxRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...rows,
            if (details != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: DiaryBudgetCardKeys.allDaysLink,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.muted,
                    minimumSize: const Size(0, AppSizes.minTapTarget),
                    textStyle: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(
                          fontFamily: AppFonts.geist,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                  onPressed: () => showDiaryDailyBudgetDetailsSheet(
                    context: context,
                    data: details,
                    numberFormat: numberFormat,
                    plannedKcal: data.countsPlans ? planned : null,
                  ),
                  child: Text(l10n.diaryBudgetAllDays),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The rows of [data], the total last.
  List<Widget> _rows(AppLocalizations l10n, FoodLabelColors colors) {
    final metrics = data.metrics;
    final details = data.budgetDetails;
    String kcal(double value) => numberFormat.format(value.round());
    String signed(double value) => value.round() < 0
        ? '−${kcal(-value)}'
        : value.round() > 0
        ? '+${kcal(value)}'
        : kcal(0);
    final planned = data.countedPlannedKcal;
    final left = data.leftKcal;
    return [
      if (data.isPauseDay) ...[
        _Row(l10n.diaryBalanceEatenLabel, kcal(metrics.realEatenKcal)),
        if (planned > 0)
          _Row(
            l10n.diaryBalancePlannedLabel,
            kcal(planned),
            color: colors.plan,
          ),
        _Row(
          l10n.diaryBalancePauseDayValue,
          l10n.diaryBalancePauseDaySubtitle,
          isTotal: true,
        ),
      ] else ...[
        _Row(
          l10n.diaryBalanceBaseLabel,
          kcal(details?.unadjustedBaseGoalKcal ?? metrics.baseGoalKcal),
        ),
        if (details != null &&
            details.unadjustedBaseGoalKcal != null &&
            details.hasCyclingAdjustment)
          _Row(
            details.isTrainingDay
                ? l10n.diaryDayTypeTraining
                : l10n.diaryDayTypeNormal,
            signed(details.cyclingAdjustmentKcal),
          ),
        if (metrics.bufferAdjustmentKcal.round() != 0)
          _Row(
            l10n.diaryBudgetBufferRow,
            signed(-metrics.bufferAdjustmentKcal),
          ),
        if (metrics.carryoverKcal.round() != 0)
          _Row(l10n.diaryBudgetCarryoverRow, signed(metrics.carryoverKcal)),
        if (data.isPlannedDay)
          _Row(
            l10n.diaryBalancePlannedLabel,
            signed(-metrics.realEatenKcal),
            color: colors.plan,
          )
        else
          _Row(l10n.diaryBalanceEatenLabel, signed(-metrics.realEatenKcal)),
        if (planned > 0)
          _Row(
            l10n.diaryBudgetPlannedCountedRow,
            signed(-planned),
            color: colors.plan,
          ),
        _Row(
          data.isOver
              ? l10n.diaryBudgetOverRow
              : data.countsPlans || data.isPlannedDay
              ? l10n.diaryBalanceLeftAfterPlanLabel
              : l10n.diaryBalanceLeftLabel,
          data.isOver ? l10n.diaryBudgetOverValue(kcal(-left)) : kcal(left),
          isTotal: true,
        ),
      ],
    ];
  }
}

/// One label and value of the ledger; the total row is bold over a rule.
class _Row extends StatelessWidget {
  const new(this.label, this.value, {this.color, this.isTotal = false});

  final String label;
  final String value;
  final Color? color;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: AppFonts.geist,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppBudgetCard.ledgerRow),
      child: Row(
        spacing: AppSpacing.xs,
        children: [
          Expanded(
            child: Text(
              label,
              style: style?.copyWith(
                color: color ?? (isTotal ? colors.ink : colors.muted),
              ),
            ),
          ),
          Text(value, style: style?.copyWith(color: color ?? colors.ink)),
        ],
      ),
    );
    if (!isTotal) {
      return row;
    }
    return DecoratedBox(
      key: DiaryBudgetCardKeys.ledgerTotal,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxs),
        child: row,
      ),
    );
  }
}
