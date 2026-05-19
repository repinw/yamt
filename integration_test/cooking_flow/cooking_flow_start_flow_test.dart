import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_controller.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_controller.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/cooking_flow_page.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/provider/'
    'kitchen_utensils_controller.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_templates_page.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/'
    'receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _CookingFlowStartHarness {
  const _CookingFlowStartHarness({
    required this.app,
    required this.sessionStore,
  });

  final Widget app;
  final _FakeCookingFlowSessionLocalStore sessionStore;
}

class _FakeCookingFlowSessionLocalStore
    implements CookingFlowSessionLocalStore {
  CookingFlowSession? savedSession;

  @override
  Future<CookingFlowSession?> load() async {
    return savedSession;
  }

  @override
  Future<bool> save(CookingFlowSession session) async {
    savedSession = session;
    return true;
  }

  @override
  Future<bool> clear() async {
    savedSession = null;
    return true;
  }
}

class _StaticPreparedMealTemplatesController
    extends PreparedMealTemplatesController {
  _StaticPreparedMealTemplatesController(this._templates);

  final List<PreparedMeal> _templates;

  @override
  FutureOr<List<PreparedMeal>> build() {
    return List<PreparedMeal>.from(_templates);
  }
}

class _StaticInventoryItemsController extends InventoryItemsController {
  _StaticInventoryItemsController(this._items);

  final List<InventoryItem> _items;

  @override
  FutureOr<List<InventoryItem>> build() {
    return List<InventoryItem>.from(_items);
  }
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  const _FakeInventoryItemRepository(this._items);

  final List<InventoryItem> _items;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.value(_items);
  }
}

class _NoopPreparedMealsController extends PreparedMealsController {
  @override
  FutureOr<List<PreparedMeal>> build() {
    return const <PreparedMeal>[];
  }
}

class _StaticKitchenUtensilsController extends KitchenUtensilsController {
  @override
  FutureOr<List<KitchenUtensil>> build() {
    return const <KitchenUtensil>[];
  }
}

