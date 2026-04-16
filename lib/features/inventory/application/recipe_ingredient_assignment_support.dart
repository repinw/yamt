import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Defines recipe ingredient effective requirement.
class RecipeIngredientEffectiveRequirement {
  /// The recipe ingredient effective requirement.
  const RecipeIngredientEffectiveRequirement({
    required this.amount,
    required this.unit,
    required this.name,
  });

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

/// Can auto assign inventory item.
bool canAutoAssignInventoryItem({
  required TemplateIngredientRequirement? requirement,
  required InventoryItem item,
}) {
  if (requirement == null) {
    return true;
  }

  if (requirement.unit == InventoryAmountUnit.piece) {
    if (!requirement.allowsDirectPieceInventoryMatch) {
      return false;
    }
    return !item.usesAmountProgress;
  }

  return item.usesAmountProgress && item.amountUnit == requirement.unit;
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
  if (sharedAmountUnit != null) {
    if (requirement.unit != InventoryAmountUnit.piece) {
      if (sharedAmountUnit != requirement.unit) {
        return null;
      }
      return RecipeIngredientEffectiveRequirement(
        amount: requirement.amount,
        unit: requirement.unit,
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
      requirement.unit != InventoryAmountUnit.piece) {
    return null;
  }
  if (!requirement.allowsDirectPieceInventoryMatch) {
    return null;
  }

  return RecipeIngredientEffectiveRequirement(
    amount: requirement.amount,
    unit: requirement.unit,
    name: requirement.name,
  );
}

/// Can select inventory item for requirement.
bool canSelectInventoryItemForRequirement({
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> selectedItems,
  required InventoryItem candidate,
}) {
  if (requirement == null) {
    return true;
  }

  if (requirement.unit != InventoryAmountUnit.piece) {
    return candidate.usesAmountProgress &&
        candidate.amountUnit == requirement.unit;
  }

  if (selectedItems.isEmpty) {
    if (!requirement.allowsDirectPieceInventoryMatch) {
      return candidate.usesAmountProgress;
    }
    return true;
  }

  if (usesOnlyPieceTrackedItems(selectedItems)) {
    return requirement.allowsDirectPieceInventoryMatch &&
        !candidate.usesAmountProgress;
  }

  final sharedAmountUnit = resolveSharedAmountProgressUnit(selectedItems);
  if (sharedAmountUnit == null) {
    return false;
  }

  return candidate.usesAmountProgress &&
      candidate.amountUnit == sharedAmountUnit;
}
