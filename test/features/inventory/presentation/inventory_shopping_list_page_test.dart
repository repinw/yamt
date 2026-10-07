import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_plan_needs.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_planned_entry_repository.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

final _now = DateTime(2026, 10, 7, 9);

class _StockRepository implements InventoryItemRepository {
  bool fail = false;
  int watchCount = 0;
  @override
  Stream<List<InventoryItem>> watchAll() {
    watchCount++;
    return fail
        ? Stream.error(StateError('offline'))
        : Stream.value([
            InventoryItem.create(
              id: 'milk',
              name: 'Milk',
              entryDate: DateTime.now(),
              storeName: 'Shop',
              quantity: 0,
            ),
          ]);
  }

  @override
  Future<List<InventoryItem>> readAll() async => [];
  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;
  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

Future<FakeShoppingListRepository> _pump(
  WidgetTester tester,
  _StockRepository stock, {
  List<CalorieEntry> plans = const [],
  FakePlannedEntryRepository? planRepository,
}) async {
  final repository = FakeShoppingListRepository();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(stock),
      shoppingListRepositoryProvider.overrideWithValue(repository),
      plannedEntryRepositoryProvider.overrideWithValue(
        planRepository ?? FakePlannedEntryRepository(plans: plans),
      ),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(repository.dispose);
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
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    'integrated page reads inventory and adds a low-stock suggestion',
    (tester) async {
      final repository = await _pump(tester, _StockRepository());
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.text('Low stock'), findsNothing);
      expect(find.text('Milk'), findsOneWidget);
      await tester.tap(find.byTooltip('Add item'));
      await tester.pumpAndSettle();
      expect(repository.savedItems.single.name, 'Milk');
      expect(find.text('Out of stock'), findsNothing);
    },
  );

  testWidgets(
    'source errors keep shopping usable and retry reloads inventory',
    (tester) async {
      final stock = _StockRepository()..fail = true;
      await _pump(tester, stock);
      expect(find.text('Your shopping list is empty.'), findsOneWidget);
      final suggestionsRetry = find.descendant(
        of: find.byKey(const ValueKey('shopping-suggestions')),
        matching: find.text('Reload suggestions'),
      );
      expect(suggestionsRetry, findsOneWidget);
      // The plan needs read the same stock, so they report it too.
      expect(
        find.text('The needs of your plans could not be loaded'),
        findsOneWidget,
      );
      stock.fail = false;
      final watchesBefore = stock.watchCount;
      await tester.tap(suggestionsRetry);
      await tester.pumpAndSettle();
      expect(stock.watchCount, watchesBefore + 1);
      expect(find.text('Milk'), findsOneWidget);
    },
  );

  testWidgets('a plan the Vorrat cannot cover goes on the list with one tap', (
    tester,
  ) async {
    final tomorrow = _now.add(const Duration(days: 1));
    final plan = CalorieEntry.create(
      id: 'plan',
      userId: 'user-1',
      name: 'Milk',
      mealType: MealType.breakfast,
      consumedAmount: 200,
      consumedUnit: ConsumedUnit.milliliters,
      per100Kcal: 50,
      per100Protein: 3,
      per100Carbs: 5,
      per100Fat: 2,
      sourceInventoryItemId: 'milk',
      loggedAt: tomorrow,
      createdAt: tomorrow,
      updatedAt: tomorrow,
    );
    final repository = await _pump(tester, _StockRepository(), plans: [plan]);

    expect(find.text('For your plan'), findsOneWidget);
    expect(find.text('200 ml'), findsOneWidget);
    await tester.tap(find.byTooltip('Add item').first);
    await tester.pumpAndSettle();

    expect(repository.savedItems.single.name, 'Milk');
    expect(find.text('For your plan'), findsNothing);
  });

  testWidgets('plans that fail to load say so, and retry loads them', (
    tester,
  ) async {
    final plans = FakePlannedEntryRepository()..loadShouldFail = true;
    await _pump(tester, _StockRepository(), planRepository: plans);

    expect(
      find.text('The needs of your plans could not be loaded'),
      findsOneWidget,
    );
    plans.loadShouldFail = false;
    await tester.tap(find.byKey(ShoppingListPlanNeeds.retryKey));
    await tester.pumpAndSettle();

    expect(
      find.text('The needs of your plans could not be loaded'),
      findsNothing,
    );
  });

  testWidgets('a stock failure in the plan needs recovers on their retry', (
    tester,
  ) async {
    final tomorrow = _now.add(const Duration(days: 1));
    final stock = _StockRepository()..fail = true;
    await _pump(
      tester,
      stock,
      plans: [
        CalorieEntry.create(
          id: 'plan',
          userId: 'user-1',
          name: 'Milk',
          mealType: MealType.breakfast,
          consumedAmount: 200,
          consumedUnit: ConsumedUnit.milliliters,
          per100Kcal: 50,
          per100Protein: 3,
          per100Carbs: 5,
          per100Fat: 2,
          sourceInventoryItemId: 'milk',
          loggedAt: tomorrow,
          createdAt: tomorrow,
          updatedAt: tomorrow,
        ),
      ],
    );
    expect(find.byKey(ShoppingListPlanNeeds.retryKey), findsOneWidget);

    stock.fail = false;
    await tester.tap(find.byKey(ShoppingListPlanNeeds.retryKey));
    await tester.pumpAndSettle();

    expect(find.text('For your plan'), findsOneWidget);
    expect(find.byKey(ShoppingListPlanNeeds.retryKey), findsNothing);
  });
}
