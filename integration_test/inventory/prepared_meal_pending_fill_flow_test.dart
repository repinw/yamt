import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_detail_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_ingredients_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'prepared_meal_eat_sheet_body.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_fill_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_ingredient_sheet.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';
import '../../test/helpers/inventory_item_whole_list_writes.dart';
import '../../test/support/prepared_meal_test_data.dart';

const _row = '200 g Reis';

class _StaticInventoryItemsController extends InventoryItemsController {
  @override
  Future<List<InventoryItem>> build() async => [
    InventoryItem.create(
      id: 'rice',
      name: 'Reis',
      entryDate: DateTime(2026, 9, 27),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 1000,
      currentAmount: 600,
      amountUnit: InventoryAmountUnit.gram,
    ),
    // Kept in pieces, so it cannot supply the row's grams (#860).
    InventoryItem.create(
      id: 'rice-bags',
      name: 'Reis Kochbeutel',
      entryDate: DateTime(2026, 9, 27),
      storeName: 'Store',
      quantity: 4,
      initialAmount: 4,
      currentAmount: 4,
      amountUnit: InventoryAmountUnit.piece,
    ),
  ];
}

/// Records the fill and ignore calls instead of saving them.
class _RecordingPreparedMealsController extends PreparedMealsController {
  new(this.calls, {required this.inPot});

  final List<String> calls;

  /// Whether the meal is still in the pot, without open rows; otherwise it
  /// is cooked with one open row.
  final bool inPot;

  @override
  FutureOr<List<PreparedMeal>> build() => [
    PreparedMeal(
      id: 'pan',
      name: 'Reispfanne',
      totalPortions: 1,
      remainingPortions: 1,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: DateTime(2026, 10),
      updatedAt: DateTime(2026, 10),
      components: const <PreparedMealComponent>[],
      recipeIngredients: const [_row],
      pendingRecipeIngredients: inPot ? const <String>[] : const [_row],
      inPot: inPot ? true : null,
    ),
  ];

  @override
  Future<bool> fillPreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
    required List<String> inventoryItemIds,
  }) async {
    calls.add('fill $mealId $ingredient ${inventoryItemIds.join(',')}');
    return true;
  }

  @override
  Future<bool> ignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) async {
    calls.add('ignore $mealId $ingredient');
    return true;
  }
}

class _StaticShoppingListController extends ShoppingListController {
  @override
  Future<List<ShoppingListItem>> build() async => const <ShoppingListItem>[];
}

/// Records the rows it saves on the shopping list in [calls].
class _RecordingShoppingList extends FakeShoppingListRepository {
  new(this.calls);

  final List<String> calls;

  @override
  Future<bool> saveAll(List<ShoppingListItem> items) {
    calls.add('list ${items.map((item) => item.name).join(',')}');
    return super.saveAll(items);
  }
}

Widget _harness(List<String> calls, {bool inPot = false}) {
  final shoppingList = _RecordingShoppingList(calls);
  addTearDown(shoppingList.dispose);
  final container = ProviderContainer(
    overrides: [
      inventoryItemsControllerProvider.overrideWith(
        _StaticInventoryItemsController.new,
      ),
      preparedMealsControllerProvider.overrideWith(
        () => _RecordingPreparedMealsController(calls, inPot: inPot),
      ),
      shoppingListControllerProvider.overrideWith(
        _StaticShoppingListController.new,
      ),
      shoppingListRepositoryProvider.overrideWithValue(shoppingList),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      locale: Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: InventoryPage(includeHomeShellChrome: true)),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await Future<void>.delayed(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _openFillSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('inventory_entry_row_pan')));
  await _settle(tester);
  final fill = find.byKey(const ValueKey('eat_meal_fill_$_row'));
  await tester.ensureVisible(fill);
  await tester.tap(fill);
  await _settle(tester);
  expect(find.byType(PreparedMealPendingFillSheet), findsOneWidget);
}

const _sauceRow = '300 g Tomatensauce';
const _openMealKey = Key('open_meal_detail');

/// Keeps the Vorrat in memory and tells its listeners about every write,
/// as the stored Vorrat does.
class _LiveInventoryItems with InventoryItemWholeListWrites {
  new(this.items);

