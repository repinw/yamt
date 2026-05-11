import 'package:yamt/core/utils/flexible_decimal_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines template ingredient requirement.
class TemplateIngredientRequirement {
  /// The template ingredient requirement.
  const TemplateIngredientRequirement({
    required this.amount,
    required this.unit,
    required this.name,
    this.countMeasureLabel,
    this.packageCountLabel,
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

  /// Package count display label, for example `1x`.
  final String? packageCountLabel;

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
      r'^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,\s]\d+)*)\s*(.+)$',
    ).firstMatch(trimmed);
    if (match == null) {
      return _parseEmbeddedAmountRequirement(
        ingredient: trimmed,
        selectedPortions: selectedPortions,
        basePortions: basePortions,
      );
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
    final packageCountLabel = _packageCountLabel(
      quantity: parsedQuantity,
      selectedPortions: selectedPortions,
      basePortions: basePortions,
    );
    final embeddedRequirement = _parseEmbeddedAmountRequirement(
      ingredient: trimmed,
      selectedPortions: selectedPortions,
      basePortions: basePortions,
      packageCountLabel: packageCountLabel,
    );
    if (conversion == null) {
      return embeddedRequirement;
    }
    if (embeddedRequirement != null &&
        _shouldPreferEmbeddedAmount(rawTail, conversion)) {
      return embeddedRequirement;
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
      packageCountLabel: requirement.packageCountLabel,
    );
  }

  /// Format pending ingredient.
  String formatPendingIngredient({
    required int amount,
    required InventoryAmountUnit unit,
    required String name,
    String? countMeasureLabel,
    String? packageCountLabel,
  }) {
    final packageLabel = packageCountLabel?.trim();
    final amountLabel = countMeasureLabel?.trim();
    final unitLabel = unit == InventoryAmountUnit.piece ? '' : unit.code;
    if (packageLabel?.isNotEmpty == true && unitLabel.isNotEmpty) {
      return '$packageLabel $amount$unitLabel $name';
    }
    final resolvedAmountLabel = amountLabel?.isNotEmpty == true
        ? amountLabel
        : unit.code;
    return '$amount $resolvedAmountLabel $name';
  }

  double? _parseQuantity(String rawValue) {
    final normalized = rawValue.trim();
    final mixedFractionMatch = RegExp(
      r'^(\d+)\s+(\d+)/(\d+)$',
    ).firstMatch(normalized);
    if (mixedFractionMatch != null) {
      final whole = _parseNumber(mixedFractionMatch.group(1)!);
      final numerator = _parseNumber(mixedFractionMatch.group(2)!);
      final denominator = _parseNumber(mixedFractionMatch.group(3)!);
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

      final numerator = _parseNumber(parts[0]);
      final denominator = _parseNumber(parts[1]);
      if (numerator == null || denominator == null || denominator == 0) {
        return null;
      }
      return numerator / denominator;
    }

    return _parseNumber(normalized);
  }

  double? _parseNumber(String value) {
    return parseFlexibleDecimal(value);
  }

  _TemplateIngredientUnitConversion? _resolveUnitConversion(String rawTail) {
    final tokens = rawTail.split(RegExp(r'\s+'));
    final rawToken = tokens.isEmpty ? null : tokens.first.trim();
    final normalizedToken = tokens.isEmpty
        ? null
        : _normalizeToken(tokens.first);

    if (normalizedToken != null) {
      if (_isPackageSizePrefixToken(
        rawToken: rawToken,
        normalizedToken: normalizedToken,
      )) {
        return const _TemplateIngredientUnitConversion(
          unit: InventoryAmountUnit.piece,
          multiplier: 1,
          consumesUnitToken: false,
        );
      }
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

  TemplateIngredientRequirement? _parseEmbeddedAmountRequirement({
    required String ingredient,
    required int selectedPortions,
    required int basePortions,
    String? packageCountLabel,
  }) {
    final match = RegExp(
      r'(?:ca\.?|circa|approx\.?)?\s*'
      r'(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?)\s*'
      '(kg|kgs|kilogramm|kilogram|g|gr|gramm|gram|mg|ml|cl|dl|l|liter)'
      '(?![a-zA-ZäöüÄÖÜß.])',
      caseSensitive: false,
    ).firstMatch(ingredient);
    if (match == null) {
      return null;
    }

    final rawQuantity = match.group(1);
    final rawUnit = match.group(2);
    if (rawQuantity == null || rawUnit == null) {
      return null;
    }

    final parsedQuantity = _parseQuantity(rawQuantity);
    final conversion = _unitConversions[_normalizeToken(rawUnit)];
    if (parsedQuantity == null ||
        parsedQuantity <= 0 ||
        conversion == null ||
        conversion.unit == InventoryAmountUnit.piece) {
      return null;
    }

    final scaledQuantity =
        parsedQuantity *
        conversion.multiplier *
        selectedPortions /
        basePortions;
    final roundedAmount = scaledQuantity.round();
    if (roundedAmount < 1) {
      return null;
    }

    final name = _cleanEmbeddedAmountIngredientName(
      ingredient: ingredient,
      amountMatch: match,
    );
    return TemplateIngredientRequirement(
      amount: roundedAmount,
      unit: conversion.unit,
      name: name.isEmpty ? ingredient.trim() : name,
      packageCountLabel: packageCountLabel,
    );
  }

  String _cleanEmbeddedAmountIngredientName({
    required String ingredient,
    required RegExpMatch amountMatch,
  }) {
    final withoutAmount = _removeEmbeddedAmountText(
      ingredient: ingredient,
      amountMatch: amountMatch,
    );
    final tokens = withoutAmount.trim().split(RegExp(r'\s+')).toList();
    while (tokens.isNotEmpty) {
      final token = _normalizeToken(tokens.first);
      if (!_isEmbeddedAmountIngredientPrefixToken(token) &&
          !_isQuantityPrefixToken(tokens.first)) {
        break;
      }
      tokens.removeAt(0);
    }
    return tokens.join(' ').trim();
  }

  bool _shouldPreferEmbeddedAmount(
    String rawTail,
    _TemplateIngredientUnitConversion conversion,
  ) {
    if (conversion.unit != InventoryAmountUnit.piece) {
      return false;
    }
    final tokens = rawTail.split(RegExp(r'\s+'));
    final firstToken = tokens.isEmpty ? '' : _normalizeToken(tokens.first);
    return _isEmbeddedAmountIngredientPrefixToken(firstToken) ||
        conversion.countMeasureLabel != null ||
        !conversion.consumesUnitToken;
  }

  bool _isEmbeddedAmountIngredientPrefixToken(String token) {
    return _embeddedAmountIngredientPrefixTokens.contains(token);
  }

  bool _isPackageSizePrefixToken({
    required String? rawToken,
    required String normalizedToken,
  }) {
    final hasAbbreviationDot = rawToken?.contains('.') == true;
    return hasAbbreviationDot &&
        _packageSizePrefixTokens.contains(normalizedToken);
  }

  bool _isQuantityPrefixToken(String token) {
    return RegExp(
      r'^(\d+(?:[.,]\d+)?|\d+/\d+)$',
    ).hasMatch(token.trim());
  }

  String _packageCountLabel({
    required double quantity,
    required int selectedPortions,
    required int basePortions,
  }) {
    final scaledQuantity = quantity * selectedPortions / basePortions;
    return '${_formatQuantityLabel(scaledQuantity)}x';
  }

  String _formatQuantityLabel(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _removeEmbeddedAmountText({
    required String ingredient,
    required RegExpMatch amountMatch,
  }) {
    final openParen = ingredient.lastIndexOf('(', amountMatch.start);
    final closeParen = ingredient.indexOf(')', amountMatch.end);
    if (openParen >= 0 && closeParen >= amountMatch.end) {
      return [
        ingredient.substring(0, openParen),
        ingredient.substring(closeParen + 1),
      ].join(' ').trim();
    }
    return [
      ingredient.substring(0, amountMatch.start),
      ingredient.substring(amountMatch.end),
    ].join(' ').trim();
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

const _embeddedAmountIngredientPrefixTokens = <String>{
  'becher',
  'dose',
  'dosen',
  'glas',
  'glaeser',
  'gläser',
  'gr',
  'gross',
  'grosse',
  'grossen',
  'groß',
  'große',
  'großen',
  'kl',
  'klein',
  'kleine',
  'kleinen',
  'm',
  'mgross',
  'mgrosse',
  'mgroß',
  'mgroße',
  'mittel',
  'mittelgross',
  'mittelgrosse',
  'mittelgroß',
  'mittelgroße',
  'packung',
  'packungen',
  'stk',
  'stueck',
  'stück',
};

const _packageSizePrefixTokens = <String>{
  'gr',
  'gross',
  'grosse',
  'groß',
  'große',
  'kl',
  'klein',
  'kleine',
};
