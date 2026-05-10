import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/product_search/domain/manual_product_search_value_utils.dart';

/// Parsed manual product weight input ready for inventory persistence.
typedef ManualProductResolvedWeightInput = ({
  String amount,
  InventoryAmountUnit unit,
  String? normalizedWeight,
  InventoryAmountParseResult? parsedAmount,
});

/// Resolve package-weight text into UI amount/unit fields and persistence data.
ManualProductResolvedWeightInput resolveManualProductWeightInput(
  String? rawWeight, {
  InventoryAmountUnit? fallbackUnit,
}) {
  const parser = InventoryAmountParser();
  final parsed = parser.tryParse(
    rawWeight: rawWeight,
    quantity: 1,
    fallbackUnit: fallbackUnit,
  );
  if (parsed != null) {
    final amount = formatInventoryAmountValue(
      amount: parsed.amount,
      unit: parsed.unit,
      scale: parsed.scale,
    );
    return (
      amount: amount,
      unit: parsed.unit,
      normalizedWeight: '$amount ${parsed.unit.code}',
      parsedAmount: parsed,
    );
  }

  final normalized = normalizeManualProductText(rawWeight ?? '');
  final amountMatch = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(normalized ?? '');
  final amount = amountMatch?.group(0)?.replaceAll(',', '.') ?? '';
  final unit =
      _unitFromRawWeight(normalized) ??
      fallbackUnit ??
      InventoryAmountUnit.gram;
  final parsedAmount = _parseWeightAmount(amount: amount, unit: unit);
  return (
    amount: amount,
    unit: unit,
    normalizedWeight: amount.isEmpty ? null : '$amount ${unit.code}',
    parsedAmount: parsedAmount,
  );
}

/// Resolve OCR quantity text into weight input, ignoring text with no amount.
ManualProductResolvedWeightInput? resolveManualProductOcrWeightInput(
  String? rawWeight, {
  required InventoryAmountUnit fallbackUnit,
}) {
  final weight = normalizeManualProductText(rawWeight ?? '');
  if (weight == null) {
    return null;
  }
  final resolved = resolveManualProductWeightInput(
    weight,
    fallbackUnit: fallbackUnit,
  );
  if (resolved.amount.isEmpty) {
    return null;
  }
  return resolved;
}

InventoryAmountParseResult? _parseWeightAmount({
  required String amount,
  required InventoryAmountUnit unit,
}) {
  if (amount.isEmpty) {
    return null;
  }

  final scale = unit == InventoryAmountUnit.piece
      ? inventoryPieceAmountScale
      : 1;
  final parsedAmount = parseInventoryAmountInput(
    rawValue: amount,
    unit: unit,
    scale: scale,
  );
  if (parsedAmount == null) {
    return null;
  }
  return InventoryAmountParseResult(
    amount: parsedAmount,
    unit: unit,
    scale: scale,
  );
}

InventoryAmountUnit? _unitFromRawWeight(String? rawWeight) {
  final normalized = rawWeight?.toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.contains('ml') || RegExp(r'(^|\s)l\b').hasMatch(normalized)) {
    return InventoryAmountUnit.milliliter;
  }
  if (normalized.contains('stk') ||
      normalized.contains('stück') ||
      normalized.contains('st ') ||
      normalized.endsWith(' st') ||
      normalized.contains('pc') ||
      normalized.contains('piece')) {
    return InventoryAmountUnit.piece;
  }
  if (normalized.contains('g')) {
    return InventoryAmountUnit.gram;
  }
  return null;
}
