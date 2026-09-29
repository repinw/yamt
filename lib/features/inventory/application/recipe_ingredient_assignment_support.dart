import 'package:yamt/features/inventory/application/'
    'template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// Defines recipe ingredient effective requirement.
class RecipeIngredientEffectiveRequirement {
  /// The recipe ingredient effective requirement.
  const new({required this.amount, required this.unit, required this.name});

  /// The amount.
  final int amount;

  /// The unit.
  final InventoryAmountUnit unit;

  /// The name.
  final String name;
}

/// Resolve shared amount progress unit.
InventoryAmountUnit? resolveSharedAmountProgressUnit(
  List<InventoryItem> items,
) {
  if (items.isEmpty) {
    return null;
  }

  InventoryAmountUnit? sharedUnit;
  for (final item in items) {
    final itemUnit = item.amountUnit;
    if (!item.usesAmountProgress || itemUnit == null) {
      return null;
    }
    if (sharedUnit == null) {
      sharedUnit = itemUnit;
      continue;
    }
    if (sharedUnit != itemUnit) {
      return null;
    }
  }

  return sharedUnit;
}

/// Uses only piece tracked items.
bool usesOnlyPieceTrackedItems(List<InventoryItem> items) {
  return items.isNotEmpty && items.every((item) => !item.usesAmountProgress);
}

/// Resolve effective requirement for items.
RecipeIngredientEffectiveRequirement? resolveEffectiveRequirementForItems({
  required TemplateIngredientRequirement requirement,
  required List<InventoryItem> assignedItems,
  required RecipeIngredientAmountConversion? amountConversion,
}) {
  if (assignedItems.isEmpty) {
    return null;
  }

  final sharedAmountUnit = resolveSharedAmountProgressUnit(assignedItems);
  final requiredUnit = requirement.inventoryUnit;
  if (sharedAmountUnit != null) {
    if (requiredUnit != InventoryAmountUnit.piece) {
      if (sharedAmountUnit != requiredUnit) {
        return null;
      }
      return RecipeIngredientEffectiveRequirement(
        amount: requirement.amount,
        unit: requiredUnit,
        name: requirement.name,
      );
    }

    if (sharedAmountUnit == InventoryAmountUnit.piece &&
        requirement.allowsDirectPieceInventoryMatch) {
      return RecipeIngredientEffectiveRequirement(
        amount: requirement.amount,
        unit: requiredUnit,
        name: requirement.name,
      );
    }

    if (amountConversion == null ||
        amountConversion.amountPerPiece < 1 ||
        amountConversion.unit != sharedAmountUnit) {
      return null;
    }

    return RecipeIngredientEffectiveRequirement(
      amount: requirement.amount * amountConversion.amountPerPiece,
      unit: sharedAmountUnit,
      name: requirement.name,
    );
  }

  if (!usesOnlyPieceTrackedItems(assignedItems) ||
      requiredUnit != InventoryAmountUnit.piece) {
    return null;
  }
  if (!requirement.allowsDirectPieceInventoryMatch) {
    return null;
  }

  return RecipeIngredientEffectiveRequirement(
    amount: requirement.amount,
    unit: requiredUnit,
    name: requirement.name,
  );
}
