import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/consumed_unit_l10n.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Formats the portion or bundle amount string for a diary meal entry.
String? formatDiaryMealPortionLabel(
  BuildContext context,
  DiaryMealEntry entry,
) {
  final l10n = AppLocalizations.of(context)!;
  final combinedFoods = entry.combinedFoods;
  if (combinedFoods != null) {
    return l10n.caloriesCombinedFoodCount(combinedFoods.length);
  }
  if (entry.isPreparedMeal) {
    final consumed = entry.bundleConsumedPortions ?? 0;
    final formattedConsumed = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(consumed);
    return l10n.caloriesBundlePortions(
      formattedConsumed,
      entry.bundleTotalPortions!,
    );
  }
  final amount = entry.consumedAmount;
  if (amount == null || amount <= 0) {
    return null;
  }
  final format = NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  )..maximumFractionDigits = 1;
  final unit = entry.consumedUnit?.localizedName(l10n) ?? l10n.caloriesUnitGram;
  final portionAmount = entry.portionAmount;
  final portionLabel = entry.portionLabel;
  if (portionAmount != null && portionAmount > 0 && portionLabel != null) {
    // An edited amount that is no longer a count in tenths shows grams.
    // The amount has one decimal, so 0,5 × 33,3 g reads back from 16,7 g.
    final count = (amount / portionAmount * 10).round() / 10;
    if (count > 0 && (amount - count * portionAmount).abs() <= 0.05 + 0.001) {
      return l10n.caloriesCountedPortion(
        _formatCount(count, format),
        format.format(portionAmount),
        unit,
        portionLabel,
      );
    }
  }
  return '${format.format(amount)} $unit';
}

String _formatCount(double count, NumberFormat format) {
  final whole = count.floor();
  if ((count - whole - 0.5).abs() < 0.001) {
    return whole == 0 ? '½' : '$whole½';
  }
  return format.format(count);
}

/// The amount of a meal plan as the meal is now: a share of the pot while it
/// is in the pot ("½ Topf"), else its portions of the cooked meal. Null
/// without the meal, so the row keeps the stored amount.
String? diaryPlanPortionText(
  AppLocalizations l10n,
  CalorieEntry plan,
  PreparedMeal? meal,
) {
  if (meal == null || plan.bundleSourcePreparedMealId != meal.id) {
    return null;
  }
  final share = preparedMealPlanShare(plan, meal);
  final format = NumberFormat.decimalPattern(l10n.localeName)
    ..maximumFractionDigits = 2;
  final amount = formatQuickChipAmount(share, format.format);
  return meal.isInPot
      ? l10n.inventoryEatSheetAmountWithUnit(amount, l10n.eatPagePotUnit)
      : l10n.caloriesBundlePortions(amount, meal.totalPortions);
}
