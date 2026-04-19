import 'package:freezed_annotation/freezed_annotation.dart';

/// Internal storage scale for fractional piece amounts.
const inventoryPieceAmountScale = 1000;

/// Defines inventory amount unit.
enum InventoryAmountUnit {
  /// Creates an instance.
  @JsonValue('g')
  gram,

  /// Creates an instance.
  @JsonValue('ml')
  milliliter,

  /// Documented member.
  @JsonValue('pc')
  piece,
}

/// Defines inventory amount unit code extension.
extension InventoryAmountUnitCode on InventoryAmountUnit {
  /// The code.
  String get code {
    return switch (this) {
      InventoryAmountUnit.gram => 'g',
      InventoryAmountUnit.milliliter => 'ml',
      InventoryAmountUnit.piece => 'pc',
    };
  }
}

/// Defines inventory amount parse result.
class InventoryAmountParseResult {
  /// The inventory amount parse result.
  const InventoryAmountParseResult({
    required this.amount,
    required this.unit,
    this.scale = 1,
  });

  /// The amount.
  final int amount;

  /// The unit.
  final InventoryAmountUnit unit;

  /// Internal amount scale.
  final int scale;
}

/// Whether amount input may use fractional values.
bool inventoryAmountAllowsFractionalInput({
  required InventoryAmountUnit unit,
  int scale = 1,
}) {
  return unit == InventoryAmountUnit.piece && scale > 1;
}

/// Converts stored inventory amount to display value.
double inventoryAmountToDisplayValue({
  required int amount,
  required InventoryAmountUnit unit,
  int scale = 1,
}) {
  final safeAmount = amount < 0 ? 0 : amount;
  final safeScale = scale < 1 ? 1 : scale;
  if (!inventoryAmountAllowsFractionalInput(unit: unit, scale: safeScale)) {
    return safeAmount.toDouble();
  }
  return safeAmount / safeScale;
}

/// Formats stored inventory amount for text fields and labels.
String formatInventoryAmountValue({
  required int amount,
  required InventoryAmountUnit unit,
  int scale = 1,
}) {
  final displayValue = inventoryAmountToDisplayValue(
    amount: amount,
    unit: unit,
    scale: scale,
  );
  final roundedValue = displayValue.roundToDouble();
  if ((displayValue - roundedValue).abs() < 0.000001) {
    return roundedValue.toInt().toString();
  }
  return displayValue.toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Parses user-entered inventory amount text into stored amount units.
int? parseInventoryAmountInput({
  required String rawValue,
  required InventoryAmountUnit unit,
  int scale = 1,
}) {
  final normalized = rawValue.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }

  if (!inventoryAmountAllowsFractionalInput(unit: unit, scale: scale)) {
    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed < 1) {
      return null;
    }
    return parsed;
  }

  final parsed = double.tryParse(normalized);
  if (parsed == null || !parsed.isFinite || parsed <= 0) {
    return null;
  }

  final safeScale = scale < 1 ? 1 : scale;
  final scaledAmount = (parsed * safeScale).round();
  if (scaledAmount < 1) {
    return null;
  }
  return scaledAmount;
}

/// Defines inventory amount parser.
class InventoryAmountParser {
  /// The inventory amount parser.
  const InventoryAmountParser();

