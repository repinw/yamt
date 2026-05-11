import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Inventory amount required by one cookflow row.
class CookingFlowInventoryRequirement {
  /// Creates inventory requirement.
  const CookingFlowInventoryRequirement({
    required this.amount,
    required this.unitCode,
  });

  /// Required normalized amount.
  final double amount;

  /// Required normalized unit code.
  final String unitCode;
}

/// Type of conflict between recipe requirement and selected inventory.
enum CookingFlowInventoryConflictKind {
  /// Selected inventory amount is too low.
  shortage,

  /// Selected inventory uses incompatible unit.
  unitConversion,
}

/// Conflict between recipe requirement and selected inventory.
class CookingFlowInventoryCheckConflict {
  /// Creates shortage conflict.
  const CookingFlowInventoryCheckConflict({
    required this.availableAmountLabel,
    required this.missingAmountLabel,
  }) : kind = CookingFlowInventoryConflictKind.shortage,
       requiredUnitCode = '',
       selectedUnitCode = null;

  /// Creates unit conversion conflict.
  const CookingFlowInventoryCheckConflict.unitConversion({
    required this.requiredUnitCode,
    required this.selectedUnitCode,
  }) : kind = CookingFlowInventoryConflictKind.unitConversion,
       availableAmountLabel = '',
       missingAmountLabel = '';

  /// Conflict kind.
  final CookingFlowInventoryConflictKind kind;

  /// Available amount label.
  final String availableAmountLabel;

  /// Missing amount label.
  final String missingAmountLabel;

  /// Required unit code.
  final String requiredUnitCode;

  /// Selected unit code.
  final String? selectedUnitCode;
}

/// Amount usage preview for selected inventory.
class CookingFlowInventoryUsagePreview {
  /// Creates usage preview.
  const CookingFlowInventoryUsagePreview({
    required this.usedAmountLabel,
    required this.remainingAmountLabel,
  });

  /// Amount consumed by cookflow.
  final String usedAmountLabel;

  /// Amount left after cookflow.
  final String remainingAmountLabel;
}

/// Resolves inventory items selected by a row.
List<InventoryItem> cookingFlowResolveSelectedInventoryItems({
  required List<CookingFlowInventoryAssignmentSelection> selectedSelections,
  required List<InventoryItem> inventoryItems,
}) {
  final inventoryById = <String, InventoryItem>{
    for (final item in inventoryItems) item.id: item,
  };
  return selectedSelections
      .map((selection) => inventoryById[selection.itemId])
      .whereType<InventoryItem>()
      .toList(growable: false);
}

/// Returns row amount label after adjust-template resolution.
String cookingFlowInventoryRowDisplayAmountLabel({
  required CookingFlowInventoryCheckRowData row,
  required CookingFlowInventoryRowAction? selectedAction,
  required List<CookingFlowInventoryAssignmentSelection> selectedSelections,
  required List<InventoryItem> inventoryItems,
  required CookingFlowInventoryConflictResolution? conflictResolution,
  String? localeCode,
}) {
  if (selectedAction != CookingFlowInventoryRowAction.assigned ||
      conflictResolution !=
          CookingFlowInventoryConflictResolution.adjustTemplate) {
    return row.amountLabel;
  }

  final requirement = cookingFlowParseInventoryRequirement(
    row.amountLabel,
    localeCode: localeCode,
  );
  if (requirement == null) {
    return row.amountLabel;
  }

  final selectedItems = cookingFlowResolveSelectedInventoryItems(
    selectedSelections: _countedSelections(selectedSelections),
    inventoryItems: inventoryItems,
  );
  if (selectedItems.isEmpty) {
    return row.amountLabel;
  }

  final availableAmount = cookingFlowAvailableInventoryAmount(
    selectedItems: selectedItems,
    requirement: requirement,
  );
  return cookingFlowFormatInventoryRequirementAmount(
    amount: availableAmount,
    unitCode: requirement.unitCode,
  );
}

