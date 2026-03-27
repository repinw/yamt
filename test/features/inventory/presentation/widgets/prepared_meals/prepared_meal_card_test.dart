import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../support/fake_local_image_store.dart';

PreparedMeal _meal() {
  final sourceItem = InventoryItem.create(
    id: 'item-1',
    name: 'Rice',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
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
    imageBase64: base64Encode(<int>[1, 2, 3]),
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

void main() {
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
            body: PreparedMealCard(
              meal: _meal(),
              onEatPressed: (mealId, portions, mealType) async => true,
              onThrowAwayPressed: (mealId, portions) async => true,
              onUnbundlePressed: (mealId) async => true,
              onEditPressed: (mealId, name, imageChanged, imageBytes) async =>
                  true,
              onSaveTemplatePressed: (meal) async => true,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Eat'), findsOneWidget);

    await tester.tap(find.byTooltip('Eat'));
    await tester.pumpAndSettle();

    expect(find.text('Eat prepared meal'), findsOneWidget);
    expect(find.text('Portions to use'), findsOneWidget);
  });

  testWidgets('PreparedMealCard expands to show ingredients and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PreparedMealCard(
              meal: _meal(),
              onEatPressed: (mealId, portions, mealType) async => true,
              onThrowAwayPressed: (mealId, portions) async => true,
              onUnbundlePressed: (mealId) async => true,
              onEditPressed: (mealId, name, imageChanged, imageBytes) async =>
                  true,
              onSaveTemplatePressed: (meal) async => true,
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
    expect(find.text('Unbundle'), findsOneWidget);
    expect(find.text('Save as template'), findsOneWidget);
  });

  testWidgets('PreparedMealCard renders cover image from local device store', (
    tester,
  ) async {
    final localImageStore = FakeLocalImageStore();
    await localImageStore.saveBytes(
      imageRef: const LocalImageRef.preparedMeal('meal-1'),
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localImageStoreProvider.overrideWithValue(localImageStore),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PreparedMealCard(
              meal: _meal().copyWith(imageBase64: null),
              onEatPressed: (mealId, portions, mealType) async => true,
              onThrowAwayPressed: (mealId, portions) async => true,
              onUnbundlePressed: (mealId) async => true,
              onEditPressed: (mealId, name, imageChanged, imageBytes) async =>
                  true,
              onSaveTemplatePressed: (meal) async => true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageWidget = tester.widget<Image>(find.byType(Image).first);
    expect(imageWidget.image, isA<MemoryImage>());
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
            body: PreparedMealCard(
              meal: _meal(),
              onEatPressed: (mealId, portions, mealType) async => true,
              onThrowAwayPressed: (mealId, portions) async => true,
              onUnbundlePressed: (mealId) async => true,
              onEditPressed: (mealId, name, imageChanged, imageBytes) async =>
                  true,
              onSaveTemplatePressed: (meal) async => true,
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

    await tester.tap(find.text('Portion'));
    await tester.pumpAndSettle();

    expect(find.text('100'), findsOneWidget);
    expect(find.text('2.7g'), findsOneWidget);

    await tester.tap(find.text('Total'));
    await tester.pumpAndSettle();

    expect(find.text('300'), findsOneWidget);
    expect(find.text('8g'), findsOneWidget);
  });

  testWidgets('PreparedMealCard hides per-100 mode for piece meals', (
    tester,
  ) async {
    final sourceItem = InventoryItem.create(
      id: 'item-1',
      name: 'Egg',
      entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      initialQuantity: 1,
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
            body: PreparedMealCard(
              meal: meal,
              onEatPressed: (mealId, portions, mealType) async => true,
              onThrowAwayPressed: (mealId, portions) async => true,
              onUnbundlePressed: (mealId) async => true,
              onEditPressed: (mealId, name, imageChanged, imageBytes) async =>
                  true,
              onSaveTemplatePressed: (meal) async => true,
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
}
