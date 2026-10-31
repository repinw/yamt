import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What the big kcal number of the budget card shows on a day that is not
/// a pause day: the value as text, the unit under it, its color, and
/// the amount behind the value.
typedef DiaryBudgetKcalTexts = ({
  String value,
  String unit,
  Color color,
  double amount,
});

/// The big kcal number of [data]: the kcal left (or over, in the error color
/// when going over is a miss), or with [showEaten] the kcal eaten with the
/// counted plans.
DiaryBudgetKcalTexts diaryBudgetKcalTexts(
  BuildContext context, {
  required DiaryBudgetCardData data,
  required bool showEaten,
  required NumberFormat numberFormat,
}) {
  final l10n = AppLocalizations.of(context)!;
  final colors = FoodLabelColors.of(context);
  final metrics = data.metrics;
  String kcal(double value) => numberFormat.format(value.round());

  final left = data.leftKcal;
  final counted = metrics.eatenKcal + data.countedPlannedKcal;
  final withPlans = data.countsPlans || data.isPlannedDay;
  return (
    value: showEaten
        ? kcal(counted)
        : data.isOver
        ? l10n.diaryBudgetOverValue(kcal(-left))
        : kcal(left),
    unit: showEaten
        ? withPlans
              ? l10n.diaryBudgetKcalWithPlanOf(kcal(metrics.targetKcal))
              : l10n.diaryBudgetKcalEatenOf(kcal(metrics.targetKcal))
        : data.isOver
        ? l10n.diaryBudgetKcalOver
        : withPlans
        ? l10n.diaryBudgetKcalLeftAfterPlan
        : l10n.diaryBudgetKcalLeft,
    // Going over is the miss for every weight goal but gaining.
    color: data.isOver
        ? data.overIsMiss
              ? Theme.of(context).colorScheme.error
              : colors.ink
        : data.isPlannedDay
        ? colors.plan
        : colors.accentText,
    amount: showEaten ? counted : left,
  );
}
