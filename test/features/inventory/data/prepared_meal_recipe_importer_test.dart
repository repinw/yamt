import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';

void main() {
  test('provider exposes a recipe importer instance', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(preparedMealRecipeImporterProvider),
      isA<PreparedMealRecipeImporter>(),
    );
  });

  test('recipe import value keeps scraped recipe data', () {
    const recipeImport = PreparedMealRecipeImport(
      recipeUrl: 'https://example.test/recipe',
      imageUrl: 'https://example.test/image.jpg',
      title: 'Pasta',
      servings: 4,
      ingredients: <String>['200 g Pasta'],
      instructions: <String>['Cook pasta', 'Serve'],
      instructionsPreview: <String>['Cook pasta'],
    );

    expect(recipeImport.recipeUrl, 'https://example.test/recipe');
    expect(recipeImport.imageUrl, 'https://example.test/image.jpg');
    expect(recipeImport.title, 'Pasta');
    expect(recipeImport.servings, 4);
    expect(recipeImport.ingredients, <String>['200 g Pasta']);
    expect(recipeImport.instructions, <String>['Cook pasta', 'Serve']);
    expect(recipeImport.instructionsPreview, <String>['Cook pasta']);
  });

  test('importRecipe scrapes JSON-LD recipe data', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    StreamSubscription<HttpRequest>? subscription;
    addTearDown(() async {
      await subscription?.cancel();
      await server.close(force: true);
    });

    subscription = server.listen((request) {
      final recipeJson = jsonEncode(<String, Object?>{
        '@context': 'https://schema.org',
        '@type': 'Recipe',
        'name': ' Pasta ',
        'description': 'Simple pasta',
        'image': '//example.test/pasta.jpg',
        'recipeYield': 4,
        'recipeIngredient': <String>[
          '200 g pasta',
          '1 tbsp olive oil',
        ],
        'recipeInstructions': <Object>[
          <String, String>{'@type': 'HowToStep', 'text': ' Boil pasta '},
          <String, String>{'@type': 'HowToStep', 'text': 'Serve'},
          <String, String>{'@type': 'HowToStep', 'text': ' '},
          <String, String>{'@type': 'HowToStep', 'text': 'Garnish'},
        ],
      });

      request.response.headers.contentType = ContentType.html;
      request.response.write('''
<!doctype html>
<html>
  <head>
    <script type="application/ld+json">$recipeJson</script>
  </head>
  <body>Recipe</body>
</html>
''');
      unawaited(request.response.close());
    });

    final result = await const PreparedMealRecipeImporter().importRecipe(
      'http://${server.address.host}:${server.port}/recipe',
      localeName: 'en',
    );

    expect(result, isNotNull);
    expect(result!.recipeUrl, startsWith('http://'));
    expect(result.imageUrl, 'https://example.test/pasta.jpg');
    expect(result.title, 'Pasta');
    expect(result.servings, 4);
    expect(result.ingredients, <String>[
      '200 g pasta',
      '1 tbsp olive oil',
    ]);
    expect(result.instructions, <String>[
      'Boil pasta',
      'Serve',
      'Garnish',
    ]);
    expect(result.instructionsPreview, <String>[
      'Boil pasta',
      'Serve',
      'Garnish',
    ]);
  });
}
