import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_date_utils.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/home/widgets/home_context_fab.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../calories/support/fake_calories_repositories.dart';

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository(this.items);

  final List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield items;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return items;
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

class _FakePreparedMealRepository implements PreparedMealRepository {
  _FakePreparedMealRepository(this.meals);

  final List<PreparedMeal> meals;

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    yield meals;
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    return meals;
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async => true;
}

class _LoadingInventoryItemsController extends InventoryItemsController {
  @override
  FutureOr<List<InventoryItem>> build() {
    return Completer<List<InventoryItem>>().future;
  }
}

class _LoadingPreparedMealsController extends PreparedMealsController {
  @override
  FutureOr<List<PreparedMeal>> build() {
    return Completer<List<PreparedMeal>>().future;
  }
}

InventoryItem _inventoryItem(String id) {
  return InventoryItem.create(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-04-01T08:00:00Z'),
    storeName: 'Store',
    quantity: 1,
  );
}

PreparedMeal _preparedMeal(String id) {
  final now = DateTime.parse('2026-04-01T08:00:00Z');
  return PreparedMeal(
    id: id,
    name: 'Soup',
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 30,
    totalFat: 10,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
  );
}

CalorieWeekOverview _weekOverview(DateTime selectedDay) {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final balanceStartDate = normalizedSelectedDay.subtract(
    const Duration(days: 6),
  );
  final days = [
    for (var offset = 0; offset < 7; offset += 1)
      CalorieWeekDayOverview(
        date: balanceStartDate.add(Duration(days: offset)),
        totalKcal: 0,
        goalKcal: 2000,
        entryCount: 0,
      ),
  ];

  return CalorieWeekOverview(
    days: days,
    totalConsumedKcal: 0,
    totalGoalKcal: 14000,
    remainingKcal: 14000,
    balanceStartDate: balanceStartDate,
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: 2000,
    goalStartsInFuture: false,
    nextGoalStartDate: null,
    futureGoalKcal: null,
  );
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
Widget _buildHarness({
  required FakeCalorieSettingsRepository settingsRepository,
  String initialLocation = AppRoutes.homeCalories,
  InventoryItemRepository? inventoryRepository,
  PreparedMealRepository? preparedMealRepository,
  InventoryItemsController? inventoryItemsController,
  PreparedMealsController? preparedMealsController,
}) {
  final today = normalizeDiaryDay(DateTime.now());
  final router = GoRouter(
    initialLocation: initialLocation,
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
                builder: (context, state) => const SizedBox(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeCalories,
                builder: (context, state) => const SizedBox(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeStatistics,
                builder: (context, state) => const SizedBox(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeSettings,
                builder: (context, state) => const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      calorieWeekOverviewForWindowProvider(today).overrideWith(
        (ref) => _weekOverview(today),
      ),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      burnWeekLiveSyncProvider.overrideWith((ref) => null),
      householdDataOwnerUserIdProvider.overrideWith((ref) => 'user-1'),
      inventoryItemRepositoryProvider.overrideWithValue(
        inventoryRepository ??
            _FakeInventoryItemRepository(const <InventoryItem>[]),
      ),
      if (inventoryItemsController != null)
        inventoryItemsControllerProvider.overrideWith(
          () => inventoryItemsController,
        ),
      preparedMealRepositoryProvider.overrideWithValue(
        preparedMealRepository ??
            _FakePreparedMealRepository(const <PreparedMeal>[]),
      ),
      if (preparedMealsController != null)
        preparedMealsControllerProvider.overrideWith(
          () => preparedMealsController,
        ),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
void main() {
  testWidgets('diary tab does not show the context fab', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await tester.pumpAndSettle();

    expect(find.byType(HomeContextFab), findsNothing);
  });

  testWidgets('diary tab shows selected day metadata in the shell bar', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final today = normalizeDiaryDay(DateTime.now());

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text(formatDiaryHeaderDate(today, 'en')), findsOneWidget);
    expect(find.text('Week 1 day 7'), findsOneWidget);
  });

  testWidgets('inventory tab hides shell fab when inventory is empty', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InventoryActionFab), findsNothing);
    expect(find.byType(HomeContextFab), findsNothing);
  });

  testWidgets('inventory tab hides shell fab while inventory is loading', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryItemsController: _LoadingInventoryItemsController(),
        preparedMealsController: _LoadingPreparedMealsController(),
      ),
    );
    await tester.pump();

    expect(find.byType(InventoryActionFab), findsNothing);
    expect(find.byType(HomeContextFab), findsNothing);
  });

  testWidgets('inventory tab shows shell fab when inventory and meals exist', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        preparedMealRepository: _FakePreparedMealRepository(<PreparedMeal>[
          _preparedMeal('meal-1'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InventoryActionFab), findsOneWidget);
    expect(find.byType(HomeContextFab), findsNothing);
  });

  testWidgets('inventory tab shows shell fab when only inventory items exist', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InventoryActionFab), findsOneWidget);
    expect(find.byType(HomeContextFab), findsNothing);
  });

  testWidgets('inventory tab shows shell fab when only prepared meals exist', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        preparedMealRepository: _FakePreparedMealRepository(<PreparedMeal>[
          _preparedMeal('meal-1'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InventoryActionFab), findsOneWidget);
    expect(find.byType(HomeContextFab), findsNothing);
  });

  testWidgets(
    'inventory selection chrome compacts on small zoomed layouts',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          settingsRepository: repository,
          initialLocation: AppRoutes.homeInventory,
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
      );
      container.read(preparedMealSelectionControllerProvider.notifier)
        ..enterSelection('item-1')
        ..toggleSelection('item-2');
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Bind meal'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bottom nav keeps labels on wider layouts with larger text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.25;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          settingsRepository: repository,
          initialLocation: AppRoutes.homeInventory,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INVENTORY'), findsOneWidget);
      expect(find.text('DIARY'), findsOneWidget);
      expect(find.text('BURN'), findsNothing);
      expect(find.text('STATISTICS'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
