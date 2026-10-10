import 'package:yamt/features/cookbook_new/application/ingredient_stock_match.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
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
  final unit = ingredientUnitLabel(l10n, requirement);
  return unit == null
      ? '${requirement.amount}'
      : l10n.freeCookingAmountWithUnit(requirement.amount, unit);
}

/// The unit of [requirement], such as "g" or "EL", or `null` for pieces
/// without a measure.
String? ingredientUnitLabel(
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

/// How much of the missing unit of [line] the Vorrat holds, such as "400 g",
/// or `null` when nothing is missing.
String? ingredientStockedLabel(
  AppLocalizations l10n,
  RecipeIngredientLine line,
) {
  final unit = line.shortfall?.unit;
  if (unit == null) {
    return null;
  }
  return ingredientStockLabel(
    l10n,
    ingredientStockedAmount(line.items, unit),
    unit,
  );
}
