import 'package:intl/intl.dart';
import 'package:recipe_scraper/recipe_scraper.dart';

/// Formats scraped recipe data into strings shown in the app.
class PreparedMealRecipeImportFormatter {
  const PreparedMealRecipeImportFormatter();

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

  String formatQuantity(num value, {String? localeName}) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    final formatter = NumberFormat.decimalPattern(
      localeName ?? Intl.getCurrentLocale(),
    )..turnOffGrouping();
    return formatter.format(value);
  }

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
