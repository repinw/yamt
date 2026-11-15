import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/meal_templates/presentation/controllers/'
    'recipe_link_read_controller.dart';

const _link = 'https://example.com/rezepte/suppe';

const _recipe = PreparedMealRecipeImport(
  recipeUrl: _link,
  title: 'Suppe',
  servings: 2,
  ingredients: ['200 g Mehl'],
  instructions: ['Kochen.'],
  instructionsPreview: ['Kochen.'],
);

/// Answers once [answer] completes; holds the asked links and locales.
class _FakeImporter extends PreparedMealRecipeImporter {
  new();

  final answer = Completer<PreparedMealRecipeImport?>();
  final asked = <(String, String?)>[];

  @override
  Future<PreparedMealRecipeImport?> importRecipe(
    String recipeUrl, {
    String? localeName,
  }) {
    asked.add((recipeUrl, localeName));
    return answer.future;
  }
}

void main() {
  late _FakeImporter importer;
  late ProviderContainer container;

  setUp(() {
    importer = _FakeImporter();
    container = ProviderContainer(
      overrides: [
        preparedMealRecipeImporterProvider.overrideWithValue(importer),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<PreparedMealRecipeImport?> read() => container
      .read(recipeLinkReadControllerProvider.notifier)
      .read(_link, localeName: 'de');

  test('gives what the page holds', () async {
    final reading = read();
    importer.answer.complete(_recipe);

    expect(await reading, same(_recipe));
    expect(importer.asked, [(_link, 'de')]);
  });

  test('gives nothing when the page has no recipe', () async {
    final reading = read();
    importer.answer.complete(null);

    expect(await reading, isNull);
  });

  test('gives nothing when the reading fails', () async {
    final reading = read();
    importer.answer.completeError(StateError('offline'));

    expect(await reading, isNull);
  });

  test('stays alive while it reads, though nobody listens', () async {
    final reading = read();
    await container.pump();
    expect(container.read(recipeLinkReadControllerProvider.exists), isTrue);

    importer.answer.complete(_recipe);
    await reading;
    await container.pump();
    expect(container.read(recipeLinkReadControllerProvider.exists), isFalse);
  });
}
