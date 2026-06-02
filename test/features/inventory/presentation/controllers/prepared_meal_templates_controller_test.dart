import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';

class _FakePreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  _FakePreparedMealTemplateRepository({
    required List<PreparedMeal> initialTemplates,
  }) : _templates = List<PreparedMeal>.from(initialTemplates);

  final StreamController<List<PreparedMeal>> _controller =
      StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> _templates;
  List<PreparedMeal> savedTemplates = const <PreparedMeal>[];
  int watchInvocationCount = 0;

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.multi((controller) {
      watchInvocationCount += 1;
      controller.add(List<PreparedMeal>.from(_templates));
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    return List<PreparedMeal>.from(_templates);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> templates) async {
    _templates = List<PreparedMeal>.from(templates);
    savedTemplates = List<PreparedMeal>.from(templates);
    _controller.add(List<PreparedMeal>.from(_templates));
    return true;
  }

  void emitWatchError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  Future<void> dispose() => _controller.close();
}

class _SilentPreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  _SilentPreparedMealTemplateRepository({
    required List<PreparedMeal> initialTemplates,
  }) : _templates = List<PreparedMeal>.from(initialTemplates);

  List<PreparedMeal> _templates;
  List<PreparedMeal> savedTemplates = const <PreparedMeal>[];

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return const Stream<List<PreparedMeal>>.empty();
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    return List<PreparedMeal>.from(_templates);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> templates) async {
    _templates = List<PreparedMeal>.from(templates);
    savedTemplates = List<PreparedMeal>.from(templates);
    return true;
  }
}

class _FakePreparedMealRecipeImporter extends PreparedMealRecipeImporter {
  const _FakePreparedMealRecipeImporter(this.recipe);

  final PreparedMealRecipeImport? recipe;

  @override
  Future<PreparedMealRecipeImport?> importRecipe(
    String recipeUrl, {
    String? localeName,
  }) async {
    return recipe;
  }
}

