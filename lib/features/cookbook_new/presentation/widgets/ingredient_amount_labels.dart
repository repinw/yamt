import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/recipes/application/ingredient_exact_quantity.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The amount of [requirement] as text, as exact as the Kochmodus says it,
/// such as "500 g", "2,5 TL" or "1/2", or `null` when the ingredient has no
/// amount.
String? ingredientAmountLabel(
  AppLocalizations l10n,
  TemplateIngredientRequirement? requirement,
) {
  if (requirement == null) {
    return null;
  }
  final quantity = ingredientQuantityText(requirement);
  final unit = _ingredientUnitLabel(l10n, requirement);
  return unit == null ? quantity : l10n.cookAmountOf(quantity, unit);
}

/// The unit of [requirement], such as "g" or "EL", or `null` for pieces
/// without a measure.
String? _ingredientUnitLabel(
  AppLocalizations l10n,
  TemplateIngredientRequirement requirement,
) => switch (requirement.unit) {
  TemplateIngredientUnit.gram => l10n.inventoryUnitGram,
  TemplateIngredientUnit.milliliter => l10n.inventoryUnitMilliliter,
  TemplateIngredientUnit.piece => requirement.countMeasureLabel,
};

/// The amount left in the Vorrat as text, such as "200 g" or "3 Stk.".
String ingredientStockLabel(
  AppLocalizations l10n,
  int amount,
  InventoryAmountUnit unit,
) {
  return switch (unit) {
    InventoryAmountUnit.gram => l10n.cookingAmountWithUnit(
      amount,
      l10n.inventoryUnitGram,
    ),
    InventoryAmountUnit.milliliter => l10n.cookingAmountWithUnit(
      amount,
      l10n.inventoryUnitMilliliter,
    ),
    InventoryAmountUnit.piece => l10n.cookingPieces(amount),
  };
}
