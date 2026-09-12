import 'package:meta/meta.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

export 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart'
    show cookingFlowPieceUnitCode;

/// Normalized inventory requirement with amount and unit.
@immutable
class CookingFlowInventoryRequirement {
  /// Creates an inventory requirement.
  const CookingFlowInventoryRequirement({
    required this.amount,
    required this.unitCode,
  });

  /// Required amount or quantity.
  final num amount;

  /// Unit code (e.g. 'g', 'ml', 'pc').
  final String unitCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CookingFlowInventoryRequirement &&
            other.amount == amount &&
            other.unitCode == unitCode;
  }

  @override
  int get hashCode => Object.hash(amount, unitCode);

  @override
  String toString() =>
      'CookingFlowInventoryRequirement($amount, unitCode: "$unitCode")';
}

/// Strips package count multipliers like '1x ' from requirement strings.
String cookingFlowStripInventoryPackageCountPrefix(String value) {
  final trimmed = value.trim();
  final match = RegExp(
    r'^\d+(?:[.,]\d+)?\s*x\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  return match?.group(1)?.trim() ?? trimmed;
}

/// Parses an amount label into a normalized [CookingFlowInventoryRequirement].
CookingFlowInventoryRequirement? cookingFlowParseInventoryRequirement(
  String value, {
  String? localeCode,
  CookingFlowParserLocale? parserLocale,
}) {
  final trimmed = cookingFlowStripInventoryPackageCountPrefix(value);
  if (trimmed.isEmpty) {
    return null;
  }
  final effectiveParserLocale =
      parserLocale ?? CookingFlowParserLocale.forLocaleCode(localeCode);

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
  if (effectiveParserLocale.isPieceUnit(rawUnit)) {
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

/// Formats an inventory requirement amount with its unit code.
String cookingFlowFormatInventoryRequirementAmount({
  required num amount,
  required String unitCode,
  String pieceUnitLabel = '',
}) {
  final displayAmount = formatCookingFlowDecimal(amount.toDouble());
  if (unitCode == cookingFlowPieceUnitCode) {
    if (pieceUnitLabel.isNotEmpty) {
      return '$displayAmount $pieceUnitLabel';
    }
    return displayAmount;
  }
  return '$displayAmount$unitCode';
}
