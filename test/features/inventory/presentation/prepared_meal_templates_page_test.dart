import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_templates_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../support/fake_local_image_store.dart';

class _FakePreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  _FakePreparedMealTemplateRepository({
    required List<PreparedMeal> initialTemplates,
  }) : _templates = List<PreparedMeal>.from(initialTemplates);

  final StreamController<List<PreparedMeal>> _controller =
      StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> _templates;
  List<PreparedMeal> savedTemplates = const <PreparedMeal>[];

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.multi((controller) {
      controller.add(List<PreparedMeal>.from(_templates));
      final subscription = _controller.stream.listen(controller.add);
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

  Future<void> dispose() => _controller.close();
}

class _FakePreparedMealRecipeImporter extends PreparedMealRecipeImporter {
  const _FakePreparedMealRecipeImporter(this.recipe);

  final PreparedMealRecipeImport? recipe;

  @override
  Future<PreparedMealRecipeImport?> importRecipe(String recipeUrl) async {
    return recipe;
  }
}

PreparedMeal _template({required String id, required String name}) {
  final sourceItem = InventoryItem.create(
    id: 'rice',
    name: 'Rice',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
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
    remainingPortions: 4,
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
    recipeUrl: 'https://www.chefkoch.de/rezepte/$id/$name.html',
    recipeIngredients: const <String>['1 kg Kartoffeln'],
    totalPortions: 4,
    remainingPortions: 4,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: const <PreparedMealComponent>[],
  );
}

void main() {
  testWidgets('renders templates and deletes one from the list', (
    tester,
  ) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _template(id: 'template-1', name: 'Lunch Box'),
      ],
    );
    final localImageStore = FakeLocalImageStore();
    addTearDown(repository.dispose);

    await localImageStore.saveBytes(
      imageRef: localImageAssetRef('asset-template-1'),
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
          preparedMealRecipeImporterProvider.overrideWithValue(
            const _FakePreparedMealRecipeImporter(null),
          ),
          localImageStoreProvider.overrideWithValue(localImageStore),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PreparedMealTemplatesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lunch Box'), findsOneWidget);
    expect(find.text('Templates'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    await tester.tap(find.byTooltip('Delete template'));
    await tester.pumpAndSettle();

    expect(find.text('Lunch Box'), findsNothing);
    expect(repository.savedTemplates, isEmpty);
  });

  testWidgets('renders template cover image from local device store', (
    tester,
  ) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _template(id: 'template-1', name: 'Lunch Box'),
      ],
    );
    final localImageStore = FakeLocalImageStore();
    addTearDown(repository.dispose);

    await localImageStore.saveBytes(
      imageRef: localImageAssetRef('asset-template-1'),
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
          preparedMealRecipeImporterProvider.overrideWithValue(
            const _FakePreparedMealRecipeImporter(null),
          ),
          localImageStoreProvider.overrideWithValue(localImageStore),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PreparedMealTemplatesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageWidget = tester.widget<Image>(find.byType(Image).first);
    expect(imageWidget.image, isA<MemoryImage>());
  });

  testWidgets('creates a recipe-based template from the templates page', (
    tester,
  ) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: const <PreparedMeal>[],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
          preparedMealRecipeImporterProvider.overrideWithValue(
            const _FakePreparedMealRecipeImporter(
              PreparedMealRecipeImport(
                recipeUrl:
                    'https://www.chefkoch.de/rezepte/1234/kartoffelsuppe.html',
                title: 'Kartoffelsuppe',
                servings: 5,
                ingredients: <String>['1 kg Kartoffeln', '500 ml Brühe'],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PreparedMealTemplatesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add recipe template'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Recipe link'),
      'chefkoch.de/rezepte/1234/kartoffelsuppe.html',
    );
    await tester.tap(find.text('Create from recipe'));
    await tester.pumpAndSettle();

    expect(find.text('Kartoffelsuppe'), findsOneWidget);
    expect(find.textContaining('Recipe: chefkoch.de'), findsOneWidget);
    expect(find.text('1 kg Kartoffeln'), findsOneWidget);
    expect(repository.savedTemplates, hasLength(1));
    expect(
      repository.savedTemplates.single.recipeUrl,
      'https://www.chefkoch.de/rezepte/1234/kartoffelsuppe.html',
    );
    expect(repository.savedTemplates.single.totalPortions, 5);
  });

  testWidgets('edits a recipe-based template from the templates page', (
    tester,
  ) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _recipeTemplate(id: 'template-1', name: 'Kartoffelsuppe'),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(repository),
          preparedMealRecipeImporterProvider.overrideWithValue(
            const _FakePreparedMealRecipeImporter(
              PreparedMealRecipeImport(
                recipeUrl:
                    'https://www.chefkoch.de/rezepte/9999/linsensuppe.html',
                title: 'Linsensuppe',
                servings: 3,
                ingredients: <String>['500 g Linsen'],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PreparedMealTemplatesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Recipe link'),
      'chefkoch.de/rezepte/9999/linsensuppe.html',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Template name'),
      'Red Lentil Soup',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Portions'), '2');
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Red Lentil Soup'), findsOneWidget);
    expect(find.text('500 g Linsen'), findsOneWidget);
    expect(repository.savedTemplates.single.name, 'Red Lentil Soup');
    expect(repository.savedTemplates.single.totalPortions, 2);
  });
}
