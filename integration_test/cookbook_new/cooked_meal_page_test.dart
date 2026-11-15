import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_page.dart';
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_save_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_cookbook_switch.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_header.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_pot_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_save_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_summary.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_discard_dialog.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/inventory_item_whole_list_writes.dart';
import '../../test/helpers/soft_keyboard_test_utils.dart';

const _startKey = ValueKey<String>('start-cooked-meal');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saves a combined meal with its pot and weight', (tester) async {
    final meals = _FakeMealRepository()..saved = [_combinedMeal()];
    final screenSwitches = <bool>[];
    final wakeLock = ScreenWakeLock(
      toggle: ({required on}) async => screenSwitches.add(on),
    );
    await tester.pumpWidget(_app(meals: meals, wakeLock: wakeLock));
    await tester.pumpAndSettle();
    await _openCooked(tester, 'combo');
    expect(screenSwitches, [true]);

    // The cookbook switch starts off.
    await _showCookbookSwitch(tester);
    expect(_cookbookSwitch(tester).value, isFalse);

    await tester.ensureVisible(find.byKey(CookedMealPotSection.weighKey));
    await tester.tap(find.byKey(CookedMealPotSection.weighKey));
    await tester.pumpAndSettle();
    // A weight without the pot cannot be saved.
    await tester.enterText(find.byKey(CookedMealPotSection.grossKey), '1300');
    await tester.pumpAndSettle();
    expect(_saveButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(CookedMealPotSection.morePortionsKey));
    await tester.tap(find.byKey(CookedMealPotSection.utensilKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CookedMealPotSection.utensilOptionKey('pot')).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookedMealSaveBar.saveKey));
    await tester.pumpAndSettle();

    expect(find.byKey(_startKey), findsOneWidget);
    expect(screenSwitches, [true, false]);
    // The page's own save is no news from another device.
    expect(find.byKey(CookedMealPage.doneElsewhereKey), findsNothing);
    final cooked = meals.saved.single;
    expect(cooked.isInPot, isFalse);
    expect(cooked.totalPortions, 2);
    expect(cooked.potTareWeight, 400);
    expect(cooked.finalNetWeight, 900);
  });

  testWidgets('"Ins Kochbuch" also saves the meal as a template', (
    tester,
  ) async {
    final meals = _FakeMealRepository()..saved = [_combinedMeal()];
    final templates = _FakeTemplateRepository();
    await tester.pumpWidget(_app(meals: meals, templates: templates));
    await tester.pumpAndSettle();
    await _openCooked(tester, 'combo');

    // The page renames the meal. The keyboard closes first, because while it
    // opens it moves the switch that the next tap aims at.
    await tester.enterText(find.byKey(CookedMealSummary.nameKey), 'Reisschale');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await waitForKeyboardClosed(tester);
    await tester.pumpAndSettle();
    await _showCookbookSwitch(tester);
    await tester.tap(find.byKey(CookedMealCookbookSwitch.switchKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookedMealSaveBar.saveKey));
    await tester.pumpAndSettle();

    expect(find.byKey(_startKey), findsOneWidget);
    final cooked = meals.saved.single;
    expect(cooked.isInPot, isFalse);
    expect(cooked.name, 'Reisschale');
    final template = templates.saved.single;
    expect(template.id, isNot(cooked.id));
    expect(template.name, 'Reisschale');
    expect(template.components.map((c) => c.inventoryItemId), ['rice', 'rice']);
    expect(template.remainingPortions, template.totalPortions);
  });

  testWidgets('a failed template keeps the meal in the Vorrat and says so', (
    tester,
  ) async {
    final meals = _FakeMealRepository()..saved = [_combinedMeal()];
    await tester.pumpWidget(
      _app(meals: meals, templates: _FakeTemplateRepository(fails: true)),
    );
    await tester.pumpAndSettle();
    await _openCooked(tester, 'combo');

    await _showCookbookSwitch(tester);
    await tester.tap(find.byKey(CookedMealCookbookSwitch.switchKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookedMealSaveBar.saveKey));
    await tester.pumpAndSettle();

    expect(find.byKey(_startKey), findsOneWidget);
    expect(meals.saved.single.isInPot, isFalse);
    expect(find.byKey(CookedMealSaveFlow.cookbookFailedKey), findsOneWidget);
  });

  testWidgets('counts the meal in pieces without weighing it', (tester) async {
    final meals = _FakeMealRepository()..saved = [_combinedMeal()];
    await tester.pumpWidget(_app(meals: meals));
    await tester.pumpAndSettle();
    await _openCooked(tester, 'combo');

    await tester.tap(
      find.byKey(CookedMealPotSection.servingKey(inPieces: true)),
    );
    await tester.pumpAndSettle();
    // Pieces need no pot and no scale.
    expect(find.byKey(CookedMealPotSection.weighKey), findsNothing);
    expect(find.byKey(CookedMealPotSection.utensilKey), findsNothing);
    expect(find.byKey(CookedMealPotSection.grossKey), findsNothing);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(CookedMealPotSection.morePortionsKey));
      await tester.pump();
    }
    await tester.tap(find.byKey(CookedMealSaveBar.saveKey));
    await tester.pumpAndSettle();

    final cooked = meals.saved.single;
    expect(cooked.isInPot, isFalse);
    expect(cooked.isServedInPieces, isTrue);
    expect(cooked.totalPortions, 6);
    expect(cooked.finalNetWeight, isNull);
    expect(cooked.potTareWeight, isNull);
  });

  testWidgets('a combined meal takes its weight from the ingredients', (
    tester,
  ) async {
    final meals = _FakeMealRepository()..saved = [_combinedMeal()];
    await tester.pumpWidget(_app(meals: meals));
    await tester.pumpAndSettle();
    await _openCooked(tester, 'combo');

    // The sum of the ingredients replaces the scale.
    expect(find.byKey(CookedMealPotSection.weighKey), findsOneWidget);
    expect(find.byKey(CookedMealPotSection.utensilKey), findsNothing);
    expect(find.byKey(CookedMealPotSection.grossKey), findsNothing);
    await tester.tap(find.byKey(CookedMealPotSection.morePortionsKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookedMealSaveBar.saveKey));
    await tester.pumpAndSettle();

    final meal = meals.saved.single;
    expect(meal.isInPot, isFalse);
    expect(meal.totalPortions, 2);
    expect(meal.finalNetWeight, 300);
    expect(meal.potTareWeight, isNull);
  });

  testWidgets('a meal from a template in pieces starts on pieces', (
    tester,
  ) async {
    final meals = _FakeMealRepository()
      ..saved = [_combinedMeal().copyWith(servedInPieces: true)];
    await tester.pumpWidget(_app(meals: meals));
    await tester.pumpAndSettle();
    await _openCooked(tester, 'combo');

    // Pieces need no weight, so neither the sum nor the scale shows.
    expect(find.byKey(CookedMealPotSection.weighKey), findsNothing);
    expect(find.byKey(CookedMealPotSection.utensilKey), findsNothing);
    await tester.tap(find.byKey(CookedMealSaveBar.saveKey));
    await tester.pumpAndSettle();

    final meal = meals.saved.single;
    expect(meal.isInPot, isFalse);
    expect(meal.isServedInPieces, isTrue);
    expect(meal.finalNetWeight, isNull);
  });

  testWidgets('an untouched name keeps a rename made meanwhile (#835)', (
    tester,
  ) async {
    final meals = _FakeMealRepository()
      ..saved = [_combinedMeal().copyWith(servedInPieces: true)];
    await tester.pumpWidget(_app(meals: meals));
    await tester.pumpAndSettle();
    await _openCooked(tester, 'combo');

    // Another device or the detail page renames the meal.
    await meals.save(meals.saved.single.copyWith(name: 'Reisbrei'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookedMealSaveBar.saveKey));
    await tester.pumpAndSettle();

    expect(meals.saved.single.isInPot, isFalse);
    expect(meals.saved.single.name, 'Reisbrei');
  });

  testWidgets('weighing a combined meal shows the container and the scale', (
    tester,
  ) async {
    final meals = _FakeMealRepository()..saved = [_combinedMeal()];
    await tester.pumpWidget(_app(meals: meals));
    await tester.pumpAndSettle();
    await _openCooked(tester, 'combo');

    await tester.ensureVisible(find.byKey(CookedMealPotSection.weighKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookedMealPotSection.weighKey));
    await tester.pumpAndSettle();

    expect(find.byKey(CookedMealPotSection.weighKey), findsNothing);
    expect(find.byKey(CookedMealPotSection.utensilKey), findsOneWidget);
    expect(find.byKey(CookedMealPotSection.grossKey), findsOneWidget);
  });

  testWidgets(
    '"Verwerfen" asks and gives the foods back to the Vorrat (#862)',
    (tester) async {
      final meals = _FakeMealRepository()..saved = [_combinedMeal()];
      final inventory = _riceInventory();
      await tester.pumpWidget(_app(meals: meals, inventory: inventory));
      await tester.pumpAndSettle();
      await _openCooked(tester, 'combo');
      expect(inventory.items.single.currentAmount, 700);

      // Cancelling keeps the meal.
      await tester.tap(find.byKey(CookedMealSaveBar.discardKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(meals.saved, hasLength(1));
      expect(find.byType(CookedMealPage), findsOneWidget);

      await tester.tap(find.byKey(CookedMealSaveBar.discardKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(cookingDiscardKey));
      await tester.pumpAndSettle();

      expect(meals.saved, isEmpty);
      expect(inventory.items.single.currentAmount, 1000);
      expect(find.byKey(_startKey), findsOneWidget);
    },
  );

  testWidgets('closing a combined meal asks and gives it back', (tester) async {
    final meals = _FakeMealRepository()..saved = [_combinedMeal()];
    await tester.pumpWidget(_app(meals: meals));
    await tester.pumpAndSettle();
    await _openCooked(tester, 'combo');

    await tester.tap(find.byKey(CookedMealHeader.closeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(cookingDiscardKey));
    await tester.pumpAndSettle();

    expect(meals.saved, isEmpty);
    expect(find.byKey(_startKey), findsOneWidget);
  });

  testWidgets('fits under the keyboard and keeps the save bar in reach', (
    tester,
  ) async {
    final meals = _FakeMealRepository()..saved = [_combinedMeal()];
    await tester.pumpWidget(_app(meals: meals));
    await tester.pumpAndSettle();
    await _openCooked(tester, 'combo');
    await tester.ensureVisible(find.byKey(CookedMealPotSection.weighKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookedMealPotSection.weighKey));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(CookedMealPotSection.grossKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookedMealPotSection.grossKey));
    // A keyboard over most of the screen covers the page instead of
    // squeezing it into an overflow.
    final inset = tester.view.physicalSize.height * 0.6;
    tester.view.viewInsets = FakeViewPadding(bottom: inset);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final visibleBottom =
        (tester.view.physicalSize.height - inset) /
        tester.view.devicePixelRatio;
    expect(
      tester.getBottomLeft(find.byKey(CookedMealSaveBar.saveKey)).dy,
      lessThanOrEqualTo(visibleBottom + 1),
    );
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

/// Opens the "Gekocht" step of the meal [mealId].
Future<void> _openCooked(WidgetTester tester, String mealId) async {
  unawaited(
    GoRouter.of(tester.element(find.byKey(_startKey)))
        .push(AppRoutes.homeCookedMealPath(mealId)),
  );
  await tester.pumpAndSettle();
}

/// Rice and oats combined from the Vorrat, waiting for "Gekocht".
PreparedMeal _combinedMeal() {
  final rice = InventoryItem.create(
    id: 'rice',
    name: 'Reis',
    entryDate: DateTime.utc(2026, 9, 29),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 1000,
    amountUnit: InventoryAmountUnit.gram,
  );
  PreparedMealComponent component(int grams) => PreparedMealComponent(
    inventoryItemId: rice.id,
    name: rice.name,
    brand: rice.brand,
    imageUrl: rice.imageUrl,
    usedAmount: grams,
    usedUnit: InventoryAmountUnit.gram,
    totalKcal: 300,
    totalProtein: 6,
    totalCarbs: 60,
    totalFat: 1,
    sourceItemSnapshot: rice,
  );
  final now = DateTime.utc(2026, 10, 8, 8);
  return PreparedMeal(
    id: 'combo',
    name: 'Reis + Reis',
    totalPortions: 1,
    remainingPortions: 1,
    totalKcal: 600,
    totalProtein: 12,
    totalCarbs: 120,
    totalFat: 2,
    createdAt: now,
    updatedAt: now,
    components: [component(200), component(100)],
    inPot: true,
  );
}

/// Scrolls the "Gekocht" step down to the cookbook switch.
Future<void> _showCookbookSwitch(WidgetTester tester) =>
    tester.scrollUntilVisible(
      find.byKey(CookedMealCookbookSwitch.switchKey),
      200,
      scrollable: find
          .descendant(
            of: find.byType(CookedMealPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );

AppSwitchListTile _cookbookSwitch(WidgetTester tester) => tester
    .widget<AppSwitchListTile>(find.byKey(CookedMealCookbookSwitch.switchKey));

FilledButton _saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(CookedMealSaveBar.saveKey));

Widget _app({
  required _FakeMealRepository meals,
  ScreenWakeLock? wakeLock,
  _FakeTemplateRepository? templates,
  _FakeInventoryRepository? inventory,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
    routes: [
      GoRoute(
        path: AppRoutes.homeInventoryTemplates,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Start', key: _startKey)),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeCookedMeal,
        builder: (context, state) =>
            CookedMealPage(mealId: state.pathParameters['mealId']!),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      preparedMealRepositoryProvider.overrideWithValue(meals),
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        templates ?? _FakeTemplateRepository(),
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        inventory ?? _riceInventory(),
      ),
      inventoryActivityEventRepositoryProvider.overrideWithValue(
        _FakeActivityRepository(),
      ),
      inventoryActivityActorProvider.overrideWithValue(null),
      screenWakeLockProvider.overrideWithValue(
        wakeLock ?? ScreenWakeLock(toggle: ({required on}) async {}),
      ),
      kitchenUtensilRepositoryProvider.overrideWithValue(
        _FakeUtensilRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

/// A Vorrat with 700 g of rice left of 1000 g.
_FakeInventoryRepository _riceInventory() => _FakeInventoryRepository([
  InventoryItem.create(
    id: 'rice',
    name: 'Reis',
    entryDate: DateTime.utc(2026, 9, 29),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 700,
    amountUnit: InventoryAmountUnit.gram,
  ),
]);

class _FakeMealRepository implements PreparedMealRepository {
  final _changes = StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> saved = const [];

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    yield saved;
    yield* _changes.stream;
  }

  @override
  Future<List<PreparedMeal>> readAll() async => saved;

  @override
  Future<bool> save(PreparedMeal meal) => _saveAll([
    for (final stored in saved)
      if (stored.id != meal.id) stored,
    meal,
  ]);

  @override
  Future<bool> delete(String mealId) => _saveAll([
    for (final stored in saved)
      if (stored.id != mealId) stored,
  ]);

  Future<bool> _saveAll(List<PreparedMeal> meals) async {
    saved = meals;
    _changes.add(meals);
    return true;
  }

  @override
  Future<List<PreparedMeal>> readAllForChange() => readAll();
}

class _FakeUtensilRepository implements KitchenUtensilRepository {
  @override
  Stream<List<KitchenUtensil>> watchAll() async* {
    yield [
      KitchenUtensil(
        id: 'pot',
        name: 'Topf',
        weightGrams: 400,
        createdAt: DateTime.utc(2026, 9),
        updatedAt: DateTime.utc(2026, 9),
      ),
    ];
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInventoryRepository with InventoryItemWholeListWrites {
  new(this.items);

  List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(items);

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    this.items = items;
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    this.items = [...this.items, ...items];
    return true;
  }
}

class _FakeActivityRepository implements InventoryActivityEventRepository {
  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) {
    return const Stream.empty();
  }

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async => true;
}

class _FakeTemplateRepository implements PreparedMealTemplateRepository {
  new({this.fails = false});

  final bool fails;
  final saved = <PreparedMeal>[];

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    yield List.of(saved);
  }

  @override
  Future<List<PreparedMeal>> readAll() async => List.of(saved);

  @override
  Future<bool> save(PreparedMeal template) => _replaceAll([
    for (final stored in List.of(saved))
      if (stored.id != template.id) stored,
    template,
  ]);

  @override
  Future<bool> update(
    String id,
    PreparedMeal? Function(PreparedMeal current) change,
  ) async => false;

  @override
  Future<bool> delete(String templateId) => _replaceAll([
    for (final stored in List.of(saved))
      if (stored.id != templateId) stored,
  ]);

  Future<bool> _replaceAll(List<PreparedMeal> templates) async {
    if (fails) {
      return false;
    }
    saved
      ..clear()
      ..addAll(templates);
    return true;
  }
}
