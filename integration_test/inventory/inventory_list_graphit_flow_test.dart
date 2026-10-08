import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/core/widgets/graphit_stock_bar.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_quick_filter.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_edit_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_detail_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_entries_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_quick_filter_chips.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_sort_sheet.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _StaticInventoryItemsController extends InventoryItemsController {
  @override
  Future<List<InventoryItem>> build() async => [
    _food('skyr', 'Skyr', left: 1000, full: 1000),
    _food('quark', 'Magerquark', left: 100, full: 1000, packs: 2),
  ];
}

final _chili = PreparedMeal(
  id: 'chili',
  name: 'Chili sin Carne',
  totalPortions: 4,
  remainingPortions: 3,
  totalKcal: 1840,
  totalProtein: 96,
  totalCarbs: 212,
  totalFat: 52,
  createdAt: DateTime(2026, 9, 28),
  updatedAt: DateTime(2026, 9, 28),
  components: const <PreparedMealComponent>[],
  pendingRecipeIngredients: const ['Reis'],
);

class _StaticPreparedMealsController extends PreparedMealsController {
  @override
  FutureOr<List<PreparedMeal>> build() => [_chili];
}

/// The stored meals that the meal editor reads and writes.
class _StaticPreparedMealRepository implements PreparedMealRepository {
  List<PreparedMeal> meals = [_chili];

  @override
  Stream<List<PreparedMeal>> watchAll() => Stream.value(meals);

  @override
  Future<List<PreparedMeal>> readAll() async => meals;

  @override
  Future<bool> save(PreparedMeal meal) async {
    meals = [
      for (final stored in meals)
        if (stored.id == meal.id) meal else stored,
    ];
    return true;
  }

  @override
  Future<bool> delete(String mealId) async {
    meals = [
      for (final stored in meals)
        if (stored.id != mealId) stored,
    ];
    return true;
  }
}

class _StaticShoppingListController extends ShoppingListController {
  @override
  Future<List<ShoppingListItem>> build() async => const <ShoppingListItem>[];
}

InventoryItem _food(
  String id,
  String name, {
  required int left,
  required int full,
  int packs = 1,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 9, 27),
    storeName: 'Store',
    quantity: packs,
    initialQuantity: packs,
    initialAmount: full,
    currentAmount: left,
    amountUnit: InventoryAmountUnit.gram,
  );
}

Widget _buildHarness() {
  final container = ProviderContainer(
    overrides: [
      inventoryItemsControllerProvider.overrideWith(
        _StaticInventoryItemsController.new,
      ),
      preparedMealsControllerProvider.overrideWith(
        _StaticPreparedMealsController.new,
      ),
      preparedMealRepositoryProvider.overrideWithValue(
        _StaticPreparedMealRepository(),
      ),
      shoppingListControllerProvider.overrideWith(
        _StaticShoppingListController.new,
      ),
      // Plans for tomorrow take 250 g of the Skyr and a portion of the
      // Chili.
      openPlanDemandProvider.overrideWith(
        (ref) async => (
          plannedByItemId: const {'skyr': 250},
          missingByItemId: const <String, int>{},
          plannedPortionsByMealId: const {'chili': 1.0},
          missingShareByPlanId: const <String, double>{},
        ),
      ),
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

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  final end = tester.binding.clock.fromNowBy(const Duration(seconds: 8));
  while (finder.evaluate().isNotEmpty) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $finder to go away.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Vorrat filters by chip, switches to tiles, sorts, opens '
      'a meal and its editor', (tester) async {
    await tester.pumpWidget(_buildHarness());
    await _settle(tester);

    expect(find.byKey(InventoryEntriesSliver.listKey), findsOneWidget);
    expect(find.text('3 LEBENSMITTEL'), findsOneWidget);

    await tester.tap(
      find.byKey(InventoryQuickFilterChips.chipKey(InventoryQuickFilter.low)),
    );
    await _settle(tester);
    expect(find.byKey(const ValueKey('inventory_entry_row_quark')), findsOne);
    expect(
      find.byKey(const ValueKey('inventory_entry_row_skyr')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        InventoryQuickFilterChips.chipKey(InventoryQuickFilter.planned),
      ),
    );
    await _settle(tester);
    expect(find.byKey(const ValueKey('inventory_entry_row_skyr')), findsOne);
    expect(
      find.byKey(const ValueKey('inventory_entry_row_quark')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('inventory_entry_row_chili')), findsOne);

    await tester.tap(
      find.byKey(InventoryQuickFilterChips.chipKey(InventoryQuickFilter.all)),
    );
    await tester.tap(find.byKey(const Key('inventory_list_view_mode_button')));
    await _settle(tester);
    expect(find.byKey(InventoryEntriesSliver.tilesKey), findsOneWidget);
    final skyrBar = tester.widget<GraphitStockBar>(
      find.descendant(
        of: find.byKey(const ValueKey('inventory_entry_tile_skyr')),
        matching: find.byType(GraphitStockBar),
      ),
    );
    expect(skyrBar.plannedShare, 0.25);

    await tester.tap(find.byKey(const Key('inventory_list_view_mode_button')));
    await tester.tap(find.byKey(const Key('inventory_list_sort_button')));
    await _settle(tester);
    await tester.tap(
      find.byKey(
        InventorySortSheet.criterionKey(InventorySortCriterion.alphabetical),
      ),
    );
    await _settle(tester);
    Navigator.of(tester.element(find.byType(InventorySortSheet))).pop();
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('inventory_entry_row_chili')));
    await _settle(tester);
    expect(find.byType(EatMealDetailSections), findsOneWidget);
    expect(find.byKey(const ValueKey('eat_meal_missing_Reis')), findsOne);

    await tester.ensureVisible(find.byKey(const Key('eat_meal_action_edit')));
    await tester.tap(find.byKey(const Key('eat_meal_action_edit')));
    await _settle(tester);
    expect(find.byKey(PreparedMealEditPage.saveKey), findsOneWidget);
    expect(
      find.byKey(const Key('prepared_meal_edit_locked_hint')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(PreparedMealEditPage.saveKey));
    // The editor closes with its route animation, which can take longer than
    // one settle on a slow runner.
    await _pumpUntilAbsent(tester, find.byKey(PreparedMealEditPage.saveKey));
    await _settle(tester);
    // The save message shows on the meal page, not on the hidden list.
    expect(find.byType(EatMealDetailSections), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppSnackBarView),
        matching: find.byType(Text),
      ),
      findsWidgets,
    );

    expect(tester.takeException(), isNull);
  });
}
