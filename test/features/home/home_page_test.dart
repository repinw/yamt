import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/provider/diary_calendar_controller.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/home/widgets/home_context_fab.dart';
import 'package:yamt/features/home/widgets/home_heart_counter_button.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome.dart';
import 'package:yamt/features/home/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
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

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  _FakeBurnWeekRunStateRepository(this.state);

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    this.state = state;
    return true;
  }
}

class _TestDiaryCalendarController extends DiaryCalendarController {
  _TestDiaryCalendarController(this.selectedDay);

  final DateTime selectedDay;

  @override
  DiaryCalendarState build() {
    final today = normalizeDiaryDay(DateTime.now());
    return DiaryCalendarState(
      today: today,
      selectedDay: normalizeDiaryDay(selectedDay),
      todayRequest: 0,
    );
  }
}

class _RecordingReceiptCaptureFlowController
    extends ReceiptCaptureFlowController {
  int _runCallCount = 0;
  ReceiptInputSource? _lastSource;

  int recordedRunCallCount() => _runCallCount;

  ReceiptInputSource? recordedLastSource() => _lastSource;

  @override
  FutureOr<ReceiptCaptureFlowResult?> build() {
    return null;
  }

  @override
  Future<ReceiptCaptureFlowResult> run({
    required ReceiptInputSource source,
  }) async {
    _runCallCount += 1;
    _lastSource = source;
    return ReceiptCaptureFlowResult.inputCanceled(source: source);
  }
}

class _RecordingReceiptBatchFlowController extends ReceiptBatchFlowController {
  int _runFileBatchCallCount = 0;

  int recordedRunFileBatchCallCount() => _runFileBatchCallCount;

  @override
  ReceiptBatchFlowState build() {
    return const ReceiptBatchFlowState();
  }

