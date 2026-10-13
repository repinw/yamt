import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_detail_flow.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_edit_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_ingredients_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'prepared_meal_edit_open_rows.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_fill_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/inventory_item_whole_list_writes.dart';

const _openKey = Key('open_meal_detail');
const _chickenRow = '200 g Hähnchen';
const _riceRow = '150 g Reis';
const _confirmKey = Key('prepared_meal_eat_confirm_button');
final _now = DateTime.utc(2026, 10, 10, 19);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a food is taken out again, its row ignored and filled later', (
    tester,
  ) async {
    final world = _World();
    await tester.pumpWidget(world.app());
    await _openDetail(tester);

    // Assign the open row, then take the chicken out again with its x.
    await _fillFromBestMatch(tester, _chickenRow);
    await _pumpUntil(tester, () => world.stock('chicken') == 300);
    final unassign = find.byKey(EatMealIngredientsBox.unassignKey('chicken'));
    await _pumpUntilFound(tester, unassign);
    await _tap(tester, unassign);

    await _pumpUntilFound(
      tester,
      find.byKey(EatMealIngredientsBox.openRowKey(_chickenRow)),
    );
    expect(
      find.byKey(EatMealIngredientsBox.unassignKey('chicken')),
      findsNothing,
    );
    expect(world.stock('chicken'), 500);
    expect(world.meal.components.single.inventoryItemId, 'rice');
    expect(world.meal.totalKcal, _cookedMeal().totalKcal);
    expect(_confirm(tester).onPressed, isNull);

    // Ignoring keeps the row, struck through, and the meal can be eaten.
    await _tap(
      tester,
      find.byKey(const ValueKey('eat_meal_ignore_$_chickenRow')),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(EatMealIngredientsBox.ignoredRowKey(_chickenRow)),
    );
    expect(world.meal.ignoredPendingRecipeIngredients, [_chickenRow]);
    expect(_confirm(tester).onPressed, isNotNull);

    // The ignored row can still be filled.
    await _fillFromBestMatch(tester, _chickenRow, ignored: true);
    await _pumpUntilFound(
      tester,
      find.byKey(EatMealIngredientsBox.unassignKey('chicken')),
    );
    expect(
      find.byKey(EatMealIngredientsBox.ignoredRowKey(_chickenRow)),
      findsNothing,
    );
    expect(world.meal.ignoredPendingRecipeIngredients, isEmpty);
    expect(world.stock('chicken'), 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing a food in the editor leaves its row open, and undo '
      'brings the food back', (tester) async {
    final world = _World();
    await tester.pumpWidget(world.app());
    await _openDetail(tester);

    await _tap(tester, find.byKey(const Key('eat_meal_action_edit')));
    await _pumpUntilFound(tester, find.byKey(PreparedMealEditPage.saveKey));
    await _tap(tester, find.byKey(PreparedMealEditPage.removeKey('rice')));
    expect(
      find.byKey(PreparedMealEditOpenRows.openKey(_riceRow)),
      findsOneWidget,
    );
    await _tap(tester, find.byKey(PreparedMealEditPage.saveKey));

    await _pumpUntilFound(
      tester,
      find.byKey(EatMealIngredientsBox.openRowKey(_riceRow)),
    );
    expect(world.meal.components, isEmpty);
    expect(world.meal.pendingRecipeIngredients, [_chickenRow, _riceRow]);
    expect(world.stock('rice'), 1000);

    final undo = find.descendant(
      of: find.byType(AppSnackBarView),
      matching: find.byType(TextButton),
    );
    await _pumpUntilFound(tester, undo);
    // Let the snack bar finish sliding in, so the tap lands on the button.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(undo);

    await _pumpUntil(tester, () => world.meal.components.isNotEmpty);
    expect(world.meal, _cookedMeal().copyWith(updatedAt: _now));
    expect(world.stock('rice'), 850);
    await _pumpUntilFound(
      tester,
      find.byKey(EatMealIngredientsBox.unassignKey('rice')),
    );
    expect(tester.takeException(), isNull);
  });
}

FilledButton _confirm(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(_confirmKey));

Future<void> _openDetail(WidgetTester tester) async {
  await _pumpUntilFound(tester, find.byKey(_openKey));
  await tester.tap(find.byKey(_openKey));
  await _pumpUntilFound(tester, find.byKey(_confirmKey));
  await _settle(tester);
}

/// Fills [row] with its best Vorrat match through "Zeile füllen".
Future<void> _fillFromBestMatch(
  WidgetTester tester,
  String row, {
  bool ignored = false,
}) async {
  await _tap(tester, find.byKey(EatMealIngredientsBox.fillKey(row)));
  await _pumpUntilFound(
    tester,
    find.byKey(PreparedMealPendingFillSheet.takeKey),
  );
  expect(
    find.byKey(PreparedMealPendingFillSheet.ignoreKey),
    ignored ? findsNothing : findsOneWidget,
  );
  await _tap(tester, find.byKey(PreparedMealPendingFillSheet.takeKey));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _settle(tester);
  await tester.tap(finder);
  await _settle(tester);
}

