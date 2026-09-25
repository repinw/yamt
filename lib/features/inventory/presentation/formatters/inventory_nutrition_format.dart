import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Format inventory nutrition value.
String formatInventoryNutritionValue(double value) {
  return value.toNutritionMetricValue();
}

/// Metrics for the nutrition strip. Unknown values are left out.
List<NutritionMetric> eatNutritionMetrics(
  AppLocalizations l10n,
  EatNutrition nutrition,
) {
  return [
    if (nutrition.eaten.kcal case final kcal?)
      NutritionMetric(
        label: l10n.inventoryNutritionCaloriesShortLabel,
        value: kcal.round().toString(),
      ),
    if (nutrition.eaten.carbs case final carbs?)
      NutritionMetric(
        label: l10n.inventoryNutritionCarbsShortLabel,
        value: _formatGrams(l10n, carbs),
      ),
    if (nutrition.eaten.protein case final protein?)
      NutritionMetric(
        label: l10n.caloriesProteinLabel,
        value: _formatGrams(l10n, protein),
      ),
    if (nutrition.eaten.fat case final fat?)
      NutritionMetric(
        label: l10n.caloriesFatLabel,
        value: _formatGrams(l10n, fat),
      ),
  ];
}

String _formatGrams(AppLocalizations l10n, double value) {
  return l10n.inventoryEatSheetAmountCompact(
    formatInventoryNutritionValue(value),
    l10n.inventoryUnitGram,
  );
}
