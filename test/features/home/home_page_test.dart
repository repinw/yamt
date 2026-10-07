import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/router/app_route_observer.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/core/widgets/content_visibility.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/core/widgets/home_shell_menu_button.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/core/widgets/home_shell_top_sliver_chrome.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_debug_keys.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_weekly_checkin_preview_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_calendar_overview_sheet/diary_calendar_overview_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_navigator.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_home_shell_top_chrome.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_preview_tiles.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/home/presentation/widgets/home_menu_panel.dart';
import 'package:yamt/features/home/presentation/widgets/inventory_add_actions.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_home_shell_top_chrome.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/scanner/data/receipt_ai_repository.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_product_resolver.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_camera_supported.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_scan_flow_coordinator.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../calories/support/fake_calories_repositories.dart';
import '../scanner/fakes/fake_receipt_ai_repository.dart';
import '../scanner/fakes/fake_receipt_product_resolver.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _FakeInventoryItemRepository implements InventoryItemRepository {
  new(this.items);

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
  new(this.meals);

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
  Future<bool> save(PreparedMeal meal) async => true;

  @override
  Future<bool> delete(String mealId) async => true;
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
  new(this.state);

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
  new(this.selectedDay);

  final DateTime selectedDay;

  @override
  DiaryCalendarState build() {
    final today = normalizeDiaryDay(DateTime.now());
    return DiaryCalendarState(
      today: today,
      selectedDay: normalizeDiaryDay(selectedDay),
    );
  }
}

class _DummyReceiptResolver implements ReceiptProductResolver {
  const new();
  @override
  Future<List<ProductCandidate>> resolveCandidates({
    required String rawLineText,
    String? storeName,
    String? brand,
    String? weight,
  }) => throw UnimplementedError();
  @override
  Future<Map<String, List<ProductCandidate>>> resolveBatch({
    required List<ReceiptLineItem> items,
    String? storeName,
  }) => throw UnimplementedError();
  @override
  Future<ProductCandidate?> resolveByBarcode(String barcode) =>
      throw UnimplementedError();
  @override
  Future<List<ProductCandidate>> resolveCandidatesByBarcode(String barcode) =>
      throw UnimplementedError();
  @override
  Future<List<ProductCandidate>> searchByName(
    String query, {
    String? storeName,
    String? brand,
    String? weight,
  }) => throw UnimplementedError();
}

class _RecordingReceiptScanFlowCoordinator extends ReceiptScanFlowCoordinator {
  new({super.isCameraSupported})
    : super(
        receiptAi: ReceiptAiRepository(
          templateClient: (_) => throw UnimplementedError(),
        ),
        resolver: const _DummyReceiptResolver(),
      );

  int cameraFlowCallCount = 0;
  int filePickerFlowCallCount = 0;

  @override
  Future<bool> startCameraFlow(BuildContext context) async {
    cameraFlowCallCount++;
    return false;
  }

  @override
  Future<bool> startFilePickerFlow(BuildContext context) async {
    filePickerFlowCallCount++;
    return false;
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
    isPreviousDayClosed: false,
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
      HomeShellTabTopChrome(title: _titleForTab(tab)),
      const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
    ],
  );
}

Widget _diaryTopChromeBranchBody() {
  return const Column(
    children: [
      DiaryHomeShellTopChrome(),
      Expanded(child: SizedBox()),
    ],
  );
}

Widget _inventoryTopChromeBranchBody() {
  return const CustomScrollView(
    slivers: [
      InventoryHomeShellTopChrome(),
      SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
    ],
  );
}

String _titleForTab(HomeTabType tab) {
  return switch (tab) {
    HomeTabType.inventory => 'Inventory',
    HomeTabType.diary => 'Today',
    HomeTabType.cookbook => 'Cookbook',
    HomeTabType.progress => 'Progress',
  };
}