/// Returns usage preview labels for assigned row.
CookingFlowInventoryUsagePreview? cookingFlowInventoryUsagePreview({
  required String amountLabel,
  required CookingFlowInventoryRowAction? selectedAction,
  required List<CookingFlowInventoryAssignmentSelection> selectedSelections,
  required List<InventoryItem> inventoryItems,
  String? localeCode,
}) {
  if (selectedAction != CookingFlowInventoryRowAction.assigned) {
    return null;
  }
  final requirement = cookingFlowParseInventoryRequirement(
    amountLabel,
    localeCode: localeCode,
  );
  if (requirement == null) {
    return null;
  }
  final selectedItems = cookingFlowResolveSelectedInventoryItems(
    selectedSelections: _countedSelections(selectedSelections),
    inventoryItems: inventoryItems,
  );
  if (selectedItems.isEmpty ||
      !cookingFlowHasInventoryAmountCompatibleSelection(
        selectedItems: selectedItems,
        requirement: requirement,
      )) {
    return null;
  }

  final availableAmount = cookingFlowAvailableInventoryAmount(
    selectedItems: selectedItems,
    requirement: requirement,
  );
  final usedAmount = availableAmount < requirement.amount
      ? availableAmount
      : requirement.amount;
  final remainingAmount = availableAmount - usedAmount;
  return CookingFlowInventoryUsagePreview(
    usedAmountLabel: cookingFlowFormatInventoryRequirementAmount(
      amount: usedAmount,
      unitCode: requirement.unitCode,
    ),
    remainingAmountLabel: cookingFlowFormatInventoryRequirementAmount(
      amount: remainingAmount,
      unitCode: requirement.unitCode,
    ),
  );
}

/// Resolves row conflict for selected inventory.
CookingFlowInventoryCheckConflict? cookingFlowInventoryConflictForRow({
  required CookingFlowInventoryCheckRowData row,
  required List<CookingFlowInventoryAssignmentSelection> selectedSelections,
  required List<InventoryItem> inventoryItems,
  String? localeCode,
}) {
  final requiredAmount = cookingFlowParseInventoryRequirement(
    row.amountLabel,
    localeCode: localeCode,
  );
  if (requiredAmount == null) {
    return null;
  }

  final selectedItems = cookingFlowResolveSelectedInventoryItems(
    selectedSelections: _countedSelections(selectedSelections),
    inventoryItems: inventoryItems,
  );
  if (selectedItems.isEmpty) {
    return null;
  }

  final selectedUnitCode = cookingFlowSelectedUnitConflictCode(
    selectedItems: selectedItems,
    requirement: requiredAmount,
  );
  if (selectedUnitCode != null) {
    return CookingFlowInventoryCheckConflict.unitConversion(
      requiredUnitCode: requiredAmount.unitCode,
      selectedUnitCode: selectedUnitCode,
    );
  }

  final availableAmount = cookingFlowAvailableInventoryAmount(
    selectedItems: selectedItems,
    requirement: requiredAmount,
  );
  if (availableAmount >= requiredAmount.amount) {
    return null;
  }

  return CookingFlowInventoryCheckConflict(
    availableAmountLabel: cookingFlowFormatInventoryRequirementAmount(
      amount: availableAmount,
      unitCode: requiredAmount.unitCode,
    ),
    missingAmountLabel: cookingFlowFormatInventoryRequirementAmount(
      amount: requiredAmount.amount - availableAmount,
      unitCode: requiredAmount.unitCode,
    ),
  );
}

/// Returns incompatible selected unit code, if present.
String? cookingFlowSelectedUnitConflictCode({
  required List<InventoryItem> selectedItems,
  required CookingFlowInventoryRequirement requirement,
}) {
  if (requirement.unitCode != cookingFlowPieceUnitCode) {
    return null;
  }
  for (final item in selectedItems) {
    if (!item.usesAmountProgress || item.amountUnit == null) {
      continue;
    }
    final unitCode = item.amountUnit!.code;
    if (unitCode != cookingFlowPieceUnitCode) {
      return unitCode;
    }
  }
  return null;
}

