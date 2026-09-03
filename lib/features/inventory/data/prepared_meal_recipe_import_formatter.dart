import 'package:intl/intl.dart';

const List<String> _units = [
  'tsp',
  'tbsp',
  'oz',
  'cup',
  'pint',
  'quart',
  'gal',
  'gallon',
  'lb',
  'kg',
  'g',
  'mg',
  'cl',
  'dl',
  'ml',
  'l',
  'EL',
  'TL',
  'Prise',
  'Prisen',
  'Bund',
  'Bunde',
  'Dose',
  'Dosen',
  'Pck.',
  'Packung',
  'Packungen',
  'Msp.',
  'Zehe',
  'Zehen',
  'Scheibe',
  'Scheiben',
  'Stk.',
  'Stück',
  'Glas',
  'Gläser',
  'Zweig',
  'Zweige',
];

final String _unitsPattern = '(?:${_units.join('|')})';

/// Represents a parsed recipe ingredient.
class Ingredient {
  /// Creates an ingredient representation.
  const Ingredient({
    required this.name,
    required this.quantity,
    this.unit,
  });

  /// Parses an ingredient string into an [Ingredient].
  factory Ingredient.fromIngredientString(String ingredientString) {
    return _calculateIngredient(ingredientString);
  }

  /// The name of the ingredient.
  final String name;

  /// The numeric quantity.
  final num quantity;

  /// The unit of measurement (optional).
  final String? unit;
}

Ingredient _calculateIngredient(String rawIngredientString) {
  var ingredientString = _replaceFractions(rawIngredientString.trim());
  if (ingredientString.isEmpty) {
    return const Ingredient(name: '', quantity: 1);
  }

  final ingredientParts = ingredientString.split(RegExp(r'\s+'));
  if (ingredientParts.isEmpty) {
    return const Ingredient(name: '', quantity: 1);
  }

  // Handle cases like "100g" -> "100 g"
  for (final unit in _units) {
    if (ingredientParts[0].toLowerCase().endsWith(unit.toLowerCase())) {
      final prefix = ingredientParts[0].substring(
        0,
        ingredientParts[0].length - unit.length,
      );
      final amount = double.tryParse(prefix.replaceAll(',', '.'));
      if (amount != null) {
        ingredientParts[0] = amount.toString();
        ingredientParts.insert(1, unit);
        ingredientString = ingredientParts.join(' ');
        break;
      }
    }
  }

  final amountMatch =
      RegExp(r'^\d+([.,]\d+)?').stringMatch(ingredientParts.first);
  final amount = amountMatch != null
      ? double.tryParse(amountMatch.replaceAll(',', '.'))
      : null;

  final unitMatch = RegExp(
    r'\b(?<=\s)(?<unit>' + _unitsPattern + r')(?![^$ _])\b',
    caseSensitive: false,
  ).stringMatch(ingredientString);

  final nameParts = amount != null && ingredientParts.isNotEmpty
      ? ingredientParts.sublist(1)
      : ingredientParts;

  var name = nameParts.join(' ');
  if (unitMatch != null && unitMatch.isNotEmpty) {
    name = name.replaceFirst(
      RegExp(r'\b' + RegExp.escape(unitMatch) + r'\b'),
      '',
    );
  }
  name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

  return Ingredient(
    name: name,
    quantity: amount ?? 1,
    unit: unitMatch,
  );
}

String _replaceFractions(String ingredientString) {
  const fractions = {
    '½': '0.5',
    '¼': '0.25',
    '¾': '0.75',
    '⅓': '0.33',
    '⅔': '0.66',
    '⅛': '0.125',
    '⅜': '0.375',
    '⅝': '0.625',
    '⅞': '0.875',
  };

  var result = ingredientString;
  for (final entry in fractions.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

/// Formats scraped recipe data into strings shown in the app.
class PreparedMealRecipeImportFormatter {
  /// The prepared meal recipe import formatter.
  const PreparedMealRecipeImportFormatter();

  /// Format ingredient line.
  String formatIngredientLine(Ingredient ingredient, {String? localeName}) {
    final parts = <String>[];
    final quantity = formatQuantity(
      ingredient.quantity,
      localeName: localeName,
    );
    if (quantity.isNotEmpty) {
      parts.add(quantity);
    }
    final unit = ingredient.unit?.trim();
    if (unit != null && unit.isNotEmpty) {
      parts.add(unit);
    }
    final name = ingredient.name.trim();
    if (name.isNotEmpty) {
      parts.add(name);
    }
    return parts.join(' ').trim();
  }

  /// Format quantity.
  String formatQuantity(num value, {String? localeName}) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    final formatter = NumberFormat.decimalPattern(
      localeName ?? Intl.getCurrentLocale(),
    )..turnOffGrouping();
    return formatter.format(value);
  }

  /// Normalize recipe image url.
  String? normalizeRecipeImageUrl(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return null;
  }
}