Widget _buildHarness({
  required FakeCalorieSettingsRepository settingsRepository,
  String initialLocation = AppRoutes.homeCalories,
  Widget? branchBody,
  InventoryItemRepository? inventoryRepository,
  PreparedMealRepository? preparedMealRepository,
  InventoryItemsController? inventoryItemsController,
  PreparedMealsController? preparedMealsController,
  ReceiptScanFlowCoordinator? receiptScanFlowCoordinator,
  BurnWeekRunStateRepository? burnWeekRunStateRepository,
  DateTime? selectedDiaryDay,
  bool? isCameraSupported,
  ThemeData? theme,
  ValueChanged<Object?>? onHubRouteExtra,
}) {
  final today = normalizeDiaryDay(DateTime.now());
  final dashboardDay = selectedDiaryDay == null
      ? today
      : normalizeDiaryDay(selectedDiaryDay);
  final firebaseAuth = _MockFirebaseAuth();
  when(() => firebaseAuth.currentUser).thenReturn(null);
  final routeObserver = RouteObserver<ModalRoute<void>>();
  final router = GoRouter(
    initialLocation: initialLocation,
    observers: [routeObserver],
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
                path: AppRoutes.homeProgress,
                builder: (context, state) =>
                    branchBody ?? _defaultBranchBody(HomeTabType.progress),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) {
          onHubRouteExtra?.call(state.extra);
          return const SizedBox();
        },
      ),
      GoRoute(
        path: AppRoutes.homeSettings,
        builder: (context, state) =>
            const Scaffold(body: Text('Settings route')),
      ),
      GoRoute(
        path: AppRoutes.homeProfile,
        builder: (context, state) =>
            const Scaffold(body: Text('Profile route')),
      ),
      GoRoute(
        path: AppRoutes.homeShopping,
        builder: (context, state) =>
            const Scaffold(body: Text('Shopping route')),
      ),
    ],
  );

  final container = ProviderContainer(
    overrides: [
      appRouteObserverProvider.overrideWithValue(routeObserver),
      authStateChangesProvider.overrideWith(
        (ref) => const Stream<User?>.empty(),
      ),
      firebaseAuthProvider.overrideWithValue(firebaseAuth),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        burnWeekRunStateRepository ??
            _FakeBurnWeekRunStateRepository(const BurnWeekRunState.initial()),
      ),
      calorieWeekOverviewForWindowProvider(today)
          .overrideWith((ref) => _weekOverview(today)),
      if (!isSameDiaryDay(dashboardDay, today))
        calorieWeekOverviewForWindowProvider(dashboardDay)
            .overrideWith((ref) => _weekOverview(dashboardDay)),
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
      // The Vorrat actions watch the scan coordinator while building, so its
      // AI and product lookups are fakes.
      receiptAiRepositoryProvider.overrideWithValue(FakeReceiptAiRepository()),
      receiptProductResolverProvider.overrideWithValue(
        FakeReceiptProductResolver(),
      ),
      if (receiptScanFlowCoordinator != null)
        receiptScanFlowCoordinatorProvider.overrideWithValue(
          receiptScanFlowCoordinator,
        ),
      if (selectedDiaryDay != null)
        diaryCalendarControllerProvider.overrideWith(
          () => _TestDiaryCalendarController(selectedDiaryDay),
        ),
      if (isCameraSupported != null)
        receiptCameraSupportedProvider.overrideWith((ref) => isCameraSupported),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      theme: theme,
      routerConfig: router,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('a page over the shell marks the tab content as covered', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();
    final diaryChrome = find.byType(
      DiaryHomeShellTopChrome,
      skipOffstage: false,
    );
    bool isContentVisible() =>
        ContentVisibility.of(tester.element(diaryChrome));

    expect(isContentVisible(), isTrue);

    unawaited(
      GoRouter.of(tester.element(diaryChrome)).push(AppRoutes.homeSettings),
    );
    await tester.pumpAndSettle();
    expect(isContentVisible(), isFalse);

    GoRouter.of(tester.element(find.text('Settings route'))).pop();
    await tester.pumpAndSettle();
    expect(isContentVisible(), isTrue);
  });

  testWidgets('diary tab shows only the day navigator in the shell bar', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DiaryDayNavigator), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomeShellTabTopChrome),
        matching: find.text('DIARY'),
      ),
      findsNothing,
    );
  });

  testWidgets('diary calendar sheet Today action returns to the current day', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final today = normalizeDiaryDay(DateTime.now());
    final oldDay = today.subtract(const Duration(days: 2));

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        selectedDiaryDay: oldDay,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(DateFormat('d. MMM', 'en').format(oldDay)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DiaryDayNavigatorKeys.label));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryCalendarOverviewKeys.today));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePage)),
    );
    final state = container.read(diaryCalendarControllerProvider);
    expect(state.selectedDay, today);
  });

  testWidgets('secondary tab chrome uses tab titles and empty actions', (
    tester,
  ) async {
    final scenarios = <String, String>{
      AppRoutes.homeInventoryTemplates: 'Cookbook',
      AppRoutes.homeProgress: 'Progress',
    };

    for (final scenario in scenarios.entries) {
      final repository = FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          settingsRepository: repository,
          initialLocation: scenario.key,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(HomeShellTabTopChrome),
          matching: find.text(scenario.value),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.assignment_outlined), findsNothing);
      expect(find.byIcon(Icons.shopping_cart_rounded), findsNothing);
      expect(find.byIcon(Icons.bug_report_rounded), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('diary menu button on the left opens settings', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();

    final menuButton = find.byKey(HomeShellMenuButton.buttonKey);
    expect(
      tester.getCenter(menuButton).dx,
      lessThan(tester.getCenter(find.byKey(DiaryDayNavigatorKeys.label)).dx),
    );
    expect(
      find.byKey(HomeMenuPanel.closeButtonKey).hitTestable(),
      findsNothing,
    );

    await tester.tap(menuButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(HomeMenuPanel.closeButtonKey).hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.byKey(HomeMenuPanel.settingsTileKey));
    await tester.pumpAndSettle();

    expect(find.text('Settings route'), findsOneWidget);
  });

  testWidgets('diary menu opens settings at the appearance section', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeShellMenuButton.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeMenuPanel.appearanceTileKey));
    await tester.pumpAndSettle();

    expect(
      GoRouterState.of(tester.element(find.text('Settings route'))).uri,
      Uri.parse(AppRoutes.homeSettingsAppearance),
    );
  });

  testWidgets('diary menu lists the profile first and opens it', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeShellMenuButton.buttonKey));
    await tester.pumpAndSettle();
    final profileTile = find.byKey(HomeMenuPanel.profileTileKey);
    expect(
      tester.getTopLeft(profileTile).dy,
      lessThan(tester.getTopLeft(find.byKey(HomeMenuPanel.settingsTileKey)).dy),
    );

    await tester.tap(profileTile);
    await tester.pumpAndSettle();

    expect(find.text('Profile route'), findsOneWidget);
    expect(
      find.byKey(HomeMenuPanel.closeButtonKey).hitTestable(),
      findsNothing,
    );
  });

  testWidgets('diary menu keeps the debug entries collapsed', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeShellMenuButton.buttonKey));
    await tester.pumpAndSettle();
    final debugPreview = find.byKey(
      DiaryWeeklyCheckInPreviewTiles.tileKey(
        DiaryWeeklyCheckInPreviewKind.checkIn,
      ),
    );
    expect(find.byKey(CalorieDebugKeys.debugDumpButton), findsNothing);
    expect(debugPreview, findsNothing);

    final debugSection = find.byKey(HomeMenuPanel.debugSectionKey);
    await tester.scrollUntilVisible(
      debugSection,
      100,
      scrollable: find.descendant(
        of: find.byType(HomeMenuPanel),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(debugSection);
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieDebugKeys.debugDumpButton), findsOneWidget);
    expect(debugPreview, findsOneWidget);
  });

  testWidgets('tapping the moved page closes the menu', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeShellMenuButton.buttonKey));
    await tester.pumpAndSettle();

    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(size.width * 0.9, size.height * 0.5));
    await tester.pumpAndSettle();

    expect(
      find.byKey(HomeMenuPanel.closeButtonKey).hitTestable(),
      findsNothing,
    );
    expect(
      find.byKey(HomeShellMenuButton.buttonKey).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('back closes the menu and stays on the tab', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeShellMenuButton.buttonKey));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.byKey(HomeMenuPanel.closeButtonKey).hitTestable(),
      findsNothing,
    );
    expect(
      find.byKey(HomeShellMenuButton.buttonKey).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('tabs other than diary have no menu button', (tester) async {
    for (final location in [
      AppRoutes.homeProgress,
      AppRoutes.homeInventory,
      AppRoutes.homeInventoryTemplates,
    ]) {
      final repository = FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          settingsRepository: repository,
          initialLocation: location,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(HomeShellMenuButton.buttonKey), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('bottom navigation lists diary, inventory, cookbook, progress', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await tester.pumpAndSettle();

    final labels = tester
        .widgetList<HomeBottomNavBar>(find.byType(HomeBottomNavBar))
        .single
        .entries
        .map((entry) => entry.item.label)
        .toList();
    expect(labels, ['Diary', 'Inventory', 'Cookbook', 'Progress']);
    expect(find.byIcon(Icons.settings_rounded), findsNothing);
  });

  testWidgets('tab top chrome renders caller-owned tools', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventoryTemplates,
        branchBody: CustomScrollView(
          slivers: [
            HomeShellTabTopChrome(
              title: 'Cookbook',
              tools: [
                HomeHeaderTool(
                  symbol: const Icon(Icons.upload_file_rounded),
                  label: 'Import',
                  onPressed: () {},
                ),
              ],
            ),
            const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(HomeShellTabTopChrome),
        matching: find.text('Cookbook'),
      ),
      findsOneWidget,
    );
    expect(find.text('IMPORT'), findsOneWidget);
    expect(find.byIcon(Icons.upload_file_rounded), findsOneWidget);
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

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(DiaryDayNavigator)).height,
      greaterThan(56),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory tab shows the action when inventory is empty', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        branchBody: _inventoryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeBottomNavBar.actionKey), findsOneWidget);
  });

  testWidgets('inventory top bar actions show shopping route', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        branchBody: _inventoryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.assignment_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.shopping_cart_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Shopping route'), findsOneWidget);
  });

  testWidgets('inventory selection chrome confirms and clears full actions', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        branchBody: _inventoryTopChromeBranchBody(),
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

    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Combine foods'), findsOneWidget);

    await tester.tap(find.text('Combine foods'));
    await tester.pumpAndSettle();

    expect(
      container.read(preparedMealSelectionControllerProvider).bindRequestToken,
      1,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(
      container.read(preparedMealSelectionControllerProvider).isSelectionMode,
      isFalse,
    );
  });

  testWidgets('inventory tab shows the dock while inventory is loading', (
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

    expect(find.byKey(HomeBottomNavBar.actionKey), findsOneWidget);
  });

  testWidgets(
    'inventory action opens the add sheet when inventory and meals exist',
    (tester) async {
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

      await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
      await tester.pumpAndSettle();

      expect(find.byKey(InventoryAddActionKeys.barcode), findsOneWidget);
      expect(find.byKey(InventoryAddActionKeys.manualSearch), findsOneWidget);
      expect(find.byKey(InventoryAddActionKeys.receiptUpload), findsOneWidget);
    },
  );

  testWidgets('inventory action and header stay put while scrolling', (
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
            const HomeShellTabTopChrome(title: 'Inventory'),
            SliverList.builder(
              itemCount: 40,
              itemBuilder: (context, index) {
                return SizedBox(height: 72, child: Text('Row $index'));
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialActionTop = tester
        .getTopLeft(find.byKey(HomeBottomNavBar.actionKey))
        .dy;
    final initialTitleTop = tester.getTopLeft(find.text('Inventory').first).dy;

    await tester.drag(find.text('Row 5'), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(HomeBottomNavBar.actionKey)).dy,
      initialActionTop,
    );
    expect(tester.getTopLeft(find.text('Inventory').first).dy, initialTitleTop);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unpinned header scrolls away under a pinned search row', (
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
            const HomeShellStatusBarSliver(),
            const HomeShellTabTopChrome(title: 'Inventory', pinned: false),
            const HomeShellPinnedSliver(height: 60, child: Text('Search row')),
            SliverList.builder(
              itemCount: 40,
              itemBuilder: (context, index) {
                return SizedBox(height: 72, child: Text('Row $index'));
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('Row 5'), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsNothing);
    expect(tester.getTopLeft(find.text('Search row')).dy, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('action word changes immediately after leaving inventory', (
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

    expect(find.text('ADD'), findsOneWidget);

    await tester.tap(find.text('DIARY'));
    await tester.pump();

    expect(find.text('ADD'), findsNothing);
    expect(find.text('EAT'), findsOneWidget);
  });

  testWidgets(
    'inventory tab shows the action when only inventory items exist',
    (tester) async {
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

      expect(find.byKey(HomeBottomNavBar.actionKey), findsOneWidget);
    },
  );

  testWidgets('inventory snackbar lays out with the action button', (
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
    ScaffoldMessenger.of(homeContext).showAppSnackBar('Saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (label, location, inventoryItems) in [
    ('diary tab with dock', AppRoutes.homeDiary, <InventoryItem>[]),
    (
      'inventory tab with dock',
      AppRoutes.homeInventory,
      <InventoryItem>[_inventoryItem('item-1')],
    ),
  ]) {
    testWidgets(
      'app snack bar sits at the top, clear of the bottom bar on $label',
      (tester) async {
        final repository = FakeCalorieSettingsRepository();
        addTearDown(repository.dispose);

        await tester.pumpWidget(
          _buildHarness(
            settingsRepository: repository,
            initialLocation: location,
            inventoryRepository: _FakeInventoryItemRepository(inventoryItems),
          ),
        );
        await tester.pumpAndSettle();

        ScaffoldMessenger.of(tester.element(find.byType(HomePage)))
            .showAppSnackBar('Saved');
        await tester.pumpAndSettle();

        final snackBar = tester.getRect(find.byType(AppSnackBarView));
        final navTop = tester.getRect(find.byType(HomeBottomNavBar)).top;
        expect(snackBar.bottom, lessThan(navTop / 2));
      },
    );
  }

  testWidgets('inventory action opens the add actions', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    Object? hubRouteExtra;

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        onHubRouteExtra: (extra) => hubRouteExtra = extra,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();

    expect(find.text('Manual search'), findsOneWidget);
    expect(find.text('AI suggestion'), findsOneWidget);
    expect(find.text('Upload image/PDF'), findsOneWidget);

    await tester.tap(find.text('Manual search'));
    await tester.pumpAndSettle();

    final args = hubRouteExtra! as ProductSearchHubRouteArgs;
    expect(args.mode, ProductSearchHubMode.inventory);
    expect(args.initialIntent, ProductSearchHubInitialIntent.search);
  });

  testWidgets('inventory add sheet opens ai suggestion route', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    Object? hubRouteExtra;

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        onHubRouteExtra: (extra) => hubRouteExtra = extra,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI suggestion'));
    await tester.pumpAndSettle();

    final args = hubRouteExtra! as ProductSearchHubRouteArgs;
    expect(args.mode, ProductSearchHubMode.inventory);
    expect(args.initialIntent, ProductSearchHubInitialIntent.ai);
  });

  testWidgets('inventory receipt sheet starts upload flow', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final coordinator = _RecordingReceiptScanFlowCoordinator();

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        receiptScanFlowCoordinator: coordinator,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload image/PDF'));
    await tester.pumpAndSettle();

    expect(coordinator.cameraFlowCallCount, 0);
    expect(coordinator.filePickerFlowCallCount, 1);
  });

  testWidgets('inventory receipt sheet takes a photo with a camera', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final coordinator = _RecordingReceiptScanFlowCoordinator();

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        receiptScanFlowCoordinator: coordinator,
        isCameraSupported: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photograph receipt'));
    await tester.pumpAndSettle();

    expect(coordinator.cameraFlowCallCount, 1);
  });

  testWidgets('inventory actions offer only the upload without a camera', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final coordinator = _RecordingReceiptScanFlowCoordinator(
      isCameraSupported: false,
    );

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialLocation: AppRoutes.homeInventory,
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem('item-1'),
        ]),
        receiptScanFlowCoordinator: coordinator,
        isCameraSupported: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    expect(find.text('Photograph receipt'), findsNothing);
    await tester.tap(find.text('Upload image/PDF'));
    await tester.pumpAndSettle();

    expect(coordinator.cameraFlowCallCount, 0);
    expect(coordinator.filePickerFlowCallCount, 1);
  });

  testWidgets('inventory tab shows the dock when only prepared meals exist', (
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

    expect(find.byKey(HomeBottomNavBar.actionKey), findsOneWidget);
  });

  testWidgets('inventory selection chrome compacts on small zoomed layouts', (
    tester,
  ) async {
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
        branchBody: _inventoryTopChromeBranchBody(),
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
    expect(find.text('Combine foods'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.restaurant_menu_rounded));
    await tester.pumpAndSettle();

    expect(
      container.read(preparedMealSelectionControllerProvider).bindRequestToken,
      1,
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(
      container.read(preparedMealSelectionControllerProvider).isSelectionMode,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom nav keeps labels on wider layouts with larger text', (
    tester,
  ) async {
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

    Finder navLabel(String label) => find.descendant(
      of: find.byType(HomeBottomNavBar),
      matching: find.text(label),
    );

    expect(navLabel('DIARY'), findsOneWidget);
    expect(navLabel('INVENTORY'), findsOneWidget);
    expect(navLabel('COOKBOOK'), findsOneWidget);
    expect(navLabel('PROGRESS'), findsOneWidget);
    expect(
      tester.getCenter(navLabel('DIARY')).dx,
      lessThan(tester.getCenter(navLabel('INVENTORY')).dx),
    );
    expect(
      tester.getCenter(navLabel('INVENTORY')).dx,
      lessThan(tester.getCenter(navLabel('COOKBOOK')).dx),
    );
    expect(
      tester.getCenter(navLabel('COOKBOOK')).dx,
      lessThan(tester.getCenter(navLabel('PROGRESS')).dx),
    );
    expect(find.text('SETTINGS'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
