import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';

import '../../../helpers/fake_firebase_storage.dart';

final _now = DateTime.utc(2026, 11, 13, 10);

const Map<String, Object?> _answer = {
  'name': 'Soup',
  'portions': 2,
  'kcal': 300,
  'protein': 10,
  'carbs': 40,
  'fat': 8,
  'ingredients': [
    {
      'text': '200 g carrots',
      'amount': 200,
      'unit': 'g',
      'kcal': 80,
      'protein': 2,
      'carbs': 16,
      'fat': 0,
    },
  ],
  'instructions': ['Boil'],
  'image_prompt': 'a soup',
};

void main() {
  FirebaseAiChefRepository repository({
    String? Function()? answer,
    Future<String?> Function()? slow,
    void Function(String templateId, Map<String, Object?> inputs)? onAsk,
  }) => FirebaseAiChefRepository(
    templateModelClient: ({required templateId, required inputs}) async {
      onAsk?.call(templateId, inputs);
      return answer != null ? answer() : jsonEncode(_answer);
    },
  );

  test('loadRecipeIdea asks recipe-idea-template with the inputs', () async {
    String? askedTemplate;
    Map<String, Object?>? askedInputs;
    final idea =
        await repository(
          onAsk: (templateId, inputs) {
            askedTemplate = templateId;
            askedInputs = inputs;
          },
        ).loadRecipeIdea(
          languageCode: 'en',
          seed: 'pasta',
          now: _now,
          inventoryIngredients: const ['Tomato', 'Milk'],
        );

    expect(askedTemplate, 'recipe-idea-template');
    expect(askedInputs, {
      'language': 'en',
      'seed': 'pasta',
      'inventory': 'Tomato\nMilk',
    });
    expect(idea.recipe.name, 'Soup');
    expect(idea.recipe.createdAt, _now);
    expect(idea.imagePrompt, 'a soup');
  });

  test(
    'loadRecipeIdea sends Bloß nicht and Unbedingt rein one per line',
    () async {
      Map<String, Object?>? askedInputs;
      await repository(onAsk: (_, inputs) => askedInputs = inputs)
          .loadRecipeIdea(
            languageCode: 'de',
            seed: 'Suppe',
            now: _now,
            excludedIngredients: const ['Koriander', 'Rosinen'],
            mustUseIngredients: const ['Spinat (available: 200 g)', 'Quark'],
          );

      expect(askedInputs?['excluded_ingredients'], 'Koriander\nRosinen');
      expect(
        askedInputs?['must_use_ingredients'],
        'Spinat (available: 200 g)\nQuark',
      );
    },
  );

  test('loadRecipeIdea throws when the template client throws', () {
    final failing = FirebaseAiChefRepository(
      templateModelClient: ({required templateId, required inputs}) async {
        throw Exception('template not found');
      },
    );

    expect(
      failing.loadRecipeIdea(languageCode: 'en', seed: 'pasta', now: _now),
      throwsException,
    );
  });

  test('loadRecipeIdea throws a FormatException for an empty answer', () {
    expect(
      repository(answer: () => null)
          .loadRecipeIdea(languageCode: 'en', seed: 'x', now: _now),
      throwsFormatException,
    );
    expect(
      repository(answer: () => '  ')
          .loadRecipeIdea(languageCode: 'en', seed: 'x', now: _now),
      throwsFormatException,
    );
  });

  test('loadRecipeIdea throws a FormatException for an unusable answer', () {
    expect(
      repository(answer: () => '{"name": "Soup"}')
          .loadRecipeIdea(languageCode: 'en', seed: 'x', now: _now),
      throwsFormatException,
    );
  });

  group('saveCover', () {
    const coverPath =
        'households/household-1/recipes/recipe-1/images/cover.jpg';

    test('uploads the bytes under the household and gives the link', () async {
      final storage = FakeFirebaseStorage();
      final repo = FirebaseAiChefRepository(
        storage: storage,
        householdId: 'household-1',
      );

      final url = await repo.saveCover(
        recipeId: 'recipe-1',
        bytes: Uint8List.fromList([1, 2]),
      );

      expect(url, 'https://example.test/$coverPath');
      expect(storage.uploads, [coverPath]);
      expect(storage.contents[coverPath], [1, 2]);
      expect(storage.contentTypes[coverPath], 'image/jpeg');
    });

    test('throws a StateError without storage', () {
      expect(
        FirebaseAiChefRepository(householdId: 'household-1')
            .saveCover(recipeId: 'recipe-1', bytes: Uint8List(1)),
        throwsStateError,
      );
    });

    test('throws a StateError without a household id', () {
      final storage = FakeFirebaseStorage();
      expect(
        FirebaseAiChefRepository(storage: storage)
            .saveCover(recipeId: 'recipe-1', bytes: Uint8List(1)),
        throwsStateError,
      );
      expect(storage.uploads, isEmpty);
    });

    test('lets an upload error through', () {
      final storage = FakeFirebaseStorage()
        ..uploadError = FirebaseException(plugin: 'storage', code: 'canceled');
      expect(
        FirebaseAiChefRepository(
          storage: storage,
          householdId: 'household-1',
        ).saveCover(recipeId: 'recipe-1', bytes: Uint8List(1)),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
