import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// The template ingredient parser provider.
final templateIngredientParserProvider = Provider<TemplateIngredientParser>((
  ref,
) {
  return const TemplateIngredientParser();
});

/// Defines template ingredient requirement.
class TemplateIngredientRequirement {
  /// The template ingredient requirement.
  const TemplateIngredientRequirement({
    required this.amount,
    required this.unit,
    required this.name,
    this.countMeasureLabel,
    this.allowsDirectPieceInventoryMatch = true,
  });

  /// The amount.
  final int amount;

  /// The unit.
  final InventoryAmountUnit unit;

  /// The name.
  final String name;

  /// The count measure label.
  final String? countMeasureLabel;

  /// Whether direct piece inventory match.
  final bool allowsDirectPieceInventoryMatch;
}

/// Defines template ingredient parser.
class TemplateIngredientParser {
  /// The template ingredient parser.
  const TemplateIngredientParser();

  /// Parse requirement.
  TemplateIngredientRequirement? parseRequirement({
    required String ingredient,
    required int selectedPortions,
    required int basePortions,
  }) {
    if (selectedPortions < 1 || basePortions < 1) {
      return null;
    }

    final trimmed = ingredient.trim();
    final match = RegExp(
      r'^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?)\s*(.+)$',
    ).firstMatch(trimmed);
    if (match == null) {
      return null;
    }

    final rawQuantity = match.group(1);
    final rawTail = match.group(2);
    if (rawQuantity == null || rawTail == null) {
      return null;
    }

    final parsedQuantity = _parseQuantity(rawQuantity);
    if (parsedQuantity == null || parsedQuantity <= 0) {
      return null;
    }

    final conversion = _resolveUnitConversion(rawTail);
    if (conversion == null) {
      return null;
    }

    final ingredientName = conversion.consumesUnitToken
        ? rawTail.split(RegExp(r'\s+')).skip(1).join(' ').trim()
        : rawTail.trim();
    final scaledQuantity =
        parsedQuantity *
        conversion.multiplier *
        selectedPortions /
        basePortions;
    final roundedAmount = scaledQuantity.round();
    if (roundedAmount < 1) {
      return null;
    }

    return TemplateIngredientRequirement(
      amount: roundedAmount,
      unit: conversion.unit,
      name: ingredientName.isEmpty ? rawTail.trim() : ingredientName,
      countMeasureLabel: conversion.countMeasureLabel,
      allowsDirectPieceInventoryMatch:
          conversion.allowsDirectPieceInventoryMatch,
    );
  }

  /// Pending ingredient label.
  String pendingIngredientLabel({
    required String originalIngredient,
    required TemplateIngredientRequirement? requirement,
  }) {
    if (requirement == null) {
      return originalIngredient.trim();
    }
    return formatPendingIngredient(
      amount: requirement.amount,
      unit: requirement.unit,
      name: requirement.name,
      countMeasureLabel: requirement.countMeasureLabel,
    );
  }

  /// Format pending ingredient.
  String formatPendingIngredient({
    required int amount,
    required InventoryAmountUnit unit,
    required String name,
    String? countMeasureLabel,
  }) {
    final amountLabel = countMeasureLabel?.trim();
    return '$amount ${amountLabel?.isNotEmpty == true ? amountLabel : unit.code} '
        '$name';
  }

  double? _parseQuantity(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    final mixedFractionMatch = RegExp(
      r'^(\d+)\s+(\d+)/(\d+)$',
    ).firstMatch(normalized);
    if (mixedFractionMatch != null) {
      final whole = double.tryParse(mixedFractionMatch.group(1)!);
      final numerator = double.tryParse(mixedFractionMatch.group(2)!);
      final denominator = double.tryParse(mixedFractionMatch.group(3)!);
      if (whole == null ||
          numerator == null ||
          denominator == null ||
          denominator == 0) {
        return null;
      }
      return whole + (numerator / denominator);
    }

    if (normalized.contains('/')) {
      final parts = normalized.split('/');
      if (parts.length != 2) {
        return null;
      }

      final numerator = double.tryParse(parts[0]);
      final denominator = double.tryParse(parts[1]);
      if (numerator == null || denominator == null || denominator == 0) {
        return null;
      }
      return numerator / denominator;
    }

    return double.tryParse(normalized);
  }