  List<InventoryItem> items;
  final _changes = StreamController<List<InventoryItem>>.broadcast();

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.multi((controller) {
    controller.add(items);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    this.items = items;
    _changes.add(items);
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) =>
      replaceItems([...this.items, ...items]);
}

/// Keeps the household's meals in memory and tells its listeners about
/// every write, as the stored meals do.
class _LiveMeals implements PreparedMealRepository {
  new(this.meals);

  List<PreparedMeal> meals;
  final _changes = StreamController<List<PreparedMeal>>.broadcast();

  @override
  Stream<List<PreparedMeal>> watchAll() => Stream.multi((controller) {
    controller.add(meals);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<List<PreparedMeal>> readAll() async => meals;

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

/// Signed out, with the stored Vorrat [items] and [meals] faked. Like the
/// Vorrat page, the page keeps the Vorrat and its meals loaded, which the
/// detail page fills an open row from, and it opens the detail page of the
/// one meal.
Widget _detailHarness({
  required _LiveInventoryItems items,
  required _LiveMeals meals,
}) {
  final container = ProviderContainer(
    overrides: [
      firebaseFirestoreProvider.overrideWith((ref) => null),
      authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 10, 12)),
      inventoryItemRepositoryProvider.overrideWithValue(items),
      preparedMealRepositoryProvider.overrideWithValue(meals),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) {
            ref
              ..watch(inventoryItemsControllerProvider)
              ..watch(preparedMealsControllerProvider);
            return Center(
              child: FilledButton(
                key: _openMealKey,
                onPressed: () => PreparedMealDetailFlow.open(
                  context: context,
                  ref: ref,
                  meal: meals.meals.single,
                ),
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// Lets the stored data load and the page settle. Unlike [_settle], it also
/// works on the host, where the data loads outside the test's fake time.
Future<void> _settleData(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The value of the nutrition label row [label] on the meal's page, or null
/// without the row.
String? _labelValue(WidgetTester tester, String label) {
  final name = find.descendant(
    of: find.byKey(PreparedMealEatSheetBody.nutritionTableKey),
    matching: find.text(label),
  );
  if (name.evaluate().isEmpty) {
    return null;
  }
  final row = find.ancestor(of: name, matching: find.byType(Row)).first;
  return tester
      .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
      .last
      .data;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('an open row takes its best Vorrat match', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_harness(calls));
    await _settle(tester);
    await _openFillSheet(tester);

    expect(find.text('Reis'), findsWidgets);
    await tester.tap(find.byKey(PreparedMealPendingFillSheet.takeKey));
    await _settle(tester);

    expect(calls, ['fill pan $_row rice']);
    expect(tester.takeException(), isNull);
  });

  testWidgets("the Vorrat pick offers only items in the row's unit (#860)", (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(_harness(calls));
    await _settle(tester);
    await _openFillSheet(tester);

    final stock = find.byKey(PreparedMealPendingFillSheet.stockKey);
    await tester.ensureVisible(stock);
    await tester.tap(stock);
    await _settle(tester);
    expect(find.byKey(pendingIngredientOptionKey('rice-bags')), findsNothing);
    expect(find.byKey(pendingIngredientUnitHintKey), findsOneWidget);
    await tester.tap(find.byKey(pendingIngredientOptionKey('rice')));
    await tester.pump();
    await tester.tap(find.byKey(pendingIngredientSaveKey));
    await _settle(tester);

    expect(calls, ['fill pan $_row rice']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an open row can be ignored', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_harness(calls));
    await _settle(tester);
    await _openFillSheet(tester);

    // The sheet scrolls once its options fill the screen.
    final ignore = find.byKey(PreparedMealPendingFillSheet.ignoreKey);
    await tester.ensureVisible(ignore);
    await tester.tap(ignore);
    await _settle(tester);

    expect(calls, ['ignore pan $_row']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an open row goes on the shopping list', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_harness(calls));
    await _settle(tester);
    await _openFillSheet(tester);

    final shoppingList = find.byKey(
      PreparedMealPendingFillSheet.shoppingListKey,
    );
    await tester.ensureVisible(shoppingList);
    await tester.tap(shoppingList);
    await _settle(tester);

    expect(calls, ['list $_row']);
    // The row stays open.
    expect(find.byKey(const ValueKey('eat_meal_fill_$_row')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a meal in the pot says so, waits for "Gekocht", and plans a '
      'share of the pot', (tester) async {
    await tester.pumpWidget(_harness(<String>[], inPot: true));
    await _settle(tester);

    expect(find.text('Im Topf'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('inventory_entry_row_pan')));
    await _settle(tester);

    // The detail page keeps its actions, but "Ins Tagebuch" stays off.
    expect(
      find.descendant(
        of: find.byType(EatPageHeader),
        matching: find.text('Im Topf'),
      ),
      findsOneWidget,
    );
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('prepared_meal_eat_confirm_button')),
    );
    expect(confirm.onPressed, isNull);
    // Its rows are filled, so it plans with kcal, measured in pots.
    expect(
      tester
          .widget<FilledButton>(find.byKey(EatPageScaffold.planButtonKey))
          .onPressed,
      isNotNull,
    );
    expect(find.text('Topf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a meal with an open row plans only as a reminder', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(<String>[]));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('inventory_entry_row_pan')));
    await _settle(tester);

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('prepared_meal_eat_confirm_button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(EatPageScaffold.planButtonKey))
          .onPressed,
      isNotNull,
    );
    expect(
      find.byKey(PreparedMealEatSheetBody.reminderHintKey),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the meal shows every nutrient of its ingredients, and a row '
      'filled with a food that lacks values marks it', (tester) async {
    final rice = labeledFoodTestData(
      id: 'rice',
      name: 'Reis',
      grams: 1000,
      label: riceLabelTestData,
    );
    final items = _LiveInventoryItems([
      rice.reducedBy(200)!,
      labeledFoodTestData(
        id: 'sauce',
        name: 'Tomatensauce',
        grams: 500,
        label: sauceLabelTestData,
      ),
    ]);
    final meals = _LiveMeals([
      labeledMealTestData(
        ingredients: [labeledIngredientTestData(rice, 200)],
        pending: const [_sauceRow],
      ),
    ]);
    await tester.pumpWidget(_detailHarness(items: items, meals: meals));
    await _settleData(tester);
    await tester.tap(find.byKey(_openMealKey));
    await _settleData(tester);

    // Rice alone: its whole label, beyond energy and the macros.
    expect(_labelValue(tester, 'Fett'), '2 g');
    expect(_labelValue(tester, 'davon gesättigte Fettsäuren'), '1 g');
    expect(_labelValue(tester, 'davon Zucker'), '2 g');
    expect(_labelValue(tester, 'Ballaststoffe'), '4 g');
    expect(_labelValue(tester, 'Salz'), '0,5 g');
    expect(
      find.byKey(EatMealIngredientsBox.incompleteKey('rice')),
      findsNothing,
    );

    // The open row takes the sauce, whose label has only energy and macros.
    final fill = find.byKey(const ValueKey('eat_meal_fill_$_sauceRow'));
    await tester.ensureVisible(fill);
    await tester.tap(fill);
    await _settleData(tester);
    await tester.tap(find.byKey(PreparedMealPendingFillSheet.takeKey));
    await _settleData(tester);

    expect(meals.meals.single.components, hasLength(2));
    expect(meals.meals.single.pendingRecipeIngredients, isEmpty);
    final note = find.byKey(EatMealIngredientsBox.incompleteKey('sauce'));
    await tester.ensureVisible(note);
    expect(tester.widget<Text>(note).data, 'Nährwerte unvollständig');
    expect(
      find.byKey(EatMealIngredientsBox.incompleteKey('rice')),
      findsNothing,
    );
    expect(_labelValue(tester, 'Fett'), '8 g');
    expect(_labelValue(tester, 'Eiweiß'), '20,5 g');
    // The sauce lacks the rest, so the rice's values become minimums.
    expect(
      _labelValue(tester, 'davon gesättigte Fettsäuren'),
      'mind. 1\u00A0g',
    );
    expect(_labelValue(tester, 'davon Zucker'), 'mind. 2\u00A0g');
    expect(_labelValue(tester, 'Ballaststoffe'), 'mind. 4\u00A0g');
    expect(_labelValue(tester, 'Salz'), 'mind. 0,5\u00A0g');
    expect(tester.takeException(), isNull);
  });
}
