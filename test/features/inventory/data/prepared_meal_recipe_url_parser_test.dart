import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_url_parser.dart';

void main() {
  test('normalizes bare recipe urls and strips query plus fragment', () {
    final normalizedUrl = normalizePreparedMealRecipeUrl(
      'chefkoch.de/rezepte/1234/spaghetti.html?foo=1#section',
    );

    expect(normalizedUrl, 'https://chefkoch.de/rezepte/1234/spaghetti.html');
  });

  test('extracts wrapped urls from surrounding text', () {
    final normalizedUrl = normalizePreparedMealRecipeUrl(
      'Rezept hier: (<https://chefkoch.de/rezepte/1234/spaghetti.html>,)',
    );

    expect(normalizedUrl, 'https://chefkoch.de/rezepte/1234/spaghetti.html');
  });

  test('keeps explicit http urls intact', () {
    final normalizedUrl = normalizePreparedMealRecipeUrl(
      'http://www.example.com/recipes/soup',
    );

    expect(normalizedUrl, 'http://www.example.com/recipes/soup');
  });

  test('rejects invalid or unsupported urls', () {
    expect(normalizePreparedMealRecipeUrl('notaurl'), isNull);
    expect(normalizePreparedMealRecipeUrl('ftp://example.com/recipe'), isNull);
    expect(normalizePreparedMealRecipeUrl('example'), isNull);
  });
}
