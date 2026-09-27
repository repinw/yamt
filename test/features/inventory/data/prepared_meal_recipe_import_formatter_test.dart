import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_recipe_import_formatter.dart';

void main() {
  const formatter = PreparedMealRecipeImportFormatter();

  group('formatQuantity', () {
    late String? previousLocale;

    setUp(() {
      previousLocale = Intl.defaultLocale;
    });

    tearDown(() {
      Intl.defaultLocale = previousLocale;
    });

    test('formats decimal quantities with english separator', () {
      Intl.defaultLocale = 'en';

      expect(formatter.formatQuantity(1.5), '1.5');
    });

    test('formats decimal quantities with german separator', () {
      Intl.defaultLocale = 'de';

      expect(formatter.formatQuantity(1.5), '1,5');
    });

    test('keeps integer quantities without decimal part', () {
      expect(formatter.formatQuantity(2), '2');
    });
  });

  group('formatIngredientLine', () {
    test('builds a full ingredient line', () {
      const ingredient = Ingredient(
        name: 'Spaghetti',
        quantity: 1.5,
        unit: 'kg',
      );

      final line = formatter.formatIngredientLine(ingredient, localeName: 'en');

      expect(line, '1.5 kg Spaghetti');
    });

    test('omits missing unit and empty names', () {
      const ingredient = Ingredient(name: '  ', quantity: 2);

      expect(formatter.formatIngredientLine(ingredient), '2');
    });

    test('invents no quantity for a line with no numeric amount', () {
      const ingredient = Ingredient(
        name: 'etwas Schnittlauch (frisch oder TK)',
        quantity: null,
      );

      expect(
        formatter.formatIngredientLine(ingredient),
        'etwas Schnittlauch (frisch oder TK)',
      );
    });
  });

  group('fromIngredientString', () {
    test('parses a numeric amount, unit, and name', () {
      final ingredient = Ingredient.fromIngredientString('500 g Mehl');

      expect(ingredient.quantity, 500);
      expect(ingredient.unit, 'g');
      expect(ingredient.name, 'Mehl');
    });

    test('keeps a vague-amount line intact with no invented quantity', () {
      final ingredient = Ingredient.fromIngredientString(
        'etwas Schnittlauch (frisch oder TK)',
      );

      expect(ingredient.quantity, isNull);
      expect(ingredient.unit, isNull);
      expect(ingredient.name, 'etwas Schnittlauch (frisch oder TK)');
    });

    test('keeps a "Prise" line intact with no invented quantity', () {
      final ingredient = Ingredient.fromIngredientString('Prise Salz');

      expect(ingredient.quantity, isNull);
      expect(ingredient.name, 'Prise Salz');
    });
  });

  group('normalizeRecipeImageUrl', () {
    test('normalizes protocol-relative urls', () {
      expect(
        formatter.normalizeRecipeImageUrl('//images.example.com/meal.jpg'),
        'https://images.example.com/meal.jpg',
      );
    });

    test('keeps http and https urls', () {
      expect(
        formatter.normalizeRecipeImageUrl(
          'https://images.example.com/meal.jpg',
        ),
        'https://images.example.com/meal.jpg',
      );
      expect(
        formatter.normalizeRecipeImageUrl('http://images.example.com/meal.jpg'),
        'http://images.example.com/meal.jpg',
      );
    });

    test('rejects empty and relative values', () {
      expect(formatter.normalizeRecipeImageUrl(' '), isNull);
      expect(formatter.normalizeRecipeImageUrl('/meal.jpg'), isNull);
    });
  });
}
