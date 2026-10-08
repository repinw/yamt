import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';
import 'package:yamt/features/inventory/presentation/formatters/'
    'inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/prepared_meal_serving_unit_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Texts of a Vorrat row or tile: the amount left with its unit, the full
/// amount, and an info line.
class InventoryEntryTexts {
  /// Creates the texts.
  const new({
    required this.amount,
    required this.unit,
    required this.ofFull,
    required this.info,
    this.infoIsWarning = false,
  });

  /// Texts of [entry]. A food that open plans take [planned] of, in its
  /// stored unit, names that amount in place of the full amount.
  factory of(
    InventoryListEntry entry,
    AppLocalizations l10n, {
    int planned = 0,
  }) {
    final texts = switch (entry) {
      InventoryFoodEntry(:final item) => _food(item, l10n),
      InventoryMealEntry(:final meal) => _meal(meal, l10n),
    };
    final ofFull = switch (entry) {
      InventoryFoodEntry(:final item) when planned > 0 =>
        l10n.inventoryRowPlanned(_stored(item, planned)),
      _ when entry.isLow => l10n.inventoryRowLow,
      _ => null,
    };
    if (ofFull == null) {
      return texts;
    }
    return InventoryEntryTexts(
      amount: texts.amount,
      unit: texts.unit,
      ofFull: ofFull,
      info: texts.info,
      infoIsWarning: texts.infoIsWarning,
    );
  }

  /// Amount left, such as "820".
  final String amount;

  /// Unit of [amount], such as "g".
  final String unit;

  /// Full amount, such as "von 1000 g", or "fast leer" when almost empty.
  final String ofFull;

  /// Brand and energy of a food, or the portions of a meal.
  final String info;

  /// Whether [info] warns, such as missing meal ingredients.
  final bool infoIsWarning;
}

InventoryEntryTexts _food(InventoryItem item, AppLocalizations l10n) {
  final brand = item.brand?.trim() ?? '';
  final kcal = item.nutrition?.per100Kcal;
  final kcalText = kcal == null
      ? ''
      : l10n.inventoryRowKcalPer100(formatInventoryNutritionValue(kcal));
  final info = brand.isNotEmpty && kcalText.isNotEmpty
      ? l10n.inventoryRowInfo(brand, kcalText)
      : (brand.isNotEmpty ? brand : kcalText);

  final unit = item.amountUnit;
  if (item.usesAmountProgress && unit != null) {
    String format(int value) => formatInventoryAmountValue(
      amount: value,
      unit: unit,
      scale: item.amountScale,
    );
    final unitName = unit.localizedName(l10n);
    return InventoryEntryTexts(
      amount: format(item.currentAmount.clamp(0, item.initialAmount)),
      unit: unitName,
      ofFull: l10n.inventoryRowOfAmount(
        l10n.inventoryEatSheetAmountWithUnit(
          format(item.initialAmount),
          unitName,
        ),
      ),
      info: info,
    );
  }
  final initial = item.effectiveInitialQuantity;
  return InventoryEntryTexts(
    amount: '${item.quantity.clamp(0, initial)}',
    unit: l10n.inventoryUnitPiece,
    ofFull: l10n.inventoryRowOfAmount(
      l10n.inventoryEatSheetAmountWithUnit('$initial', l10n.inventoryUnitPiece),
    ),
    info: info,
  );
}

/// [amount] of [item]'s stored unit as the row shows it.
String _stored(InventoryItem item, int amount) {
  final unit = item.amountUnit;
  if (item.usesAmountProgress && unit != null) {
    return formatInventoryAmountValue(
      amount: amount,
      unit: unit,
      scale: item.amountScale,
    );
  }
  return '$amount';
}

InventoryEntryTexts _meal(PreparedMeal meal, AppLocalizations l10n) {
  final portionsLeft = formatInventoryNutritionValue(
    meal.remainingPortions.toDouble(),
  );
  final missing = meal.pendingRecipeIngredients.length;
  // Until "Gekocht", the pot matters more than its open rows.
  final isMissingShown = !meal.isInPot && missing > 0;
  final info = meal.isInPot
      ? l10n.inventoryMealInPot
      : isMissingShown
      ? l10n.inventoryRowMealMissing(missing)
      : meal.isServedInPieces
      ? l10n.inventoryRowMealFromRecipePieces(portionsLeft, meal.totalPortions)
      : meal.recipeIngredients.isNotEmpty
      ? l10n.inventoryRowMealFromRecipe(portionsLeft, meal.totalPortions)
      : l10n.inventoryRowMealCombined(portionsLeft, meal.totalPortions);

  final netWeight = meal.finalNetWeight;
  // A weighing while eating tells the grams left better than "Gekocht".
  final weightLeft = PreparedMealEatCalculator(meal).currentNetWeight;
  if (netWeight != null && netWeight > 0 && weightLeft != null) {
    final gram = l10n.inventoryUnitGram;
    return InventoryEntryTexts(
      amount: '$weightLeft',
      unit: gram,
      ofFull: l10n.inventoryRowOfAmount(
        l10n.inventoryEatSheetAmountWithUnit('$netWeight', gram),
      ),
      info: info,
      infoIsWarning: isMissingShown,
    );
  }
  final portions = preparedMealServingUnit(l10n, meal);
  return InventoryEntryTexts(
    amount: portionsLeft,
    unit: portions,
    ofFull: l10n.inventoryRowOfAmount(
      l10n.inventoryEatSheetAmountWithUnit('${meal.totalPortions}', portions),
    ),
    info: info,
    infoIsWarning: isMissingShown,
  );
}