  _TemplateIngredientUnitConversion? _resolveUnitConversion(String rawTail) {
    final tokens = rawTail.split(RegExp(r'\s+'));
    final rawToken = tokens.isEmpty ? null : tokens.first.trim();
    final normalizedToken = tokens.isEmpty
        ? null
        : _normalizeToken(tokens.first);

    if (normalizedToken != null) {
      final mappedConversion = _unitConversions[normalizedToken];
      final conversion = mappedConversion == null
          ? null
          : mappedConversion.unit == InventoryAmountUnit.piece
          ? mappedConversion.copyWith(countMeasureLabel: rawToken)
          : mappedConversion;
      if (conversion != null) {
        return conversion;
      }
      if (_unsupportedMeasureTokens.contains(normalizedToken)) {
        return null;
      }
    }

    return const _TemplateIngredientUnitConversion(
      unit: InventoryAmountUnit.piece,
      multiplier: 1,
      consumesUnitToken: false,
    );
  }

  String _normalizeToken(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp('[^a-z0-9äöüß]+'), '');
  }
}

class _TemplateIngredientUnitConversion {
  const _TemplateIngredientUnitConversion({
    required this.unit,
    required this.multiplier,
    required this.consumesUnitToken,
    this.countMeasureLabel,
    this.allowsDirectPieceInventoryMatch = true,
  });

  final InventoryAmountUnit unit;
  final double multiplier;
  final bool consumesUnitToken;
  final String? countMeasureLabel;
  final bool allowsDirectPieceInventoryMatch;

  _TemplateIngredientUnitConversion copyWith({String? countMeasureLabel}) {
    return _TemplateIngredientUnitConversion(
      unit: unit,
      multiplier: multiplier,
      consumesUnitToken: consumesUnitToken,
      countMeasureLabel: countMeasureLabel ?? this.countMeasureLabel,
      allowsDirectPieceInventoryMatch: allowsDirectPieceInventoryMatch,
    );
  }
}

const _unitConversions = <String, _TemplateIngredientUnitConversion>{
  'g': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.gram,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'gr': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.gram,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'gramm': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.gram,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'gram': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.gram,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'grams': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.gram,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'kg': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.gram,
    multiplier: 1000,
    consumesUnitToken: true,
  ),
  'kgs': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.gram,
    multiplier: 1000,
    consumesUnitToken: true,
  ),
  'kilogramm': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.gram,
    multiplier: 1000,
    consumesUnitToken: true,
  ),
  'kilogram': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.gram,
    multiplier: 1000,
    consumesUnitToken: true,
  ),
  'kilograms': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.gram,
    multiplier: 1000,
    consumesUnitToken: true,
  ),
  'ml': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'milliliter': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'milliliters': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'millilitre': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'millilitres': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'cl': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 10,
    consumesUnitToken: true,
  ),
  'dl': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 100,
    consumesUnitToken: true,
  ),
  'l': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 1000,
    consumesUnitToken: true,
  ),
  'liter': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 1000,
    consumesUnitToken: true,
  ),
  'liters': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 1000,
    consumesUnitToken: true,
  ),
  'litre': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 1000,
    consumesUnitToken: true,
  ),
  'litres': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.milliliter,
    multiplier: 1000,
    consumesUnitToken: true,
  ),
  'pc': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'piece': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'pieces': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'stk': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'stuck': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'stueck': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'stück': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'stücke': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
  ),
  'el': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
    allowsDirectPieceInventoryMatch: false,
  ),
  'essloeffel': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
    allowsDirectPieceInventoryMatch: false,
  ),
  'esslöffel': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
    allowsDirectPieceInventoryMatch: false,
  ),
  'tbsp': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
    allowsDirectPieceInventoryMatch: false,
  ),
  'tl': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
    allowsDirectPieceInventoryMatch: false,
  ),
  'teeloeffel': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
    allowsDirectPieceInventoryMatch: false,
  ),
  'teelöffel': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
    allowsDirectPieceInventoryMatch: false,
  ),
  'teaspoon': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
    allowsDirectPieceInventoryMatch: false,
  ),
  'teaspoons': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
    allowsDirectPieceInventoryMatch: false,
  ),
  'tsp': _TemplateIngredientUnitConversion(
    unit: InventoryAmountUnit.piece,
    multiplier: 1,
    consumesUnitToken: true,
    allowsDirectPieceInventoryMatch: false,
  ),
};

const _unsupportedMeasureTokens = <String>{
  'cup',
  'cups',
  'lb',
  'lbs',
  'ounce',
  'ounces',
  'oz',
  'pinch',
  'pinches',
  'pound',
  'pounds',
  'prise',
  'prisen',
};
