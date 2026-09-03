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

  test('importRecipe parses image defined as a Map with contentUrl', () async {
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
        'name': 'Curry',
        'image': <String, Object?>{
          '@type': 'ImageObject',
          'contentUrl': 'https://example.test/curry.jpg',
        },
        'recipeYield': '4 Portionen',
        'recipeIngredient': <String>['400 g Tofu'],
        'recipeInstructions': <String>['Cook curry'],
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
      'http://${server.address.host}:${server.port}/curry',
    );

    expect(result, isNotNull);
    expect(result!.imageUrl, 'https://example.test/curry.jpg');
    expect(result.title, 'Curry');
    expect(result.servings, 4);
    expect(result.ingredients, <String>['400 g Tofu']);
    expect(result.instructions, <String>['Cook curry']);
  });

  test(
    'importRecipe resolves @id image reference in Yoast SEO @graph',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      StreamSubscription<HttpRequest>? subscription;
      addTearDown(() async {
        await subscription?.cancel();
        await server.close(force: true);
      });

      subscription = server.listen((request) {
        final graphJson = jsonEncode(<String, Object?>{
          '@context': 'https://schema.org',
          '@graph': <Object>[
            <String, Object?>{
              '@type': 'ImageObject',
              '@id': 'https://example.test/pizza/#primaryimage',
              'url': 'https://example.test/pizza.jpg',
              'contentUrl': 'https://example.test/pizza.jpg',
            },
            <String, Object?>{
              '@type': 'Recipe',
              '@id': 'https://example.test/pizza/#recipe',
              'name': 'Pizza Margherita',
              'image': <String, Object?>{
                '@id': 'https://example.test/pizza/#primaryimage',
              },
              'recipeYield': 2,
              'recipeIngredient': <String>['300 g Mehl', '150 g Mozzarella'],
              'recipeInstructions': <Object>[
                <String, String>{'@type': 'HowToStep', 'text': 'Bake pizza'},
              ],
            },
          ],
        });

        request.response.headers.contentType = ContentType.html;
        request.response.write('''
<!doctype html>
<html>
  <head>
    <script type="application/ld+json">$graphJson</script>
  </head>
  <body>Recipe</body>
</html>
''');
        unawaited(request.response.close());
      });

      final result = await const PreparedMealRecipeImporter().importRecipe(
        'http://${server.address.host}:${server.port}/pizza',
      );

      expect(result, isNotNull);
      expect(result!.imageUrl, 'https://example.test/pizza.jpg');
      expect(result.title, 'Pizza Margherita');
      expect(result.servings, 2);
    },
  );

  test(
    'importRecipe handles empty image map gracefully with null imageUrl',
    () async {
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
          'name': 'Salad',
          'image': <String, Object?>{},
          'recipeYield': 1,
          'recipeIngredient': <String>['100 g Salat'],
          'recipeInstructions': <String>['Mix salad'],
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
        'http://${server.address.host}:${server.port}/salad',
      );

      expect(result, isNotNull);
      expect(result!.imageUrl, isNull);
      expect(result.title, 'Salad');
    },
  );

  test(
    'importRecipe parses aspect ratio map and HowToSection instructions',
    () async {
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
          'name': 'Burger',
          'image': <String, Object?>{
            '16x9': 'https://example.test/burger-16x9.jpg',
            '4x3': 'https://example.test/burger-4x3.jpg',
          },
          'recipeYield': 'Für 3 Personen',
          'recipeIngredient': <String>['3 Patties', '3 Buns'],
          'recipeInstructions': <Object>[
            <String, Object?>{
              '@type': 'HowToSection',
              'name': 'Zubereitung',
              'itemListElement': <Object>[
                <String, String>{
                  '@type': 'HowToStep',
                  'text': 'Patties grillen',
                },
                <String, String>{'@type': 'HowToStep', 'text': 'Buns belegen'},
              ],
            },
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
        'http://${server.address.host}:${server.port}/burger',
      );

      expect(result, isNotNull);
      expect(result!.imageUrl, 'https://example.test/burger-16x9.jpg');
      expect(result.servings, 3);
      expect(result.instructions, <String>[
        'Patties grillen',
        'Buns belegen',
      ]);
    },
  );

  test('importRecipe returns null gracefully on 404 or invalid url', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    StreamSubscription<HttpRequest>? subscription;
    addTearDown(() async {
      await subscription?.cancel();
      await server.close(force: true);
    });

    subscription = server.listen((request) {
      request.response.statusCode = HttpStatus.notFound;
      unawaited(request.response.close());
    });

    final notFoundResult =
        await const PreparedMealRecipeImporter().importRecipe(
      'http://${server.address.host}:${server.port}/missing',
    );
    expect(notFoundResult, isNull);

    final invalidResult = await const PreparedMealRecipeImporter().importRecipe(
      'not-a-valid-url',
    );
    expect(invalidResult, isNull);
  });
}
