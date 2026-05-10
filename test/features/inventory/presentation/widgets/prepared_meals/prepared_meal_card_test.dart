import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_primary_action_button.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'remaining_progress_bar.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../support/fake_local_image_store.dart';

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final _controller = StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.multi((controller) {
      controller.add(List<InventoryItem>.from(_items));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    _items = List<InventoryItem>.from(items);
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    _items = <InventoryItem>[..._items, ...items];
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  Future<void> dispose() => _controller.close();
}

PreparedMeal _meal() {
  final sourceItem = InventoryItem.create(
    id: 'item-1',
    name: 'Rice',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    unitPrice: 3,
    currencyCode: 'EUR',
    initialAmount: 300,
    currentAmount: 100,
    amountUnit: InventoryAmountUnit.gram,
    imageUrl: 'https://images.example.com/rice.jpg',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 200,
      per100Protein: 10,
      per100Carbs: 20,
      per100Fat: 5,
    ),
  );

  return PreparedMeal(
    id: 'meal-1',
    name: 'Rice bowl',
    imageAssetId: 'asset-meal-1',
    totalPortions: 3,
    remainingPortions: 2,
    totalKcal: 300,
    totalProtein: 15,
    totalCarbs: 30,
    totalFat: 8,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: [
      PreparedMealComponent(
        inventoryItemId: sourceItem.id,
        name: sourceItem.name,
        brand: sourceItem.brand,
        imageUrl: sourceItem.imageUrl,
        usedAmount: 150,
        usedUnit: InventoryAmountUnit.gram,
        totalKcal: 300,
        totalProtein: 15,
        totalCarbs: 30,
        totalFat: 8,
        sourceItemSnapshot: sourceItem,
      ),
    ],
  );
}

PreparedMeal _incompleteMeal() {
  return _meal().copyWith(
    pendingRecipeIngredients: const <String>['Sour cream'],
  );
}

PreparedMeal _depletedMeal() {
  return _meal().copyWith(remainingPortions: 0);
}

Uint8List _pngBytes() {
  return base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAFgwJ/lR3pWQAAAABJRU5ErkJggg==',
  );
}

InventoryItem _inventorySuggestion({required String id, required String name}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    imageUrl: '//images.example.com/sour-cream.jpg',
  );
}

