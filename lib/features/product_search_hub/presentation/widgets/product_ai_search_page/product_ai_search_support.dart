import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/application/'
    'product_ai_nutrition_selection.dart';
import 'package:yamt/features/product_search_hub/application/'
    'product_ai_search_result_builder.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_ai_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_ai_search_result.dart';

/// Resolves nutrition selection from draft, weight, and chosen kcal density.
ProductAiNutritionSelection? resolveProductAiNutritionSelection({
  required ProductAiSearchDraft? draft,
  required double? weightGrams,
  required double? selectedPer100Kcal,
}) {
  if (draft == null || weightGrams == null) {
    return null;
  }
  return buildProductAiNutritionSelection(
    draft: draft,
    weightGrams: weightGrams,
    selectedPer100Kcal: selectedPer100Kcal ?? baseProductAiPer100Kcal(draft),
  );
}

/// Returns the base kcal per 100g for [draft].
double resolveProductAiBasePer100Kcal(ProductAiSearchDraft draft) =>
    baseProductAiPer100Kcal(draft);

/// Parses weight input string and returns null if invalid or not positive.
double? parseProductAiWeightInput(String value) {
  final parsed = parseManualProductDouble(value);
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed;
}

/// Checks whether [selectedLoggedAt] is on the same calendar day as [now].
bool isProductAiLoggedAtToday({
  required DateTime selectedLoggedAt,
  required DateTime now,
}) {
  final today = DateUtils.dateOnly(now);
  final selectedDay = DateUtils.dateOnly(selectedLoggedAt);
  return selectedDay == today;
}

/// Prompts user to pick a logged-at date clamped up to [now].
Future<DateTime?> pickProductAiLoggedDate({
  required BuildContext context,
  required DateTime selectedLoggedAt,
  required DateTime now,
}) async {
  final initialDate = DateUtils.dateOnly(selectedLoggedAt);
  final lastDate = DateUtils.dateOnly(now);
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
    firstDate: DateTime(2000),
    lastDate: lastDate,
  );
  if (pickedDate == null) {
    return null;
  }
  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    now.hour,
    now.minute,
  );
}

/// Builds a [ManualProductAiSearchResult] from user selections.
ManualProductAiSearchResult buildManualProductAiSearchResult({
  required InventoryItem baseItem,
  required ProductAiNutritionSelection selection,
  required InventoryReceiptManualProductAction action,
  required DateTime loggedAt,
  required MealType mealType,
}) {
  return ManualProductAiSearchResult(
    item: buildProductAiResultItem(baseItem: baseItem, selection: selection),
    action: action,
    globalPackageWeight: selection.weightLabel,
    eatSelection: buildProductAiEatSelection(
      eatNow: action == InventoryReceiptManualProductAction.eatNow,
      selection: selection,
      loggedAt: loggedAt,
      mealType: mealType,
    ),
  );
}
