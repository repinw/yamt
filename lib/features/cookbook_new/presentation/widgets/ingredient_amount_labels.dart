import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The amount of [requirement] as text, such as "500 g", or `null` when the
/// ingredient has no amount.
String? ingredientAmountLabel(
  AppLocalizations l10n,
  TemplateIngredientRequirement? requirement,
) {
  if (requirement == null) {
    return null;
  }
  final unit = switch (requirement.unit) {
    TemplateIngredientUnit.gram => l10n.inventoryUnitGram,
    TemplateIngredientUnit.milliliter => l10n.inventoryUnitMilliliter,
    TemplateIngredientUnit.piece => requirement.countMeasureLabel,
  };
  return unit == null
      ? '${requirement.amount}'
      : l10n.freeCookingAmountWithUnit(requirement.amount, unit);
}

/// The amount left in the Vorrat as text, such as "200 g" or "3 Stk.".
String ingredientStockLabel(
  AppLocalizations l10n,
  int amount,
  InventoryAmountUnit unit,
) {
  return switch (unit) {
    InventoryAmountUnit.gram => l10n.freeCookingAmountWithUnit(
      amount,
      l10n.inventoryUnitGram,
    ),
    InventoryAmountUnit.milliliter => l10n.freeCookingAmountWithUnit(
      amount,
      l10n.inventoryUnitMilliliter,
    ),
    InventoryAmountUnit.piece => l10n.freeCookingPieces(amount),
  };
}