Widget _wrapCard(Widget child) {
  return SingleChildScrollView(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

@Dependencies([InventoryItemsController, preparedMealImagePicker])
void main() {
  testWidgets('PreparedMealCard shows expand indicator and rotates it', (
    tester,
  ) async {
    const indicatorKey = Key('prepared_meal_card_expand_indicator_meal-1');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _meal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialRotation = tester.widget<AnimatedRotation>(
      find.byKey(indicatorKey),
    );
    expect(initialRotation.turns, 0);

    await tester.tap(find.text('Rice bowl'));
    await tester.pumpAndSettle();

    final expandedRotation = tester.widget<AnimatedRotation>(
      find.byKey(indicatorKey),
    );
    expect(expandedRotation.turns, 0.5);
  });

  testWidgets('PreparedMealCard shows eat action in the header', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _meal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Eat'), findsOneWidget);

    await tester.tap(find.byTooltip('Eat'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('prepared_meal_eat_sheet_hero_cover')),
      findsOneWidget,
    );
    expect(find.text('Portions to use'), findsOneWidget);
  });

  testWidgets('PreparedMealCard shows portions progress under header bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _meal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(RemainingProgressBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RemainingProgressBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('/3 portions'),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('300 kcal'), findsNothing);
  });

  testWidgets('PreparedMealCard shows fractional portions progress label', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _meal().copyWith(remainingPortions: 0.5),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );

    final progressBar = tester.widget<RemainingProgressBar>(
      find.byType(RemainingProgressBar),
    );
    expect(progressBar.stockLabel, '0,5/3 Portionen');
    expect(progressBar.ratio, closeTo(1 / 6, 0.0001));
    expect(progressBar.remainingUnits, 0.5);
    expect(progressBar.segmentedByUnits, isFalse);
    expect(find.text('17%'), findsOneWidget);
  });

  testWidgets('PreparedMealCard shows ingredient count in header badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _meal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1 INGREDIENTS'), findsOneWidget);
  });

  testWidgets('PreparedMealCard uses theme primary color for eat button', (
    tester,
  ) async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _meal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );

    final button = tester.widget<InventoryPrimaryActionButton>(
      find.byType(InventoryPrimaryActionButton),
    );

    expect(button.enabledBackgroundColor, theme.colorScheme.primary);
    expect(button.useGradientWhenShowText, isFalse);
  });

  testWidgets('PreparedMealCard expands to show ingredients and actions', (
    tester,
  ) async {
    final localImageStore = FakeLocalImageStore();
    await localImageStore.saveBytes(
      imageRef: localImageAssetRef('asset-meal-1'),
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localImageStoreProvider.overrideWithValue(localImageStore)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _meal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Rice bowl'));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNWidgets(2));
    expect(find.text('Rice'), findsOneWidget);
    expect(
      find.byKey(const Key('prepared_meal_ingredient_avatar_item-1')),
      findsOneWidget,
    );
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Throw away'), findsOneWidget);
    expect(find.text('Return to inventory'), findsOneWidget);
    expect(find.text('Save as template'), findsOneWidget);
  });

  testWidgets(
    'PreparedMealCard disables eat and throw away actions at zero portions',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: _wrapCard(
                PreparedMealCard(
                  meal: _depletedMeal(),
                  onEatPressed:
                      ({
                        required mealId,
                        required portions,
                        required mealType,
                        required loggedDay,
                      }) async => true,
                  onThrowAwayPressed: (mealId, portions, reason) async => true,
                  onUnbundlePressed: (mealId) async => true,
                  onEditPressed: (mealId, result) async => true,
                  onSaveTemplatePressed: (meal) async => true,
                ),
              ),
            ),
          ),
        ),
      );

      final eatButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(eatButton.onPressed, isNull);

      await tester.tap(find.text('Rice bowl'));
      await tester.pumpAndSettle();

      final throwAwayButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Throw away'),
      );
      expect(throwAwayButton.onPressed, isNull);
    },
  );

  testWidgets('PreparedMealCard returns the meal to inventory', (tester) async {
    final meal = _meal();
    String? unbundledMealId;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: meal,
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async {
                  unbundledMealId = mealId;
                  return true;
                },
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Rice bowl'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Return to inventory'));
    await tester.pumpAndSettle();

    expect(unbundledMealId, meal.id);
  });

  testWidgets('PreparedMealCard opens discard reason dialog after portions', (
    tester,
  ) async {
    final meal = _meal();
    String? thrownAwayMealId;
    num? thrownAwayPortions;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: meal,
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async {
                  thrownAwayMealId = mealId;
                  thrownAwayPortions = portions;
                  return true;
                },
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Rice bowl'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Throw away'));
    await tester.pumpAndSettle();

    expect(find.text('Why are you throwing this away?'), findsOneWidget);

    await tester.tap(find.text('Expired'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1');
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(thrownAwayMealId, meal.id);
    expect(thrownAwayPortions, 1);
  });

  testWidgets('PreparedMealCard renders cover image from local device store', (
    tester,
  ) async {
    final localImageStore = FakeLocalImageStore();
    await localImageStore.saveBytes(
      imageRef: localImageAssetRef('asset-meal-1'),
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localImageStoreProvider.overrideWithValue(localImageStore)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _meal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageWidget = tester.widget<Image>(find.byType(Image).first);
    expect(imageWidget.image, isA<MemoryImage>());
  });

  testWidgets('PreparedMealCard passes local cover image into eat sheet', (
    tester,
  ) async {
    final localImageStore = FakeLocalImageStore();
    await localImageStore.saveBytes(
      imageRef: localImageAssetRef('asset-meal-1'),
      bytes: _pngBytes(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localImageStoreProvider.overrideWithValue(localImageStore)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _meal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eat'));
    await tester.pumpAndSettle();

    final heroImage = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('prepared_meal_eat_sheet_hero_cover')),
        matching: find.byType(Image),
      ),
    );
    expect(heroImage.image, isA<MemoryImage>());
  });

  testWidgets('PreparedMealCard shows nutrition toggle and updates values', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _meal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Rice bowl'));
    await tester.pumpAndSettle();

    expect(find.text('100 g/ml'), findsOneWidget);
    expect(find.text('Portion'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('5.3g'), findsOneWidget);
    expect(find.text('Price per 100 g/ml'), findsOneWidget);
    expect(find.text('€1.00'), findsOneWidget);

    await tester.tap(find.text('Portion'));
    await tester.pumpAndSettle();

    expect(find.text('100'), findsOneWidget);
    expect(find.text('2.7g'), findsOneWidget);
    expect(find.text('Price per portion'), findsOneWidget);
    expect(find.text('€0.50'), findsOneWidget);

    await tester.tap(find.text('Total'));
    await tester.pumpAndSettle();

    expect(find.text('300'), findsOneWidget);
    expect(find.text('8g'), findsOneWidget);
    expect(find.text('Total price'), findsOneWidget);
    expect(find.text('€1.50'), findsOneWidget);
  });

  testWidgets(
    'PreparedMealCard uses meal currency instead of app language currency',
    (tester) async {
      final sourceItem = InventoryItem.create(
        id: 'item-usd',
        name: 'Imported rice',
        entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
        storeName: 'Store',
        quantity: 1,
        unitPrice: 3,
        currencyCode: 'USD',
        initialAmount: 300,
        currentAmount: 100,
        amountUnit: InventoryAmountUnit.gram,
        nutrition: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 200,
          per100Protein: 10,
          per100Carbs: 20,
          per100Fat: 5,
        ),
      );
      final meal = PreparedMeal(
        id: 'meal-usd',
        name: 'Imported bowl',
        totalPortions: 3,
        remainingPortions: 3,
        totalKcal: 300,
        totalProtein: 15,
        totalCarbs: 30,
        totalFat: 8,
        createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
        updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
        components: [
          PreparedMealComponent(
            inventoryItemId: sourceItem.id,
            name: sourceItem.name,
            brand: sourceItem.brand,
            imageUrl: sourceItem.imageUrl,
            usedAmount: 150,
            usedUnit: InventoryAmountUnit.gram,
            totalKcal: 300,
            totalProtein: 15,
            totalCarbs: 30,
            totalFat: 8,
            sourceItemSnapshot: sourceItem,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: _wrapCard(
                PreparedMealCard(
                  meal: meal,
                  onEatPressed:
                      ({
                        required mealId,
                        required portions,
                        required mealType,
                        required loggedDay,
                      }) async => true,
                  onThrowAwayPressed: (mealId, portions, reason) async => true,
                  onUnbundlePressed: (mealId) async => true,
                  onEditPressed: (mealId, result) async => true,
                  onSaveTemplatePressed: (meal) async => true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Imported bowl'));
      await tester.pumpAndSettle();

      expect(find.text(r'$1.00'), findsOneWidget);
      expect(find.text('€1.00'), findsNothing);
    },
  );

  testWidgets(
    'PreparedMealCard re-enables eat action after optimistic meal update',
    (tester) async {
      final firstAction = Completer<bool>();
      var meal = _meal();
      var invocationCount = 0;
      late StateSetter setHostState;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setHostState = setState;
                  return _wrapCard(
                    PreparedMealCard(
                      meal: meal,
                      onEatPressed:
                          ({
                            required mealId,
                            required portions,
                            required mealType,
                            required loggedDay,
                          }) async {
                            invocationCount += 1;
                            if (invocationCount == 1) {
                              setHostState(() {
                                meal = meal.copyWith(
                                  remainingPortions: 1,
                                  updatedAt: DateTime.parse(
                                    '2026-03-27T12:05:00Z',
                                  ),
                                );
                              });
                              return firstAction.future;
                            }
                            return true;
                          },
                      onThrowAwayPressed: (mealId, portions, reason) async =>
                          true,
                      onUnbundlePressed: (mealId) async => true,
                      onEditPressed: (mealId, result) async => true,
                      onSaveTemplatePressed: (meal) async => true,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Eat'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('prepared_meal_eat_confirm_button')),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byTooltip('Eat'));
      await tester.pumpAndSettle();

      expect(invocationCount, 1);
      expect(
        find.byKey(const Key('prepared_meal_eat_sheet_hero_cover')),
        findsOneWidget,
      );
      firstAction.complete(true);
    },
  );

  testWidgets('PreparedMealCard hides per-100 mode for piece meals', (
    tester,
  ) async {
    final sourceItem = InventoryItem.create(
      id: 'item-1',
      name: 'Egg',
      entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      imageUrl: 'https://images.example.com/egg.jpg',
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 70,
        per100Protein: 6,
        per100Carbs: 1,
        per100Fat: 5,
      ),
    );

    final meal = PreparedMeal(
      id: 'meal-1',
      name: 'Egg meal',
      totalPortions: 2,
      remainingPortions: 2,
      totalKcal: 140,
      totalProtein: 12,
      totalCarbs: 2,
      totalFat: 10,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
      components: [
        PreparedMealComponent(
          inventoryItemId: sourceItem.id,
          name: sourceItem.name,
          brand: sourceItem.brand,
          imageUrl: sourceItem.imageUrl,
          usedAmount: 2,
          usedUnit: InventoryAmountUnit.piece,
          totalKcal: 140,
          totalProtein: 12,
          totalCarbs: 2,
          totalFat: 10,
          sourceItemSnapshot: sourceItem,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: meal,
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Egg meal'));
    await tester.pumpAndSettle();

    expect(find.text('100 g/ml'), findsNothing);
    expect(find.text('Portion'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });

  testWidgets('PreparedMealCard shows localized incomplete meal details', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _incompleteMeal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
                onFillPendingIngredientPressed:
                    (mealId, ingredient, inventoryItemIds) async => true,
                onIgnorePendingIngredientPressed: (mealId, ingredient) async =>
                    true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Incomplete'), findsOneWidget);

    await tester.tap(find.text('Rice bowl'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This meal is not complete yet and can only be eaten once all '
        'missing ingredients have been added.',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Add ingredient'), findsOneWidget);
    expect(find.byTooltip('Ignore ingredient'), findsOneWidget);
  });

  testWidgets('PreparedMealCard assigns a pending ingredient', (tester) async {
    final repository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[
        _inventorySuggestion(id: 'sour-cream', name: 'Sour cream'),
      ],
    );
    addTearDown(repository.dispose);
    String? filledMealId;
    String? filledIngredient;
    List<String>? filledItemIds;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _incompleteMeal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
                onFillPendingIngredientPressed:
                    (mealId, ingredient, inventoryItemIds) async {
                      filledMealId = mealId;
                      filledIngredient = ingredient;
                      filledItemIds = inventoryItemIds;
                      return true;
                    },
                onIgnorePendingIngredientPressed: (mealId, ingredient) async =>
                    true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rice bowl'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add ingredient'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(filledMealId, 'meal-1');
    expect(filledIngredient, 'Sour cream');
    expect(filledItemIds, <String>['sour-cream']);
  });

  testWidgets('PreparedMealCard ignores a pending ingredient', (tester) async {
    String? ignoredMealId;
    String? ignoredIngredient;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _wrapCard(
              PreparedMealCard(
                meal: _incompleteMeal(),
                onEatPressed:
                    ({
                      required mealId,
                      required portions,
                      required mealType,
                      required loggedDay,
                    }) async => true,
                onThrowAwayPressed: (mealId, portions, reason) async => true,
                onUnbundlePressed: (mealId) async => true,
                onEditPressed: (mealId, result) async => true,
                onSaveTemplatePressed: (meal) async => true,
                onFillPendingIngredientPressed:
                    (mealId, ingredient, inventoryItemIds) async => true,
                onIgnorePendingIngredientPressed: (mealId, ingredient) async {
                  ignoredMealId = mealId;
                  ignoredIngredient = ingredient;
                  return true;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rice bowl'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ignore ingredient'));
    await tester.pumpAndSettle();

    expect(ignoredMealId, 'meal-1');
    expect(ignoredIngredient, 'Sour cream');
  });
}