/// Lets taps, route animations and the fake streams finish. Pumps only,
/// so it works with and without the live binding.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) =>
    _pumpUntil(tester, () => finder.evaluate().isNotEmpty);

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(done(), isTrue);
}

/// A cooked rice pan whose rice was taken while cooking and whose chicken
/// is still open.
PreparedMeal _cookedMeal() {
  final rice = _item('rice', 'Reis', grams: 1000);
  return PreparedMeal(
    id: 'pan',
    name: 'Reispfanne',
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 195.45,
    totalProtein: 4.05,
    totalCarbs: 42.15,
    totalFat: 0.45,
    createdAt: DateTime.utc(2026, 10, 10, 18),
    updatedAt: DateTime.utc(2026, 10, 10, 18),
    components: [
      PreparedMealComponent(
        inventoryItemId: 'rice',
        name: 'Reis',
        brand: null,
        imageUrl: null,
        usedAmount: 150,
        usedUnit: InventoryAmountUnit.gram,
        totalKcal: 195.45,
        totalProtein: 4.05,
        totalCarbs: 42.15,
        totalFat: 0.45,
        sourceItemSnapshot: rice,
        pendingRecipeIngredient: _riceRow,
      ),
    ],
    recipeIngredients: const [_riceRow, _chickenRow],
    pendingRecipeIngredients: const [_chickenRow],
  );
}

InventoryItem _item(String id, String name, {required int grams}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.utc(2026, 10, 9),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: grams,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 130.3,
      per100Protein: 2.7,
      per100Carbs: 28.1,
      per100Fat: 0.3,
    ),
  );
}

/// The household's meal and Vorrat in memory, behind the real meal
/// controllers and service.
class _World {
  final _meals = _Meals(_cookedMeal());
  final _items = _Items([
    _item('rice', 'Reis', grams: 850),
    _item('chicken', 'Hähnchen', grams: 500),
  ]);

  PreparedMeal get meal => _meals.meals.single;

  int stock(String itemId) =>
      _items.items.firstWhere((item) => item.id == itemId).currentAmount;

  Widget app() {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        // Signed out: the Vorrat controllers read only the fakes.
        authStateChangesProvider.overrideWithValue(
          const AsyncData<User?>(null),
        ),
        userProfileProvider.overrideWithValue(const AsyncData(null)),
        firebaseFirestoreProvider.overrideWith((ref) => null),
        preparedMealRepositoryProvider.overrideWithValue(_meals),
        inventoryItemRepositoryProvider.overrideWithValue(_items),
        inventoryActivityEventRepositoryProvider.overrideWithValue(
          _NoActivity(),
        ),
        inventoryActivityActorProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: _VorratHost()),
      ),
    );
  }
}

/// Stands in for the Vorrat page: it keeps the Vorrat and its meals loaded
/// and opens the meal's detail page.
class _VorratHost extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryItemsControllerProvider).value;
    final meal = ref.watch(preparedMealsControllerProvider).value?.single;
    if (items == null || meal == null) {
      return const SizedBox.shrink();
    }
    return Center(
      child: FilledButton(
        key: _openKey,
        onPressed: () =>
            PreparedMealDetailFlow.open(context: context, ref: ref, meal: meal),
        child: Text(meal.name),
      ),
    );
  }
}

class _Meals implements PreparedMealRepository {
  new(PreparedMeal meal) : meals = [meal];

  final _changes = StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> meals;

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    yield meals;
    yield* _changes.stream;
  }

  @override
  Future<List<PreparedMeal>> readAll() async => List.of(meals);

  @override
  Future<List<PreparedMeal>> readAllForChange() => readAll();

  @override
  Future<bool> save(PreparedMeal meal) async {
    meals = [
      for (final stored in meals)
        if (stored.id == meal.id) meal else stored,
    ];
    _changes.add(meals);
    return true;
  }

  @override
  Future<bool> delete(String mealId) async {
    meals = [
      for (final stored in meals)
        if (stored.id != mealId) stored,
    ];
    _changes.add(meals);
    return true;
  }
}

class _Items with InventoryItemWholeListWrites {
  new(this.items);

  final _changes = StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield items;
    yield* _changes.stream;
  }

  @override
  Future<List<InventoryItem>> readAll() async => List.of(items);

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    this.items = List.of(items);
    _changes.add(this.items);
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    this.items = [...this.items, ...items];
    _changes.add(this.items);
    return true;
  }
}

class _NoActivity implements InventoryActivityEventRepository {
  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) =>
      const Stream.empty();

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async => true;
}
