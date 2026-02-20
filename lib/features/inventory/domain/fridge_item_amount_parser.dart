import 'package:freezed_annotation/freezed_annotation.dart';

enum FridgeAmountUnit {
  @JsonValue('g')
  gram,
  @JsonValue('ml')
  milliliter,
  @JsonValue('pc')
  piece,
}

extension FridgeAmountUnitCode on FridgeAmountUnit {
  String get code {
    return switch (this) {
      FridgeAmountUnit.gram => 'g',
      FridgeAmountUnit.milliliter => 'ml',
      FridgeAmountUnit.piece => 'pc',
    };
  }
}

class FridgeAmountParseResult {
  const FridgeAmountParseResult({required this.amount, required this.unit});

  final int amount;
  final FridgeAmountUnit unit;
}

class FridgeItemAmountParser {
  const FridgeItemAmountParser();

  static final RegExp _packPattern = RegExp(r'^(\d+)[x\u00D7](.+)$');
  static final RegExp _valueWithUnitPattern = RegExp(
    r'^(\d+(?:[.,]\d+)?)([a-zA-Z]+)?$',
  );
  static final Map<String, ({FridgeAmountUnit base, double multiplier})>
  _unitAliases = <String, ({FridgeAmountUnit base, double multiplier})>{
    'g': (base: FridgeAmountUnit.gram, multiplier: 1.0),
    'gr': (base: FridgeAmountUnit.gram, multiplier: 1.0),
    'gram': (base: FridgeAmountUnit.gram, multiplier: 1.0),
    'grams': (base: FridgeAmountUnit.gram, multiplier: 1.0),
    'kg': (base: FridgeAmountUnit.gram, multiplier: 1000.0),
    'kilogram': (base: FridgeAmountUnit.gram, multiplier: 1000.0),
    'kilograms': (base: FridgeAmountUnit.gram, multiplier: 1000.0),
    'mg': (base: FridgeAmountUnit.gram, multiplier: 0.001),
    'ml': (base: FridgeAmountUnit.milliliter, multiplier: 1.0),
    'cl': (base: FridgeAmountUnit.milliliter, multiplier: 10.0),
    'dl': (base: FridgeAmountUnit.milliliter, multiplier: 100.0),
    'l': (base: FridgeAmountUnit.milliliter, multiplier: 1000.0),
    'liter': (base: FridgeAmountUnit.milliliter, multiplier: 1000.0),
    'liters': (base: FridgeAmountUnit.milliliter, multiplier: 1000.0),
    'litre': (base: FridgeAmountUnit.milliliter, multiplier: 1000.0),
    'litres': (base: FridgeAmountUnit.milliliter, multiplier: 1000.0),
    'pc': (base: FridgeAmountUnit.piece, multiplier: 1.0),
    'piece': (base: FridgeAmountUnit.piece, multiplier: 1.0),
    'pieces': (base: FridgeAmountUnit.piece, multiplier: 1.0),
    'st': (base: FridgeAmountUnit.piece, multiplier: 1.0),
    'stk': (base: FridgeAmountUnit.piece, multiplier: 1.0),
  };

  FridgeAmountParseResult? tryParse({
    required String? rawWeight,
    required int quantity,
    FridgeAmountUnit? fallbackUnit,
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

    return FridgeAmountParseResult(
      amount: convertedAmount.round(),
      unit: conversion.base,
    );
  }

  ({FridgeAmountUnit base, double multiplier})? _resolveConversion({
    required String? rawUnit,
    required FridgeAmountUnit? fallbackUnit,
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