@Dependencies([
  CookingFlowController,
  CookingFlowWizardController,
  InventoryItemsController,
  PreparedMealsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
_CookingFlowStartHarness _buildHarness() {
  final sessionStore = _FakeCookingFlowSessionLocalStore();
  final templates = <PreparedMeal>[_recipeTemplate()];
  final inventoryItems = <InventoryItem>[
    _inventoryItem(id: 'pasta', name: 'Pasta', amount: 500),
    _inventoryItem(id: 'tomato-sauce', name: 'Tomato sauce', amount: 300),
  ];

  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomePage(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeInventory,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Inventory')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeDiary,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Diary')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeInventoryTemplates,
                builder: (context, state) {
                  return const MealTemplatesPage(includeAppBar: false);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeStatistics,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Statistics')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeSettings,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Settings')),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.homeInventoryTemplateDetail,
        builder: (context, state) {
          return CookingFlowPage(
            templateId: state.pathParameters['templateId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeKitchenUtensils,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Kitchen utensils')),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeShopping,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Shopping list')),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      cookingFlowSessionLocalStoreProvider.overrideWithValue(sessionStore),
      preparedMealTemplatesControllerProvider.overrideWith(
        () => _StaticPreparedMealTemplatesController(templates),
      ),
      inventoryItemsControllerProvider.overrideWith(
        () => _StaticInventoryItemsController(inventoryItems),
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        _FakeInventoryItemRepository(inventoryItems),
      ),
      preparedMealsControllerProvider.overrideWith(
        _NoopPreparedMealsController.new,
      ),
      cookingFlowControllerProvider.overrideWith(CookingFlowController.new),
      kitchenUtensilsControllerProvider.overrideWith(
        _StaticKitchenUtensilsController.new,
      ),
    ],
  );
  addTearDown(container.dispose);

  return _CookingFlowStartHarness(
    sessionStore: sessionStore,
    app: UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
}

PreparedMeal _recipeTemplate() {
  return PreparedMeal(
    id: 'template-1',
    name: 'One-pan pasta',
    recipeIngredients: const <String>[
      '200g Pasta',
      '150g Tomato sauce',
    ],
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 700,
    totalProtein: 24,
    totalCarbs: 110,
    totalFat: 18,
    createdAt: DateTime.parse('2026-05-01T12:00:00Z'),
    updatedAt: DateTime.parse('2026-05-01T12:00:00Z'),
    components: const <PreparedMealComponent>[],
  );
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  required int amount,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-05-01T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: amount,
    currentAmount: amount,
    amountUnit: InventoryAmountUnit.gram,
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required String description,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final end = tester.binding.clock.fromNowBy(timeout);
  while (finder.evaluate().isEmpty) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $description.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntilAbsent(
  WidgetTester tester,
  Finder finder, {
  required String description,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final end = tester.binding.clock.fromNowBy(timeout);
  while (finder.evaluate().isNotEmpty) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $description.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntilOnScreen(
  WidgetTester tester,
  Finder finder, {
  required String description,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final end = tester.binding.clock.fromNowBy(timeout);
  while (!_isFinderCenterOnScreen(tester, finder)) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $description.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

bool _isFinderCenterOnScreen(WidgetTester tester, Finder finder) {
  if (finder.evaluate().isEmpty) {
    return false;
  }

  final center = tester.getCenter(finder.first);
  final viewSize = tester.view.physicalSize / tester.view.devicePixelRatio;
  return center.dx >= 0 &&
      center.dy >= 0 &&
      center.dx <= viewSize.width &&
      center.dy <= viewSize.height;
}

Future<void> _assignInventoryIngredient({
  required WidgetTester tester,
  required Finder assignButton,
  required String itemName,
}) async {
  await tester.ensureVisible(assignButton);
  await _pumpUntilOnScreen(
    tester,
    assignButton,
    description: '$itemName assign action',
  );
  await tester.tap(assignButton);
  await tester.pump();

  await _pumpUntilFound(
    tester,
    find.byType(BottomSheet),
    description: 'inventory assignment menu',
  );
  await tester.pumpAndSettle();

  final itemText = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.text(itemName),
  );
  await _pumpUntilFound(
    tester,
    itemText,
    description: '$itemName assignment option',
  );
  await tester.pumpAndSettle();

  final tile = find.ancestor(
    of: itemText,
    matching: find.byType(AppCheckboxListTile),
  );
  expect(tile, findsOneWidget);
  await _pumpUntilOnScreen(
    tester,
    tile,
    description: '$itemName assignment tile',
  );

  await tester.tap(tile);
  await tester.pumpAndSettle();

  final selectButton = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.text('Select'),
  );
  await _pumpUntilFound(
    tester,
    selectButton,
    description: 'inventory assignment select action',
  );
  await tester.pumpAndSettle();
  await _pumpUntilOnScreen(
    tester,
    selectButton,
    description: 'inventory assignment select action',
  );
  await tester.tap(selectButton);
  await tester.pumpAndSettle();
  await _pumpUntilAbsent(
    tester,
    find.byType(BottomSheet),
    description: 'inventory assignment menu to close',
  );
}

@Dependencies([
  CookingFlowController,
  CookingFlowWizardController,
  InventoryItemsController,
  PreparedMealsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts cookflow from added recipe after assigning ingredients', (
    tester,
  ) async {
    final harness = _buildHarness();

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('One-pan pasta'));
    await tester.pumpAndSettle();

    expect(find.text('Start cooking session'), findsOneWidget);
    expect(find.text('Inventory check'), findsOneWidget);

    await _assignInventoryIngredient(
      tester: tester,
      assignButton: find.byTooltip('Assign').first,
      itemName: 'Pasta',
    );
    await _assignInventoryIngredient(
      tester: tester,
      assignButton: find.byTooltip('Assign').last,
      itemName: 'Tomato sauce',
    );

    await _pumpUntilFound(
      tester,
      find.text('Start flow'),
      description: 'enabled start flow action',
    );
    await tester.tap(find.text('Start flow'));
    await tester.pumpAndSettle();

    expect(find.text('1. Preparation'), findsOneWidget);
    expect(find.text('Start cooking session'), findsNothing);
    expect(
      harness.sessionStore.savedSession?.step,
      CookingFlowSessionStep.preparation,
    );
    expect(
      harness.sessionStore.savedSession?.introDraft.rowStates
          .map((row) => row.selections.map((item) => item.itemId).toList())
          .toList(),
      <List<String>>[
        <String>['pasta'],
        <String>['tomato-sauce'],
      ],
    );
  });
}