Future<void> _waitForCondition(
  bool Function() condition, {
  Duration timeout = const Duration(milliseconds: 200),
}) async {
  final stopwatch = Stopwatch()..start();
  while (!condition()) {
    if (stopwatch.elapsed >= timeout) {
      fail('Condition not reached within $timeout.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

PreparedMeal _templateMeal({required String id, required String name}) {
  final sourceItem = InventoryItem.create(
    id: 'rice',
    name: 'Rice',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 300,
    currentAmount: 300,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 200,
      per100Protein: 10,
      per100Carbs: 20,
      per100Fat: 5,
    ),
  );

  return PreparedMeal(
    id: id,
    name: name,
    imageAssetId: 'asset-$id',
    totalPortions: 4,
    remainingPortions: 2,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 10,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: [
      PreparedMealComponent(
        inventoryItemId: sourceItem.id,
        name: sourceItem.name,
        brand: sourceItem.brand,
        imageUrl: sourceItem.imageUrl,
        usedAmount: 200,
        usedUnit: InventoryAmountUnit.gram,
        totalKcal: 400,
        totalProtein: 20,
        totalCarbs: 40,
        totalFat: 10,
        sourceItemSnapshot: sourceItem,
      ),
    ],
  );
}

PreparedMeal _recipeTemplate({required String id, required String name}) {
  return PreparedMeal(
    id: id,
    name: name,
    imageUrl: 'https://example.com/$id.jpg',
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 640,
    totalProtein: 30,
    totalCarbs: 80,
    totalFat: 18,
    createdAt: DateTime.parse('2026-04-02T12:00:00Z'),
    updatedAt: DateTime.parse('2026-04-02T12:00:00Z'),
    components: const <PreparedMealComponent>[],
    recipeIngredients: const <String>[
      '200 g pasta',
      '150 g tomatoes',
    ],
    recipeInstructions: const <String>[
      'Cook pasta.',
      'Toss with tomatoes.',
    ],
  );
}

ProviderSubscription<AsyncValue<List<PreparedMeal>>> _keepControllerAlive(
  ProviderContainer container,
) {
  return container.listen(
    preparedMealTemplatesControllerProvider,
    (previous, next) {},
  );
}

void main() {
  test('stale repository errors are ignored after repository swap', () async {
    var usesSharedRepository = true;
    final sharedRepository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _templateMeal(id: 'shared-template', name: 'Shared Template'),
      ],
    );
    final personalRepository = _FakePreparedMealTemplateRepository(
      initialTemplates: const <PreparedMeal>[],
    );
    addTearDown(sharedRepository.dispose);
    addTearDown(personalRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWith((ref) {
          if (usesSharedRepository) {
            return sharedRepository;
          }
          return personalRepository;
        }),
        preparedMealRecipeImporterProvider.overrideWithValue(
          const _FakePreparedMealRecipeImporter(null),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealTemplatesControllerProvider.future);
    usesSharedRepository = false;
    container.invalidate(preparedMealTemplateRepositoryProvider);

    final reloadedTemplates = await container.read(
      preparedMealTemplatesControllerProvider.future,
    );
    expect(reloadedTemplates, isEmpty);

    sharedRepository.emitWatchError(StateError('stale permission denied'));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    final stateAfterStaleError = container.read(
      preparedMealTemplatesControllerProvider,
    );
    expect(stateAfterStaleError.hasError, isFalse);
    expect(stateAfterStaleError.asData?.value, isEmpty);
  });

  test('saveTemplateFromMeal stores a normalized meal template', () async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: const <PreparedMeal>[],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
        preparedMealRecipeImporterProvider.overrideWithValue(
          const _FakePreparedMealRecipeImporter(null),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealTemplatesControllerProvider.future);
    final saved = await container
        .read(preparedMealTemplatesControllerProvider.notifier)
        .saveTemplateFromMeal(_templateMeal(id: 'meal-1', name: 'Lunch Box'));

    expect(saved.isSuccess, isTrue);
    expect(saved.templateId, isNotNull);
    expect(repository.savedTemplates, hasLength(1));
    expect(repository.savedTemplates.single.name, 'Lunch Box');
    expect(repository.savedTemplates.single.imageAssetId, 'asset-meal-1');
    expect(repository.savedTemplates.single.remainingPortions, 4);
    expect(repository.savedTemplates.single.id, isNot('meal-1'));
  });

  test('saveRecipeTemplate stores recipe-only generated template', () async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: const <PreparedMeal>[],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
        preparedMealRecipeImporterProvider.overrideWithValue(
          const _FakePreparedMealRecipeImporter(null),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    final recipe = _recipeTemplate(id: 'generated-1', name: 'Tomato Pasta');

    await container.read(preparedMealTemplatesControllerProvider.future);
    final saved = await container
        .read(preparedMealTemplatesControllerProvider.notifier)
        .saveRecipeTemplate(recipe);

    expect(saved.isSuccess, isTrue);
    expect(repository.savedTemplates, hasLength(1));
    expect(repository.savedTemplates.single.id, isNot('generated-1'));
    expect(repository.savedTemplates.single.name, 'Tomato Pasta');
    expect(repository.savedTemplates.single.imageUrl, recipe.imageUrl);
    expect(repository.savedTemplates.single.components, isEmpty);
    expect(
      repository.savedTemplates.single.recipeIngredients,
      recipe.recipeIngredients,
    );
    expect(
      repository.savedTemplates.single.recipeInstructions,
      recipe.recipeInstructions,
    );
    expect(repository.savedTemplates.single.totalKcal, recipe.totalKcal);
  });

  test('deleteTemplate removes the selected template', () async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _templateMeal(id: 'template-1', name: 'Lunch Box'),
      ],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
        preparedMealRecipeImporterProvider.overrideWithValue(
          const _FakePreparedMealRecipeImporter(null),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealTemplatesControllerProvider.future);
    final deleted = await container
        .read(preparedMealTemplatesControllerProvider.notifier)
        .deleteTemplate('template-1');

    expect(deleted, isTrue);
    expect(repository.savedTemplates, isEmpty);
  });

  test('saveTemplateFromMeal works before the template watch emits', () async {
    final repository = _SilentPreparedMealTemplateRepository(
      initialTemplates: const <PreparedMeal>[],
    );

    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
        preparedMealRecipeImporterProvider.overrideWithValue(
          const _FakePreparedMealRecipeImporter(null),
        ),
      ],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(preparedMealTemplatesControllerProvider.notifier)
        .saveTemplateFromMeal(_templateMeal(id: 'meal-1', name: 'Lunch Box'))
        .timeout(const Duration(milliseconds: 200));

    expect(saved.isSuccess, isTrue);
    expect(repository.savedTemplates, hasLength(1));
    expect(repository.savedTemplates.single.name, 'Lunch Box');
  });

  test(
    'createTemplateFromRecipe stores normalized recipe template data',
    () async {
      final repository = _FakePreparedMealTemplateRepository(
        initialTemplates: const <PreparedMeal>[],
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
          preparedMealRecipeImporterProvider.overrideWithValue(
            const _FakePreparedMealRecipeImporter(
              PreparedMealRecipeImport(
                recipeUrl: 'https://chefkoch.de/rezepte/1234/spaghetti.html',
                title: 'Spaghetti mit Pesto',
                servings: 4,
                ingredients: <String>['500 g Spaghetti', '2 EL Pesto'],
                instructions: <String>[
                  'Spaghetti kochen.',
                  'Pesto unterheben.',
                ],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealTemplatesControllerProvider.future);
      final saved = await container
          .read(preparedMealTemplatesControllerProvider.notifier)
          .createTemplateFromRecipe(
            recipeUrl: 'chefkoch.de/rezepte/1234/spaghetti-mit-pesto.html',
          );

      expect(saved.isSuccess, isTrue);
      expect(repository.savedTemplates, hasLength(1));
      expect(
        repository.savedTemplates.single.recipeUrl,
        'https://chefkoch.de/rezepte/1234/spaghetti.html',
      );
      expect(repository.savedTemplates.single.name, 'Spaghetti mit Pesto');
      expect(repository.savedTemplates.single.totalPortions, 4);
      expect(repository.savedTemplates.single.recipeIngredients, <String>[
        '500 g Spaghetti',
        '2 EL Pesto',
      ]);
      expect(repository.savedTemplates.single.recipeInstructions, <String>[
        'Spaghetti kochen.',
        'Pesto unterheben.',
      ]);
      expect(repository.savedTemplates.single.components, isEmpty);
    },
  );

  test('createTemplateFromRecipe rejects invalid input', () async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: const <PreparedMeal>[],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
        preparedMealRecipeImporterProvider.overrideWithValue(
          const _FakePreparedMealRecipeImporter(null),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealTemplatesControllerProvider.future);
    final saved = await container
        .read(preparedMealTemplatesControllerProvider.notifier)
        .createTemplateFromRecipe(recipeUrl: 'notaurl');

    expect(saved.isSuccess, isFalse);
    expect(
      saved.failureReason,
      PreparedMealTemplateSaveFailureReason.invalidInput,
    );
    expect(repository.savedTemplates, isEmpty);
  });

  test('createTemplateFromRecipe reports import failures separately', () async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: const <PreparedMeal>[],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
        preparedMealRecipeImporterProvider.overrideWithValue(
          const _FakePreparedMealRecipeImporter(null),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealTemplatesControllerProvider.future);
    final saved = await container
        .read(preparedMealTemplatesControllerProvider.notifier)
        .createTemplateFromRecipe(
          recipeUrl: 'https://chefkoch.de/rezepte/1234/spaghetti.html',
        );

    expect(saved.isSuccess, isFalse);
    expect(
      saved.failureReason,
      PreparedMealTemplateSaveFailureReason.recipeLoadFailed,
    );
  });

  test('updateRecipeTemplate updates recipe-backed templates', () async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _templateMeal(id: 'template-1', name: 'Old Name').copyWith(
          recipeUrl: 'https://chefkoch.de/rezepte/old.html',
          recipeIngredients: const <String>['1 old ingredient'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
        preparedMealRecipeImporterProvider.overrideWithValue(
          const _FakePreparedMealRecipeImporter(
            PreparedMealRecipeImport(
              recipeUrl: 'https://chefkoch.de/rezepte/new.html',
              title: 'Imported Recipe',
              servings: 6,
              ingredients: <String>['2 carrots', '1 onion'],
              instructions: <String>[
                'Karotten schneiden.',
                'Mit Zwiebeln kochen.',
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealTemplatesControllerProvider.future);
    final result = await container
        .read(preparedMealTemplatesControllerProvider.notifier)
        .updateRecipeTemplate(
          templateId: 'template-1',
          recipeUrl: 'chefkoch.de/rezepte/new.html',
          name: 'Edited Name',
          totalPortions: 2,
        );

    expect(result.isSuccess, isTrue);
    expect(repository.savedTemplates, hasLength(1));
    expect(repository.savedTemplates.single.name, 'Edited Name');
    expect(
      repository.savedTemplates.single.recipeUrl,
      'https://chefkoch.de/rezepte/new.html',
    );
    expect(repository.savedTemplates.single.recipeIngredients, <String>[
      '2 carrots',
      '1 onion',
    ]);
    expect(repository.savedTemplates.single.recipeInstructions, <String>[
      'Karotten schneiden.',
      'Mit Zwiebeln kochen.',
    ]);
    expect(repository.savedTemplates.single.totalPortions, 2);
    expect(repository.savedTemplates.single.remainingPortions, 2);
  });

  test('existing recipe templates backfill missing instructions', () async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _templateMeal(id: 'template-1', name: 'Soup').copyWith(
          recipeUrl: 'https://chefkoch.de/rezepte/soup.html',
          recipeIngredients: const <String>['1 L Brühe'],
          recipeInstructions: const <String>[],
        ),
      ],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
        preparedMealRecipeImporterProvider.overrideWithValue(
          const _FakePreparedMealRecipeImporter(
            PreparedMealRecipeImport(
              recipeUrl: 'https://chefkoch.de/rezepte/soup.html',
              title: 'Soup',
              servings: 4,
              ingredients: <String>['1 L Brühe'],
              instructions: <String>[
                'Brühe erhitzen.',
                'Suppe ziehen lassen.',
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    final templates = await container.read(
      preparedMealTemplatesControllerProvider.future,
    );

    expect(templates.single.recipeInstructions, isEmpty);

    await _waitForCondition(() => repository.savedTemplates.isNotEmpty);

    expect(repository.savedTemplates.single.recipeInstructions, <String>[
      'Brühe erhitzen.',
      'Suppe ziehen lassen.',
    ]);
    expect(
      repository.savedTemplates.single.updatedAt,
      DateTime.parse('2026-03-27T12:00:00Z'),
    );
  });
}
