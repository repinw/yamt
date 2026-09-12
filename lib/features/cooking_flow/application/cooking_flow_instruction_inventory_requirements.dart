import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_requirement.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Parsed inventory requirement for cooking flow inventory tracking.
typedef CookingInventoryRequirement = CookingFlowInventoryRequirement;

/// Aggregates amount and unit from selected inventory items.
({String label, String unitCode})? selectedCookingInventoryAmount({
  required List<InventoryItem> selectedItems,
  required String pieceUnitLabel,
}) {
  InventoryAmountUnit? sharedUnit;
  var sharedScale = 1;
  var totalAmount = 0;

  for (final item in selectedItems) {
    final itemUnit = item.amountUnit;
    if (!item.usesAmountProgress || itemUnit == null) {
      if (sharedUnit != null &&
          (sharedUnit != InventoryAmountUnit.piece || sharedScale != 1)) {
        return null;
      }
      sharedUnit ??= InventoryAmountUnit.piece;
      sharedScale = 1;
      totalAmount += item.quantity;
      continue;
    }
    if (sharedUnit == null) {
      sharedUnit = itemUnit;
      sharedScale = item.amountScale;
    } else if (sharedUnit != itemUnit || sharedScale != item.amountScale) {
      return null;
    }
    totalAmount += item.currentAmount;
  }

  if (sharedUnit == null || totalAmount < 1) {
    return null;
  }
  final amountLabel = formatInventoryAmountValue(
    amount: totalAmount,
    unit: sharedUnit,
    scale: sharedScale,
  );
  final label = sharedUnit == InventoryAmountUnit.piece
      ? (pieceUnitLabel.isNotEmpty
            ? '$amountLabel $pieceUnitLabel'
            : amountLabel)
      : '$amountLabel${sharedUnit.code}';
  return (label: label, unitCode: sharedUnit.code);
}

/// Whether the selected inventory amount takes precedence over the requirement.
bool shouldUseSelectedCookingAmount({
  required CookingInventoryRequirement? requirement,
  required ({String label, String unitCode}) selectedAmount,
}) {
  if (requirement == null) {
    return true;
  }
  return requirement.unitCode == cookingFlowParserPieceUnitCode &&
      selectedAmount.unitCode != cookingFlowParserPieceUnitCode;
}

/// Parses an amount and unit string into a [CookingInventoryRequirement].
CookingInventoryRequirement? parseCookingInventoryRequirement(
  String value,
  CookingFlowParserLocale parserLocale,
) {
  return cookingFlowParseInventoryRequirement(
    value,
    parserLocale: parserLocale,
  );
}

/// Calculates total available quantity or amount for [requirement].
int availableCookingInventoryAmount({
  required List<InventoryItem> selectedItems,
  required CookingInventoryRequirement requirement,
}) {
  return cookingFlowAvailableInventoryAmount(
    selectedItems: selectedItems,
    requirement: requirement,
  ).round();
}

/// Formats inventory requirement amount with its unit code.
String formatCookingInventoryRequirementAmount({
  required int amount,
  required String unitCode,
  required String pieceUnitLabel,
}) {
  return cookingFlowFormatInventoryRequirementAmount(
    amount: amount,
    unitCode: unitCode,
    pieceUnitLabel: pieceUnitLabel,
  );
}
