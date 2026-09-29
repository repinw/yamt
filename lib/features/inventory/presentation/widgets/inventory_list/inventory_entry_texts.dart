import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/formatters/'
    'inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
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

  /// Texts of [entry].
  factory of(InventoryListEntry entry, AppLocalizations l10n) {
    final texts = switch (entry) {
      InventoryFoodEntry(:final item) => _food(item, l10n),
      InventoryMealEntry(:final meal) => _meal(meal, l10n),
    };
    if (!entry.isLow) {
      return texts;
    }
    return InventoryEntryTexts(
      amount: texts.amount,
      unit: texts.unit,
      ofFull: l10n.inventoryRowLow,
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

InventoryEntryTexts _meal(PreparedMeal meal, AppLocalizations l10n) {
  final portionsLeft = formatInventoryNutritionValue(
    meal.remainingPortions.toDouble(),
  );
  final missing = meal.pendingRecipeIngredients.length;
  final info = missing > 0
      ? l10n.inventoryRowMealMissing(missing)
      : l10n.inventoryRowMealCooked(portionsLeft, meal.totalPortions);

  final netWeight = meal.finalNetWeight;
  final weightLeft = meal.remainingNetWeight;
  if (netWeight != null && netWeight > 0 && weightLeft != null) {
    final gram = l10n.inventoryUnitGram;
    return InventoryEntryTexts(
      amount: '$weightLeft',
      unit: gram,
      ofFull: l10n.inventoryRowOfAmount(
        l10n.inventoryEatSheetAmountWithUnit('$netWeight', gram),
      ),
      info: info,
      infoIsWarning: missing > 0,
    );
  }
  final portions = l10n.eatPagePortionsUnit;
  return InventoryEntryTexts(
    amount: portionsLeft,
    unit: portions,
    ofFull: l10n.inventoryRowOfAmount(
      l10n.inventoryEatSheetAmountWithUnit('${meal.totalPortions}', portions),
    ),
    info: info,
    infoIsWarning: missing > 0,
  );
}
