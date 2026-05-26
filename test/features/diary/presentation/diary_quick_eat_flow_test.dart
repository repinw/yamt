import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/diary_inventory_food_picker.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/product_search/presentation/inventory_manual_add_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/diary_dashboard_test_support.dart';

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  diaryQuickEatInventory,
  inventoryBackedCalorieEntrySaveFlow,
])
void main() {
  testWidgets('manual quick-eat sources push manual add with route args', (
    tester,
  ) async {
    final cases = <DiaryQuickEatSource, InventoryManualAddInitialAction>{
      DiaryQuickEatSource.barcode: InventoryManualAddInitialAction.barcodeScan,
      DiaryQuickEatSource.manualSearch:
          InventoryManualAddInitialAction.manualSearch,
      DiaryQuickEatSource.ai: InventoryManualAddInitialAction.aiSuggestion,
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(
        _RouteHarness(
          source: entry.key,
          selectedDay: DateTime(2026, 4, 27),
        ),
      );

      await tester.tap(find.byKey(_openFlowButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('action:${entry.value.name}'), findsOneWidget);
      expect(find.text('quickEatOnly:true'), findsOneWidget);
      expect(find.text('mealType:lunch'), findsOneWidget);
      expect(find.text('loggedDay:2026-04-27'), findsOneWidget);
    }
  });

  testWidgets('manual quick-eat route keeps future selected day', (
    tester,
  ) async {
    final futureDay = DateTime.now().add(const Duration(days: 1));
    final expectedDay =
        '${futureDay.year.toString().padLeft(4, '0')}-'
        '${futureDay.month.toString().padLeft(2, '0')}-'
        '${futureDay.day.toString().padLeft(2, '0')}';

    await tester.pumpWidget(
      _RouteHarness(
        source: DiaryQuickEatSource.manualSearch,
        selectedDay: futureDay,
      ),
    );

    await tester.tap(find.byKey(_openFlowButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('loggedDay:$expectedDay'), findsOneWidget);
  });

  testWidgets(
    'inventory picker shows empty state without shrink-wrapping list',
    (
      tester,
    ) async {
      await _pumpPickerHarness(
        tester,
        items: const <InventoryItem>[],
        meals: const <PreparedMeal>[],
      );

      await tester.tap(find.byKey(_openPickerButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('No available food in inventory.'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    },
  );

  testWidgets('inventory picker renders foods lazily and returns selection', (
    tester,
  ) async {
    final item = _inventoryItem(id: 'item-1', name: 'Greek Yogurt');
    final meal = _preparedMeal(
      id: 'meal-1',
      name: 'Pasta Bowl',
      remainingPortions: 0.5,
    );

    await _pumpPickerHarness(
      tester,
      items: [item],
      meals: [meal],
      locale: const Locale('de'),
    );

    await tester.tap(find.byKey(_openPickerButtonKey));
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.shrinkWrap, isFalse);
    expect(find.text('Greek Yogurt'), findsOneWidget);
    expect(find.text('Pasta Bowl'), findsOneWidget);
    expect(find.text('0,5/2 Portionen'), findsOneWidget);

    await tester.tap(find.text('Greek Yogurt'));
    await tester.pumpAndSettle();

    expect(find.text('selected:item:item-1'), findsOneWidget);

    await tester.tap(find.byKey(_openPickerButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pasta Bowl'));
    await tester.pumpAndSettle();

    expect(find.text('selected:meal:meal-1'), findsOneWidget);
  });

  test('inventory availability rejects depleted items', () {
    expect(
      canDiaryQuickEatInventoryItem(
        _inventoryItem(id: 'available', name: 'Available'),
      ),
      isTrue,
    );
    expect(
      canDiaryQuickEatInventoryItem(
        _inventoryItem(id: 'depleted', name: 'Depleted', quantity: 0),
      ),
      isFalse,
    );
    expect(
      canDiaryQuickEatInventoryItem(
        _inventoryItem(
          id: 'empty-progress',
          name: 'Empty progress',
          initialAmount: 500,
          amountUnit: InventoryAmountUnit.gram,
        ),
      ),
      isFalse,
    );
    expect(
      canDiaryQuickEatInventoryItem(
        _inventoryItem(
          id: 'missing-progress-unit',
          name: 'Missing progress unit',
          initialAmount: 500,
          currentAmount: 250,
        ),
      ),
      isTrue,
    );
  });

  testWidgets('inventory quick eat hides depleted provider items', (
    tester,
  ) async {
    await _pumpInventoryFlowHarness(
      tester,
      inventoryItems: [
        _inventoryItem(id: 'available', name: 'Available food'),
        _inventoryItem(id: 'depleted', name: 'Depleted food', quantity: 0),
        _inventoryItem(
          id: 'empty-progress',
          name: 'Empty progress food',
          initialAmount: 500,
          amountUnit: InventoryAmountUnit.gram,
        ),
      ],
      preparedMeals: const <PreparedMeal>[],
    );

    await tester.tap(find.byKey(_openInventoryFlowButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Available food'), findsOneWidget);
    expect(find.text('Depleted food'), findsNothing);
    expect(find.text('Empty progress food'), findsNothing);
  });

  testWidgets('inventory quick eat waits for provider load before picker', (
    tester,
  ) async {
    final inventoryGate = Completer<void>();
    final mealsGate = Completer<void>();
    await _pumpDelayedInventoryFlowHarness(
      tester,
      inventoryItems: [_inventoryItem(id: 'item-1', name: 'Loaded food')],
      preparedMeals: const <PreparedMeal>[],
      inventoryGate: inventoryGate,
      mealsGate: mealsGate,
    );

    await tester.tap(find.byKey(_openInventoryFlowButtonKey));
    await tester.pump();

    expect(find.text('No available food in inventory.'), findsNothing);
    expect(find.text('Loaded food'), findsNothing);

    inventoryGate.complete();
    mealsGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Loaded food'), findsOneWidget);
    expect(find.text('No available food in inventory.'), findsNothing);
  });

  testWidgets('inventory item stage failure shows action failed snackbar', (
    tester,
  ) async {
    _stageCallCount = 0;
    _discardedPendingIds.clear();
    await _pumpInventoryFlowHarness(
      tester,
      inventoryItems: [
        _inventoryItem(
          id: 'item-1',
          name: 'Stage Failure Food',
          initialAmount: 100,
          currentAmount: 100,
          amountUnit: InventoryAmountUnit.gram,
        ),
      ],
      preparedMeals: const <PreparedMeal>[],
      failInventoryStage: true,
    );

    await tester.tap(find.byKey(_openInventoryFlowButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stage Failure Food'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '100',
    );
    await tester.pump();
    final confirmButton = find.byKey(
      const Key('inventory_item_amount_dialog_confirm_button'),
    );
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(_stageCallCount, 1);
    expect(find.textContaining('Action failed'), findsOneWidget);
  });

  testWidgets(
    'inventory quick eat uses staged consumption from page container',
    (
      tester,
    ) async {
      _stageCallCount = 0;
      _discardedPendingIds.clear();
      await _pumpInventoryFlowHarness(
        tester,
        inventoryItems: [
          _inventoryItem(
            id: 'item-1',
            name: 'No Nutrition Food',
            initialAmount: 100,
            currentAmount: 100,
            amountUnit: InventoryAmountUnit.gram,
            nutrition: null,
          ),
        ],
        preparedMeals: const <PreparedMeal>[],
      );

      await tester.tap(find.byKey(_openInventoryFlowButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No Nutrition Food'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('inventory_item_amount_dialog_field')),
        '100',
      );
      await tester.pump();
      final confirmButton = find.byKey(
        const Key('inventory_item_amount_dialog_confirm_button'),
      );
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(_stageCallCount, 1);
      expect(_discardedPendingIds, <String>['pending-item-1']);
      expect(find.textContaining('Action failed'), findsOneWidget);
    },
  );

  testWidgets('prepared meal consume failure shows prepared meal snackbar', (
    tester,
  ) async {
    await _pumpInventoryFlowHarness(
      tester,
      inventoryItems: const <InventoryItem>[],
      preparedMeals: [
        _preparedMeal(id: 'meal-1', name: 'Failure Meal'),
      ],
      failPreparedMealConsume: true,
    );

    await tester.tap(find.byKey(_openInventoryFlowButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Failure Meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prepared_meal_eat_confirm_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Prepared meal action failed'), findsOneWidget);
  });
}

const _openFlowButtonKey = Key('open_quick_eat_flow');
const _openPickerButtonKey = Key('open_inventory_picker');
const _openInventoryFlowButtonKey = Key('open_inventory_quick_eat_flow');
final _inventoryFlowDay = DateTime(2026, 4, 27);
int _stageCallCount = 0;
final _discardedPendingIds = <String>[];

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  diaryQuickEatInventory,
  inventoryBackedCalorieEntrySaveFlow,
])
class _RouteHarness extends StatelessWidget {
  const _RouteHarness({
    required this.source,
    required this.selectedDay,
  });

  final DiaryQuickEatSource source;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: AppRoutes.root,
      routes: [
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) => _QuickEatRouteLauncher(
            source: source,
            selectedDay: selectedDay,
          ),
        ),
        GoRoute(
          path: AppRoutes.homeInventoryManualAdd,
          builder: (context, state) {
            final args = state.extra! as InventoryManualAddRouteArgs;
            final loggedAt = args.preselectedLoggedAt!;
            final dayText =
                '${loggedAt.year.toString().padLeft(4, '0')}-'
                '${loggedAt.month.toString().padLeft(2, '0')}-'
                '${loggedAt.day.toString().padLeft(2, '0')}';

            return Scaffold(
              body: Column(
                children: [
                  Text('action:${args.initialAction.name}'),
                  Text('quickEatOnly:${args.quickEatOnly}'),
                  Text('mealType:${args.preselectedMealType!.jsonValue}'),
                  Text('loggedDay:$dayText'),
                ],
              ),
            );
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [_dashboardOverrideFor(selectedDay)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  diaryQuickEatInventory,
  inventoryBackedCalorieEntrySaveFlow,
])
class _QuickEatRouteLauncher extends ConsumerWidget {
  const _QuickEatRouteLauncher({
    required this.source,
    required this.selectedDay,
  });

  final DiaryQuickEatSource source;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: TextButton(
        key: _openFlowButtonKey,
        onPressed: () {
          unawaited(
            DiaryQuickEatFlow.openSource(
              context: context,
              ref: ref,
              source: source,
              mealType: MealType.lunch,
              selectedDay: selectedDay,
            ),
          );
        },
        child: const Text('Open'),
      ),
    );
  }
}

Future<void> _pumpPickerHarness(
  WidgetTester tester, {
  required List<InventoryItem> items,
  required List<PreparedMeal> meals,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _PickerHarness(items: items, meals: meals),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpInventoryFlowHarness(
  WidgetTester tester, {
  required List<InventoryItem> inventoryItems,
  required List<PreparedMeal> preparedMeals,
  bool failInventoryStage = false,
  bool failPreparedMealConsume = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        _dashboardOverrideFor(_inventoryFlowDay),
        inventoryItemsControllerProvider.overrideWith(
          () => _TestInventoryItemsController(
            inventoryItems,
            failStage: failInventoryStage,
          ),
        ),
        preparedMealsControllerProvider.overrideWith(
          () => _TestPreparedMealsController(
            preparedMeals,
            failConsume: failPreparedMealConsume,
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _InventoryFlowHarness(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDelayedInventoryFlowHarness(
  WidgetTester tester, {
  required List<InventoryItem> inventoryItems,
  required List<PreparedMeal> preparedMeals,
  required Completer<void> inventoryGate,
  required Completer<void> mealsGate,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        _dashboardOverrideFor(_inventoryFlowDay),
        inventoryItemsControllerProvider.overrideWith(
          () => _DelayedInventoryItemsController(
            inventoryItems,
            gate: inventoryGate,
          ),
        ),
        preparedMealsControllerProvider.overrideWith(
          () => _DelayedPreparedMealsController(
            preparedMeals,
            gate: mealsGate,
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _InventoryFlowHarness(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

@Dependencies([
  InventoryItemsController,
  diaryQuickEatInventory,
  PreparedMealsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class _InventoryFlowHarness extends ConsumerWidget {
  const _InventoryFlowHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: TextButton(
        key: _openInventoryFlowButtonKey,
        onPressed: () {
          unawaited(
            DiaryQuickEatFlow.openSource(
              context: context,
              ref: ref,
              source: DiaryQuickEatSource.inventory,
              mealType: MealType.lunch,
              selectedDay: _inventoryFlowDay,
            ),
          );
        },
        child: const Text('Open inventory'),
      ),
    );
  }
}

Override _dashboardOverrideFor(DateTime day) {
  final normalizedDay = normalizeDiaryDay(day);
  return diaryDayDashboardControllerProvider(normalizedDay).overrideWith(
    () => FakeDiaryDayDashboardController(
      diaryDashboardLoadedStateForTest(selectedDay: normalizedDay),
    ),
  );
}

class _TestInventoryItemsController extends InventoryItemsController {
  _TestInventoryItemsController(this._items, {required this.failStage});

  final List<InventoryItem> _items;
  final bool failStage;

  @override
  FutureOr<List<InventoryItem>> build() async {
    return _items;
  }

  @override
  Future<PendingInventoryConsumption?> stagePendingConsumption(
    String itemId,
    int amount,
  ) async {
    _stageCallCount += 1;
    if (failStage) {
      return null;
    }
    return PendingInventoryConsumption(
      id: 'pending-$itemId',
      itemId: itemId,
      amount: amount,
    );
  }

  @override
  Future<bool> discardPendingConsumption(String draftId) async {
    _discardedPendingIds.add(draftId);
    return true;
  }
}

class _DelayedInventoryItemsController extends InventoryItemsController {
  _DelayedInventoryItemsController(this._items, {required this.gate});

  final List<InventoryItem> _items;
  final Completer<void> gate;

  @override
  FutureOr<List<InventoryItem>> build() async {
    await gate.future;
    return _items;
  }
}

class _TestPreparedMealsController extends PreparedMealsController {
  _TestPreparedMealsController(this._meals, {required this.failConsume});

  final List<PreparedMeal> _meals;
  final bool failConsume;

  @override
  FutureOr<List<PreparedMeal>> build() async {
    return _meals;
  }

  @override
  Future<bool> consumePreparedMeal({
    required String mealId,
    required num consumedPortions,
    required MealType mealType,
    DateTime? loggedDay,
  }) async {
    return !failConsume;
  }
}

class _DelayedPreparedMealsController extends PreparedMealsController {
  _DelayedPreparedMealsController(this._meals, {required this.gate});

  final List<PreparedMeal> _meals;
  final Completer<void> gate;

  @override
  FutureOr<List<PreparedMeal>> build() async {
    await gate.future;
    return _meals;
  }
}

class _PickerHarness extends StatefulWidget {
  const _PickerHarness({
    required this.items,
    required this.meals,
  });

  final List<InventoryItem> items;
  final List<PreparedMeal> meals;

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  String _selectedText = 'selected:none';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_selectedText),
          TextButton(
            key: _openPickerButtonKey,
            onPressed: () {
              unawaited(_openPicker());
            },
            child: const Text('Open picker'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPicker() async {
    final selection = await showModalBottomSheet<DiaryInventoryFoodSelection>(
      context: context,
      builder: (context) => DiaryInventoryFoodPicker(
        items: widget.items,
        meals: widget.meals,
      ),
    );
    if (!mounted || selection == null) {
      return;
    }

    setState(() {
      _selectedText = switch (selection) {
        DiaryInventoryItemFoodSelection(:final item) =>
          'selected:item:${item.id}',
        DiaryPreparedMealFoodSelection(:final meal) =>
          'selected:meal:${meal.id}',
      };
    });
  }
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  int quantity = 1,
  int initialAmount = 0,
  int currentAmount = 0,
  InventoryAmountUnit? amountUnit,
  GlobalFoodNutrition? nutrition = const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 100,
  ),
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 4, 27),
    storeName: 'Test Store',
    quantity: quantity,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
    brand: 'Test Brand',
    imageUrl: 'https://example.com/$id.jpg',
    weight: '100g',
    nutrition: nutrition,
  );
}

PreparedMeal _preparedMeal({
  required String id,
  required String name,
  num remainingPortions = 1,
}) {
  return PreparedMeal(
    id: id,
    name: name,
    totalPortions: 2,
    remainingPortions: remainingPortions,
    totalKcal: 500,
    totalProtein: 20,
    totalCarbs: 60,
    totalFat: 10,
    createdAt: DateTime(2026, 4, 27),
    updatedAt: DateTime(2026, 4, 27),
    components: const [],
    imageUrl: 'https://example.com/$id.jpg',
  );
}