  static final RegExp _packPattern = RegExp(r'^(\d+)[x\u00D7](.+)$');
  static final RegExp _valueWithUnitPattern = RegExp(
    r'^(\d+(?:[.,]\d+)?)([a-zA-Z]+)?$',
  );
  static final Map<
    String,
    ({InventoryAmountUnit base, double multiplier, int scale})
  >
  _unitAliases =
      <String, ({InventoryAmountUnit base, double multiplier, int scale})>{
        'g': (
          base: InventoryAmountUnit.gram,
          multiplier: 1.0,
          scale: 1,
        ),
        'gr': (
          base: InventoryAmountUnit.gram,
          multiplier: 1.0,
          scale: 1,
        ),
        'gram': (
          base: InventoryAmountUnit.gram,
          multiplier: 1.0,
          scale: 1,
        ),
        'grams': (
          base: InventoryAmountUnit.gram,
          multiplier: 1.0,
          scale: 1,
        ),
        'kg': (
          base: InventoryAmountUnit.gram,
          multiplier: 1000.0,
          scale: 1,
        ),
        'kilogram': (
          base: InventoryAmountUnit.gram,
          multiplier: 1000.0,
          scale: 1,
        ),
        'kilograms': (
          base: InventoryAmountUnit.gram,
          multiplier: 1000.0,
          scale: 1,
        ),
        'mg': (
          base: InventoryAmountUnit.gram,
          multiplier: 0.001,
          scale: 1,
        ),
        'ml': (
          base: InventoryAmountUnit.milliliter,
          multiplier: 1.0,
          scale: 1,
        ),
        'cl': (
          base: InventoryAmountUnit.milliliter,
          multiplier: 10.0,
          scale: 1,
        ),
        'dl': (
          base: InventoryAmountUnit.milliliter,
          multiplier: 100.0,
          scale: 1,
        ),
        'l': (
          base: InventoryAmountUnit.milliliter,
          multiplier: 1000.0,
          scale: 1,
        ),
        'liter': (
          base: InventoryAmountUnit.milliliter,
          multiplier: 1000.0,
          scale: 1,
        ),
        'liters': (
          base: InventoryAmountUnit.milliliter,
          multiplier: 1000.0,
          scale: 1,
        ),
        'litre': (
          base: InventoryAmountUnit.milliliter,
          multiplier: 1000.0,
          scale: 1,
        ),
        'litres': (
          base: InventoryAmountUnit.milliliter,
          multiplier: 1000.0,
          scale: 1,
        ),
        'pc': (
          base: InventoryAmountUnit.piece,
          multiplier: 1.0,
          scale: inventoryPieceAmountScale,
        ),
        'pcs': (
          base: InventoryAmountUnit.piece,
          multiplier: 1.0,
          scale: inventoryPieceAmountScale,
        ),
        'piece': (
          base: InventoryAmountUnit.piece,
          multiplier: 1.0,
          scale: inventoryPieceAmountScale,
        ),
        'pieces': (
          base: InventoryAmountUnit.piece,
          multiplier: 1.0,
          scale: inventoryPieceAmountScale,
        ),
        'st': (
          base: InventoryAmountUnit.piece,
          multiplier: 1.0,
          scale: inventoryPieceAmountScale,
        ),
        'stk': (
          base: InventoryAmountUnit.piece,
          multiplier: 1.0,
          scale: inventoryPieceAmountScale,
        ),
      };

  /// Try parse.
  InventoryAmountParseResult? tryParse({
    required String? rawWeight,
    required int quantity,
    InventoryAmountUnit? fallbackUnit,
  }) {
    final normalized = _normalizeWeight(rawWeight);
    if (normalized == null) {
      return null;
    }

    final compact = normalized.toLowerCase().replaceAll(' ', '');
    final packData = _packPattern.firstMatch(compact);
    final multiplier = packData == null ? 1 : int.parse(packData.group(1)!);
    final valueAndUnit = packData == null ? compact : packData.group(2)!;

    final match = _valueWithUnitPattern.firstMatch(valueAndUnit);
    if (match == null) {
      return null;
    }

    final rawValue = match.group(1)!.replaceAll(',', '.');
    final value = double.tryParse(rawValue);
    if (value == null || !value.isFinite || value <= 0) {
      return null;
    }

    final conversion = _resolveConversion(
      rawUnit: match.group(2),
      fallbackUnit: fallbackUnit,
    );
    if (conversion == null) {
      return null;
    }

    final safeQuantity = quantity < 1 ? 0 : quantity;
    final totalAmount = value * multiplier * safeQuantity;
    final convertedAmount =
        totalAmount * conversion.multiplier * conversion.scale;
    if (!convertedAmount.isFinite || convertedAmount < 0) {
      return null;
    }

    return InventoryAmountParseResult(
      amount: convertedAmount.round(),
      unit: conversion.base,
      scale: conversion.scale,
    );
  }

  ({InventoryAmountUnit base, double multiplier, int scale})?
  _resolveConversion({
    required String? rawUnit,
    required InventoryAmountUnit? fallbackUnit,
  }) {
    final normalizedUnit = _normalizeUnit(rawUnit);
    if (normalizedUnit != null) {
      final mapped = _unitAliases[normalizedUnit];
      if (mapped != null) {
        return mapped;
      }
    }
    if (fallbackUnit == null) {
      return null;
    }
    return (
      base: fallbackUnit,
      multiplier: 1.0,
      scale: fallbackUnit == InventoryAmountUnit.piece
          ? inventoryPieceAmountScale
          : 1,
    );
  }

  String? _normalizeWeight(String? rawWeight) {
    final trimmed = rawWeight?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? _normalizeUnit(String? rawUnit) {
    final trimmed = rawUnit?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
