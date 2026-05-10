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
  final rawAmount = amountMatch != null
      ? amountMatch.group(0)!.replaceAll(',', '.')
      : '';
  final conversion = _conversionFromRawWeight(normalized);
  final unit = conversion?.unit ?? fallbackUnit ?? InventoryAmountUnit.gram;
  final amount = _convertFallbackAmount(
    rawAmount: rawAmount,
    multiplier: conversion?.multiplier ?? 1,
  );
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

({InventoryAmountUnit unit, double multiplier})? _conversionFromRawWeight(
  String? rawWeight,
) {
  final normalized = rawWeight?.toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.contains('ml')) {
    return (unit: InventoryAmountUnit.milliliter, multiplier: 1);
  }
  if (RegExp(r'(^|\s|\d)l\b').hasMatch(normalized)) {
    return (unit: InventoryAmountUnit.milliliter, multiplier: 1000);
  }
  if (normalized.contains('stk') ||
      normalized.contains('stück') ||
      normalized.contains('st ') ||
      normalized.endsWith(' st') ||
      normalized.contains('pc') ||
      normalized.contains('piece')) {
    return (unit: InventoryAmountUnit.piece, multiplier: 1);
  }
  if (normalized.contains('kg')) {
    return (unit: InventoryAmountUnit.gram, multiplier: 1000);
  }
  if (normalized.contains('g')) {
    return (unit: InventoryAmountUnit.gram, multiplier: 1);
  }
  return null;
}

String _convertFallbackAmount({
  required String rawAmount,
  required double multiplier,
}) {
  if (rawAmount.isEmpty) {
    return '';
  }
  final parsed = double.tryParse(rawAmount);
  if (parsed == null || !parsed.isFinite || parsed <= 0) {
    return rawAmount;
  }
  return formatManualProductDouble(parsed * multiplier);
}
