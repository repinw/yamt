import 'package:freezed_annotation/freezed_annotation.dart';

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
  const InventoryAmountParseResult({required this.amount, required this.unit});

  /// The amount.
  final int amount;

  /// The unit.
  final InventoryAmountUnit unit;
}

/// Defines inventory amount parser.
class InventoryAmountParser {
  /// The inventory amount parser.
  const InventoryAmountParser();

  static final RegExp _packPattern = RegExp(r'^(\d+)[x\u00D7](.+)$');
  static final RegExp _valueWithUnitPattern = RegExp(
    r'^(\d+(?:[.,]\d+)?)([a-zA-Z]+)?$',
  );
  static final Map<String, ({InventoryAmountUnit base, double multiplier})>
  _unitAliases = <String, ({InventoryAmountUnit base, double multiplier})>{
    'g': (base: InventoryAmountUnit.gram, multiplier: 1.0),
    'gr': (base: InventoryAmountUnit.gram, multiplier: 1.0),
    'gram': (base: InventoryAmountUnit.gram, multiplier: 1.0),
    'grams': (base: InventoryAmountUnit.gram, multiplier: 1.0),
    'kg': (base: InventoryAmountUnit.gram, multiplier: 1000.0),
    'kilogram': (base: InventoryAmountUnit.gram, multiplier: 1000.0),
    'kilograms': (base: InventoryAmountUnit.gram, multiplier: 1000.0),
    'mg': (base: InventoryAmountUnit.gram, multiplier: 0.001),
    'ml': (base: InventoryAmountUnit.milliliter, multiplier: 1.0),
    'cl': (base: InventoryAmountUnit.milliliter, multiplier: 10.0),
    'dl': (base: InventoryAmountUnit.milliliter, multiplier: 100.0),
    'l': (base: InventoryAmountUnit.milliliter, multiplier: 1000.0),
    'liter': (base: InventoryAmountUnit.milliliter, multiplier: 1000.0),
    'liters': (base: InventoryAmountUnit.milliliter, multiplier: 1000.0),
    'litre': (base: InventoryAmountUnit.milliliter, multiplier: 1000.0),
    'litres': (base: InventoryAmountUnit.milliliter, multiplier: 1000.0),
    'pc': (base: InventoryAmountUnit.piece, multiplier: 1.0),
    'pcs': (base: InventoryAmountUnit.piece, multiplier: 1.0),
    'piece': (base: InventoryAmountUnit.piece, multiplier: 1.0),
    'pieces': (base: InventoryAmountUnit.piece, multiplier: 1.0),
    'st': (base: InventoryAmountUnit.piece, multiplier: 1.0),
    'stk': (base: InventoryAmountUnit.piece, multiplier: 1.0),
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
    final convertedAmount = totalAmount * conversion.multiplier;
    if (!convertedAmount.isFinite || convertedAmount < 0) {
      return null;
    }

    return InventoryAmountParseResult(
      amount: convertedAmount.round(),
      unit: conversion.base,
    );
  }

  ({InventoryAmountUnit base, double multiplier})? _resolveConversion({
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
    return (base: fallbackUnit, multiplier: 1.0);
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