  @override
  Future<void> runFileBatch() async {
    _runFileBatchCallCount += 1;
    state = const ReceiptBatchFlowState(
      status: ReceiptBatchFlowStatus.inputCanceled,
    );
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

Widget _defaultBranchBody(HomeTabType tab) {
  return CustomScrollView(
    slivers: [
      HomeShellTabTopChrome(tab: tab),
      const SliverFillRemaining(
        hasScrollBody: false,
        child: SizedBox(),
      ),
    ],
  );
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
Widget _buildHarness({
  required FakeCalorieSettingsRepository settingsRepository,
  String initialLocation = AppRoutes.homeCalories,
  Widget? branchBody,
  InventoryItemRepository? inventoryRepository,
  PreparedMealRepository? preparedMealRepository,
  InventoryItemsController? inventoryItemsController,
  PreparedMealsController? preparedMealsController,
  ReceiptCaptureFlowController? receiptCaptureFlowController,
  ReceiptBatchFlowController? receiptBatchFlowController,
  BurnWeekRunStateRepository? burnWeekRunStateRepository,
  DateTime? selectedDiaryDay,
  bool? isCameraSupported,
  ThemeData? theme,
  ValueChanged<Object?>? onManualAddRouteExtra,
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
                builder: (context, state) =>
                    branchBody ?? _defaultBranchBody(HomeTabType.inventory),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeCalories,
                builder: (context, state) =>
                    branchBody ?? _defaultBranchBody(HomeTabType.diary),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeInventoryTemplates,
                builder: (context, state) =>
                    branchBody ?? _defaultBranchBody(HomeTabType.cookbook),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeStatistics,
                builder: (context, state) =>
                    branchBody ?? _defaultBranchBody(HomeTabType.statistics),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeSettings,
                builder: (context, state) =>
                    branchBody ?? _defaultBranchBody(HomeTabType.settings),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.homeInventoryManualAdd,
        builder: (context, state) {
          onManualAddRouteExtra?.call(state.extra);
          return const SizedBox();
        },
      ),
    ],
  );

  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        burnWeekRunStateRepository ??
            _FakeBurnWeekRunStateRepository(
              const BurnWeekRunState.initial(),
            ),
      ),
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
      if (receiptCaptureFlowController != null)
        receiptCaptureFlowControllerProvider.overrideWith(
          () => receiptCaptureFlowController,
        ),
      if (receiptBatchFlowController != null)
        receiptBatchFlowControllerProvider.overrideWith(
          () => receiptBatchFlowController,
        ),
      if (selectedDiaryDay != null)
        diaryCalendarControllerProvider.overrideWith(
          () => _TestDiaryCalendarController(selectedDiaryDay),
        ),
      if (isCameraSupported != null)
        receiptCameraSupportedProvider.overrideWith(
          (ref) => isCameraSupported,
        ),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      theme: theme,
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
  receiptCameraSupported,
])
void main() {
  testWidgets('diary tab does not show the context fab', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await tester.pumpAndSettle();

    expect(find.byType(HomeContextFab), findsNothing);
  });

  testWidgets('diary tab shows selected day date in the shell bar', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final today = normalizeDiaryDay(DateTime.now());

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text(formatCalendarHeaderDate(today, 'en')), findsOneWidget);
    expect(find.text('Week 1 day 7'), findsNothing);
  });

  testWidgets('home shell chrome collapses on scroll down and returns upward', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: Builder(
          builder: (context) {
            return CustomScrollView(
              slivers: [
                const HomeShellTabTopChrome(tab: HomeTabType.diary),
                SliverList.builder(
                  itemCount: 40,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      height: 72,
                      child: Text('Row $index'),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    double chromeOpacity(Type chromeType) {
      return tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(chromeType),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
    }

    final initialTopOffset = tester.getTopLeft(find.byType(HomeTopBar)).dy;
    final initialBottomOpacity = chromeOpacity(HomeShellBottomChrome);

    await tester.drag(find.text('Row 5'), const Offset(0, -48));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final shiftedTopOffset = tester.getTopLeft(find.byType(HomeTopBar)).dy;

    await tester.drag(find.text('Row 5'), const Offset(0, -172));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final collapsedBottomOpacity = chromeOpacity(HomeShellBottomChrome);

    expect(shiftedTopOffset, lessThan(initialTopOffset));
    expect(find.byType(HomeTopBar), findsNothing);
    expect(collapsedBottomOpacity, lessThan(initialBottomOpacity));

    await tester.drag(find.text('Row 8'), const Offset(0, 240));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(HomeTopBar), findsOneWidget);
    final revealedTopOffset = tester.getTopLeft(find.byType(HomeTopBar)).dy;
    final revealedBottomOpacity = chromeOpacity(HomeShellBottomChrome);

    expect(revealedTopOffset, greaterThan(shiftedTopOffset));
    expect(revealedBottomOpacity, greaterThan(collapsedBottomOpacity));
    expect(revealedBottomOpacity - collapsedBottomOpacity, greaterThan(0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('diary shell bar grows for very large accessibility text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await tester.pumpAndSettle();

    final topBar = tester.widget<HomeTopBar>(find.byType(HomeTopBar));
    expect(topBar.preferredSize.height, greaterThan(96));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides heart counter during learning week', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await tester.pumpAndSettle();

    expect(find.byType(HomeHeartCounterButton), findsNothing);
    expect(find.text('x 1'), findsNothing);
  });

  testWidgets('hides heart counter on inventory tab after learning week', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial().copyWith(
        runWeekNumber: burnWeekFirstGameRunWeekNumber,
        heartCount: 2,
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        burnWeekRunStateRepository: runStateRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeHeartCounterButton), findsNothing);
    expect(find.text('x 2'), findsNothing);
  });

  testWidgets('heart counter spends heart on selected old diary day', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final oldDay = normalizeDiaryDay(
      DateTime.now().subtract(const Duration(days: 3)),
    );
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(
          startOfCalendarWeek(oldDay),
        ),
        runWeekNumber: burnWeekFirstGameRunWeekNumber,
        heartCount: 1,
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        burnWeekRunStateRepository: runStateRepository,
        selectedDiaryDay: oldDay,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(HomeHeartCounterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use heart'));
    await tester.pumpAndSettle();

    expect(runStateRepository.state.heartCount, 0);
    expect(runStateRepository.state.heartDayKeys, <String>[
      diaryDayKey(oldDay),
    ]);
  });

  testWidgets('heart counter blocks practice days before run starts', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final selectedDay = normalizeDiaryDay(DateTime.now());
    final futureStartDay = addDiaryDays(selectedDay, 3);
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(futureStartDay),
        runWeekNumber: burnWeekFirstGameRunWeekNumber,
        heartCount: 1,
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        burnWeekRunStateRepository: runStateRepository,
        selectedDiaryDay: selectedDay,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(HomeHeartCounterButton));
    await tester.pumpAndSettle();

    expect(find.text('Use heart day?'), findsNothing);
    expect(runStateRepository.state.heartCount, 1);
    expect(runStateRepository.state.heartDayKeys, isEmpty);
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
    final scaffoldFinder = find.ancestor(
      of: find.byType(InventoryActionFab),
      matching: find.byType(Scaffold),
    );
    final scaffold = tester.widget<Scaffold>(scaffoldFinder.first);
    expect(
      scaffold.floatingActionButtonAnimator,
      FloatingActionButtonAnimator.noAnimation,
    );
  });

  testWidgets('inventory fab follows the bottom chrome while scrolling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        branchBody: CustomScrollView(
          slivers: [
            const HomeShellTabTopChrome(tab: HomeTabType.inventory),
            SliverList.builder(
              itemCount: 40,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 72,
                  child: Text('Row $index'),
                );
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialFabTop = tester.getTopLeft(find.byType(InventoryActionFab)).dy;

    await tester.drag(find.text('Row 5'), const Offset(0, -220));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final collapsedFabTop = tester
        .getTopLeft(
          find.byType(InventoryActionFab),
        )
        .dy;

    expect(collapsedFabTop, greaterThan(initialFabTop));

    await tester.drag(find.text('Row 8'), const Offset(0, 240));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final revealedFabTop = tester
        .getTopLeft(find.byType(InventoryActionFab))
        .dy;

    expect(revealedFabTop, lessThan(collapsedFabTop));
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory fab disappears immediately after leaving inventory', (
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

    await tester.tap(find.text('DIARY'));
    await tester.pump();

    expect(find.byType(InventoryActionFab), findsNothing);
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

  testWidgets('inventory snackbar lays out with inventory fab', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(384, 832));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        theme: ThemeData(
          useMaterial3: true,
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final homeContext = tester.element(find.byType(HomePage));
    ScaffoldMessenger.of(homeContext).showSnackBar(
      const SnackBar(content: Text('Saved')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory shell fab opens requested add actions', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    Object? manualAddRouteExtra;

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        onManualAddRouteExtra: (extra) => manualAddRouteExtra = extra,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Manual search'), findsOneWidget);
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('AI suggestion'), findsOneWidget);
    expect(find.text('Upload image/PDF'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);

    await tester.tap(find.text('Manual search'));
    await tester.pumpAndSettle();

    expect(
      manualAddRouteExtra,
      InventoryManualAddInitialAction.manualSearch,
    );
  });

  testWidgets('inventory shell fab opens ai suggestion route', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    Object? manualAddRouteExtra;

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        onManualAddRouteExtra: (extra) => manualAddRouteExtra = extra,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI suggestion'));
    await tester.pumpAndSettle();

    expect(
      manualAddRouteExtra,
      InventoryManualAddInitialAction.aiSuggestion,
    );
  });

  testWidgets('inventory shell fab starts upload flow', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final batchController = _RecordingReceiptBatchFlowController();

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        receiptBatchFlowController: batchController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload image/PDF'));
    await tester.pumpAndSettle();

    expect(batchController.recordedRunFileBatchCallCount(), 1);
  });

  testWidgets('inventory shell fab starts camera flow when enabled', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final captureController = _RecordingReceiptCaptureFlowController();

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        receiptCaptureFlowController: captureController,
        isCameraSupported: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(captureController.recordedRunCallCount(), 1);
    expect(captureController.recordedLastSource(), ReceiptInputSource.camera);
  });

  testWidgets('inventory shell fab disables camera when unsupported', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final captureController = _RecordingReceiptCaptureFlowController();

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        receiptCaptureFlowController: captureController,
        isCameraSupported: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(captureController.recordedRunCallCount(), 0);
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
      expect(find.text('COOKBOOK'), findsOneWidget);
      expect(
        tester.getCenter(find.text('DIARY')).dx,
        lessThan(tester.getCenter(find.text('INVENTORY')).dx),
      );
      expect(
        tester.getCenter(find.text('INVENTORY')).dx,
        lessThan(tester.getCenter(find.text('COOKBOOK')).dx),
      );
      expect(
        tester.getCenter(find.text('COOKBOOK')).dx,
        lessThan(tester.getCenter(find.text('MORE')).dx),
      );
      expect(find.text('BURN'), findsNothing);
      expect(find.text('MORE'), findsOneWidget);
      expect(find.text('STATISTICS'), findsNothing);
      expect(find.text('SETTINGS'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('more menu can be dismissed with a drag', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('MORE'));
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.drag(find.byType(BottomSheet), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('INVENTORY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
