import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_plan_needs.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';
import '../../test/helpers/inventory_item_whole_list_writes.dart';

final _now = DateTime(2026, 10, 7, 9);

/// Oats in stock: 100 g left of a 500 g pack.
class _StockRepository with InventoryItemWholeListWrites {
  final _items = [
    InventoryItem.create(
      id: 'oats',
      name: 'Haferflocken',
      entryDate: DateTime(2026, 10),
      storeName: 'Rewe',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 100,
      amountUnit: InventoryAmountUnit.gram,
    ),
  ];

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    // A real stream answers after a gap, like Firestore.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield _items;
  }

  @override
  Future<List<InventoryItem>> readAll() async => _items;
  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;
  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a plan the Vorrat cannot cover goes on the shopping list', (
    tester,
  ) async {
    final tomorrow = _now.add(const Duration(days: 1));
    final shopping = FakeShoppingListRepository();
    addTearDown(shopping.dispose);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        inventoryItemRepositoryProvider.overrideWithValue(_StockRepository()),
        shoppingListRepositoryProvider.overrideWithValue(shopping),
        plannedEntryRepositoryProvider.overrideWithValue(
          FakePlannedEntryRepository(
            plans: [
              CalorieEntry.create(
                id: 'porridge',
                userId: 'user-1',
                name: 'Haferflocken',
                mealType: MealType.breakfast,
                consumedAmount: 300,
                consumedUnit: ConsumedUnit.grams,
                per100Kcal: 370,
                per100Protein: 13,
                per100Carbs: 59,
                per100Fat: 7,
                sourceInventoryItemId: 'oats',
                loggedAt: tomorrow,
                createdAt: _now,
                updatedAt: _now,
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InventoryShoppingListPage(),
        ),
      ),
    );

    final add = find.byKey(
      ShoppingListPlanNeeds.addKey(
        ShoppingPlanNeed(
          name: 'Haferflocken',
          day: tomorrow,
          mealType: MealType.breakfast,
          amount: 0,
          inMilliliters: false,
          isPartial: true,
        ),
      ),
    );
    for (var i = 0; i < 50 && add.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(add, findsOneWidget);
    // 100 g in stock cover a third of the 300 g plan.
    expect(find.textContaining('200 g missing'), findsOneWidget);

    await tester.tap(add);
    for (var i = 0; i < 50 && shopping.savedItems.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(shopping.savedItems.single.name, 'Haferflocken');
    expect(tester.takeException(), isNull);
  });
}
