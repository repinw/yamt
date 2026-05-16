import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// Maps recipe ingredient units to inventory amount units.
extension TemplateIngredientUnitInventoryMapper on TemplateIngredientUnit {
  /// Converts a recipe ingredient unit to an inventory amount unit.
  InventoryAmountUnit toInventoryAmountUnit() {
    return switch (this) {
      TemplateIngredientUnit.gram => InventoryAmountUnit.gram,
      TemplateIngredientUnit.milliliter => InventoryAmountUnit.milliliter,
      TemplateIngredientUnit.piece => InventoryAmountUnit.piece,
    };
  }
}

/// Maps inventory amount units back to recipe ingredient units for labels.
extension InventoryAmountUnitTemplateIngredientMapper on InventoryAmountUnit {
  /// Converts an inventory amount unit to a recipe ingredient unit.
  TemplateIngredientUnit toTemplateIngredientUnit() {
    return switch (this) {
      InventoryAmountUnit.gram => TemplateIngredientUnit.gram,
      InventoryAmountUnit.milliliter => TemplateIngredientUnit.milliliter,
      InventoryAmountUnit.piece => TemplateIngredientUnit.piece,
    };
  }
}

/// Maps recipe ingredient requirements to inventory amount units.
extension TemplateIngredientRequirementInventoryMapper
    on TemplateIngredientRequirement {
  /// Inventory amount unit for this requirement.
  InventoryAmountUnit get inventoryUnit {
    return unit.toInventoryAmountUnit();
  }
}