/// Parses amount label into normalized inventory requirement.
CookingFlowInventoryRequirement? cookingFlowParseInventoryRequirement(
  String value, {
  String? localeCode,
}) {
  final trimmed = cookingFlowStripInventoryPackageCountPrefix(value);
  if (trimmed.isEmpty) {
    return null;
  }
  final parserLocale = CookingFlowParserLocale.forLocaleCode(localeCode);

  final match = RegExp(
    r'^([\d.,\s/]+)(?:\s*([a-zA-ZäöüÄÖÜß]+))?$',
  ).firstMatch(trimmed);
  if (match == null) {
    return null;
  }

  final rawAmount = parseCookingFlowQuantity(match.group(1)!);
  if (rawAmount == null) {
    return null;
  }

  final rawUnit = match.group(2)?.trim().toLowerCase();
  if (parserLocale.isPieceUnit(rawUnit)) {
    return CookingFlowInventoryRequirement(
      amount: rawAmount,
      unitCode: cookingFlowPieceUnitCode,
    );
  }
  return switch (rawUnit) {
    null || '' => CookingFlowInventoryRequirement(
      amount: rawAmount,
      unitCode: cookingFlowPieceUnitCode,
    ),
    'g' => CookingFlowInventoryRequirement(
      amount: rawAmount,
      unitCode: 'g',
    ),
    'kg' => CookingFlowInventoryRequirement(
      amount: rawAmount * 1000,
      unitCode: 'g',
    ),
    'mg' => CookingFlowInventoryRequirement(
      amount: rawAmount / 1000,
      unitCode: 'g',
    ),
    'ml' => CookingFlowInventoryRequirement(
      amount: rawAmount,
      unitCode: 'ml',
    ),
    'cl' => CookingFlowInventoryRequirement(
      amount: rawAmount * 10,
      unitCode: 'ml',
    ),
    'dl' => CookingFlowInventoryRequirement(
      amount: rawAmount * 100,
      unitCode: 'ml',
    ),
    'l' => CookingFlowInventoryRequirement(
      amount: rawAmount * 1000,
      unitCode: 'ml',
    ),
    _ => null,
  };
}

/// Returns available selected inventory amount in requirement unit.
double cookingFlowAvailableInventoryAmount({
  required List<InventoryItem> selectedItems,
  required CookingFlowInventoryRequirement requirement,
}) {
  var total = 0.0;
  for (final item in selectedItems) {
    if (requirement.unitCode == cookingFlowPieceUnitCode) {
      if (item.usesAmountProgress && item.amountUnit?.code == 'pc') {
        total += item.currentAmount;
        continue;
      }
      total += item.quantity;
      continue;
    }

    if (!item.usesAmountProgress ||
        item.amountUnit?.code != requirement.unitCode) {
      continue;
    }
    total += item.currentAmount;
  }
  return total;
}

/// Whether selected inventory can cover or compare with requirement unit.
bool cookingFlowHasInventoryAmountCompatibleSelection({
  required List<InventoryItem> selectedItems,
  required CookingFlowInventoryRequirement requirement,
}) {
  for (final item in selectedItems) {
    if (requirement.unitCode == cookingFlowPieceUnitCode) {
      return true;
    }
    if (item.usesAmountProgress &&
        item.amountUnit?.code == requirement.unitCode) {
      return true;
    }
  }
  return false;
}

/// Formats inventory requirement amount.
String cookingFlowFormatInventoryRequirementAmount({
  required double amount,
  required String unitCode,
}) {
  if (unitCode == cookingFlowPieceUnitCode) {
    return formatCookingFlowDecimal(amount);
  }
  return '${formatCookingFlowDecimal(amount)}$unitCode';
}

List<CookingFlowInventoryAssignmentSelection> _countedSelections(
  List<CookingFlowInventoryAssignmentSelection> selections,
) {
  return selections
      .where((selection) => !selection.isAdditionalIngredient)
      .toList(growable: false);
}
