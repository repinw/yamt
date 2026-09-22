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
import 'package:yamt/core/widgets/content_visibility.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/core/widgets/home_shell_bottom_chrome.dart';
import 'package:yamt/core/widgets/home_shell_chrome.dart';
import 'package:yamt/core/widgets/home_shell_menu_button.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/core/widgets/home_top_bar.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_calendar_overview_sheet/diary_calendar_overview_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_navigator.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_home_shell_top_chrome.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/home/widgets/home_context_fab.dart';
import 'package:yamt/features/home/widgets/home_menu_drawer.dart';
import 'package:yamt/features/home/widgets/'
    'inventory_action_fab.dart';
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
import 'package:yamt/features/scanner/domain/contracts/receipt_product_resolver.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_structured_parser.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_text_extractor.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_camera_supported.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_scan_flow_coordinator.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../calories/support/fake_calories_repositories.dart';

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

class _DummyReceiptParser implements ReceiptStructuredParser {
  const new();
  @override
  Future<ScannedReceipt> parsePdf({required String pdfFilePath}) =>
      throw UnimplementedError();
  @override
  Future<ScannedReceipt> parseRawText({
    required String rawText,
    List<String> sourceFilePaths = const <String>[],
  }) => throw UnimplementedError();
}

class _DummyReceiptExtractor implements ReceiptTextExtractor {
  const new();
  @override
  Future<String> extractText(List<String> imageFilePaths) =>
      throw UnimplementedError();
  @override
  Future<void> dispose() async {}
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
  new()
    : super(
        parser: const _DummyReceiptParser(),
        extractor: const _DummyReceiptExtractor(),
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

double _homeChromeOpacity(WidgetTester tester, Type chromeType) {
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

FixedScrollMetrics _homeShellScrollMetrics({required double pixels}) {
  return FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: 1000,
    pixels: pixels,
    viewportDimension: 844,
    axisDirection: AxisDirection.down,
    devicePixelRatio: 1,
  );
}

void _dispatchHomeShellScrollUpdate(
  BuildContext context, {
  required double pixels,
  required double scrollDelta,
}) {
  ScrollUpdateNotification(
    metrics: _homeShellScrollMetrics(pixels: pixels),
    context: context,
    scrollDelta: scrollDelta,
  ).dispatch(context);
}

void _dispatchHomeShellScrollEnd(
  BuildContext context, {
  required double pixels,
}) {
  ScrollEndNotification(
    metrics: _homeShellScrollMetrics(pixels: pixels),
    context: context,
  ).dispatch(context);
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
  testWidgets('diary tab does not show the context fab', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: _diaryTopChromeBranchBody(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeContextFab), findsNothing);
  });

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
    expect(find.text('Today'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomeShellTabTopChrome),
        matching: find.text('Diary'),
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

    expect(find.text(DateFormat('dd.MM').format(oldDay)), findsOneWidget);

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

    await tester.tap(menuButton);
    await tester.pumpAndSettle();
    expect(find.byType(HomeMenuDrawer), findsOneWidget);

    await tester.tap(find.byKey(HomeMenuDrawer.settingsTileKey));
    await tester.pumpAndSettle();

    expect(find.text('Settings route'), findsOneWidget);
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

  testWidgets('tab top chrome renders caller-owned actions', (tester) async {
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
              actions: [
                IconButton(
                  tooltip: 'Import recipe',
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file_rounded),
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
    expect(find.byTooltip('Import recipe'), findsOneWidget);
    expect(find.byIcon(Icons.upload_file_rounded), findsOneWidget);
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
                const HomeShellTabTopChrome(title: 'Today'),
                SliverList.builder(
                  itemCount: 40,
                  itemBuilder: (context, index) {
                    return SizedBox(height: 72, child: Text('Row $index'));
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialTopOffset = tester.getTopLeft(find.byType(HomeTopBar)).dy;
    final initialBottomOpacity = _homeChromeOpacity(
      tester,
      HomeShellBottomChrome,
    );

    await tester.drag(find.text('Row 5'), const Offset(0, -48));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final shiftedTopOffset = tester.getTopLeft(find.byType(HomeTopBar)).dy;

    await tester.drag(find.text('Row 5'), const Offset(0, -172));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final collapsedBottomOpacity = _homeChromeOpacity(
      tester,
      HomeShellBottomChrome,
    );

    expect(shiftedTopOffset, lessThan(initialTopOffset));
    expect(find.byType(HomeTopBar), findsNothing);
    expect(collapsedBottomOpacity, lessThan(initialBottomOpacity));

    await tester.drag(find.text('Row 8'), const Offset(0, 240));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(HomeTopBar), findsOneWidget);
    final revealedTopOffset = tester.getTopLeft(find.byType(HomeTopBar)).dy;
    final revealedBottomOpacity = _homeChromeOpacity(
      tester,
      HomeShellBottomChrome,
    );

    expect(revealedTopOffset, greaterThan(shiftedTopOffset));
    expect(revealedBottomOpacity, greaterThan(collapsedBottomOpacity));
    expect(revealedBottomOpacity - collapsedBottomOpacity, greaterThan(0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shell chrome ignores non-scrollable page drags', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: const CustomScrollView(
          slivers: [
            HomeShellTabTopChrome(title: 'Today'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Short content')),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialBottomOpacity = _homeChromeOpacity(
      tester,
      HomeShellBottomChrome,
    );

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -180),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(HomeTopBar), findsOneWidget);
    expect(
      _homeChromeOpacity(tester, HomeShellBottomChrome),
      moreOrLessEquals(initialBottomOpacity),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shell chrome stays visible on shallow scroll pages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: const CustomScrollView(
          slivers: [
            HomeShellTabTopChrome(title: 'Today'),
            SliverToBoxAdapter(
              child: SizedBox(height: 980, child: Text('Shallow content')),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialBottomOpacity = _homeChromeOpacity(
      tester,
      HomeShellBottomChrome,
    );

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();

    expect(
      _homeChromeOpacity(tester, HomeShellBottomChrome),
      moreOrLessEquals(initialBottomOpacity),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shell chrome snaps after partial scrolls settle', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: CustomScrollView(
          slivers: [
            const HomeShellTabTopChrome(title: 'Today'),
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

    await tester.drag(find.text('Row 5'), const Offset(0, -96));
    await tester.pumpAndSettle();

    expect(
      _homeChromeOpacity(tester, HomeShellBottomChrome),
      moreOrLessEquals(1),
    );

    await tester.drag(find.text('Row 7'), const Offset(0, -190));
    await tester.pumpAndSettle();

    expect(
      _homeChromeOpacity(tester, HomeShellBottomChrome),
      moreOrLessEquals(0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shell chrome reveals when scroll ends near top', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: CustomScrollView(
          slivers: [
            const HomeShellTabTopChrome(title: 'Today'),
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

    final scrollContext = tester.element(find.byType(CustomScrollView).first);
    _dispatchHomeShellScrollUpdate(
      scrollContext,
      pixels: 220,
      scrollDelta: 220,
    );
    _dispatchHomeShellScrollEnd(scrollContext, pixels: 220);
    await tester.pumpAndSettle();

    expect(
      _homeChromeOpacity(tester, HomeShellBottomChrome),
      moreOrLessEquals(0),
    );

    _dispatchHomeShellScrollEnd(scrollContext, pixels: 5);
    await tester.pumpAndSettle();

    expect(
      _homeChromeOpacity(tester, HomeShellBottomChrome),
      moreOrLessEquals(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shell chrome snaps open at exact threshold', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: CustomScrollView(
          slivers: [
            const HomeShellTabTopChrome(title: 'Today'),
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

    final scrollContext = tester.element(find.byType(CustomScrollView).first);
    _dispatchHomeShellScrollUpdate(
      scrollContext,
      pixels: 160,
      scrollDelta: 160,
    );
    _dispatchHomeShellScrollEnd(scrollContext, pixels: 160);
    await tester.pumpAndSettle();

    expect(
      _homeChromeOpacity(tester, HomeShellBottomChrome),
      moreOrLessEquals(1),
    );

    _dispatchHomeShellScrollUpdate(
      scrollContext,
      pixels: 163.2,
      scrollDelta: 163.2,
    );
    _dispatchHomeShellScrollEnd(scrollContext, pixels: 163.2);
    await tester.pumpAndSettle();

    expect(
      _homeChromeOpacity(tester, HomeShellBottomChrome),
      moreOrLessEquals(0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shell chrome ignores nested vertical scroll views', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        branchBody: CustomScrollView(
          slivers: [
            const HomeShellTabTopChrome(title: 'Today'),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 480,
                child: ListView.builder(
                  key: const ValueKey('nested-home-scroll'),
                  primary: false,
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      height: 64,
                      child: Text('Nested row $index'),
                    );
                  },
                ),
              ),
            ),
            SliverList.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                return SizedBox(height: 72, child: Text('Outer row $index'));
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialTopOffset = tester.getTopLeft(find.byType(HomeTopBar)).dy;
    final initialBottomOpacity = _homeChromeOpacity(
      tester,
      HomeShellBottomChrome,
    );

    await tester.drag(find.text('Nested row 4'), const Offset(0, -220));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(HomeTopBar), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(HomeTopBar)).dy,
      moreOrLessEquals(initialTopOffset),
    );
    expect(
      _homeChromeOpacity(tester, HomeShellBottomChrome),
      moreOrLessEquals(initialBottomOpacity),
    );
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

  testWidgets('inventory tab hides shell fab when inventory is empty', (
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

    expect(find.byType(InventoryActionFab), findsNothing);
    expect(find.byType(HomeContextFab), findsNothing);
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
    expect(find.text('Bind meal'), findsOneWidget);

    await tester.tap(find.text('Bind meal'));
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

  testWidgets('inventory ingredient selection chrome uses add action', (
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
    container
        .read(preparedMealSelectionControllerProvider.notifier)
        .startAddIngredientsToMealSelection();
    container
        .read(preparedMealSelectionControllerProvider.notifier)
        .toggleSelection('item-1');
    await tester.pumpAndSettle();

    expect(find.text('Add ingredient'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    await tester.tap(find.text('Add ingredient'));
    await tester.pumpAndSettle();

    expect(
      container.read(preparedMealSelectionControllerProvider).bindRequestToken,
      1,
    );
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

    final initialFabTop = tester.getTopLeft(find.byType(InventoryActionFab)).dy;

    await tester.drag(find.text('Row 5'), const Offset(0, -220));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final collapsedFabTop = tester
        .getTopLeft(find.byType(InventoryActionFab))
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

    await tester.tap(find.text('Diary'));
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

  testWidgets('inventory snackbar lays out with inventory fab', (tester) async {
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
    ScaffoldMessenger.of(homeContext)
        .showSnackBar(const SnackBar(content: Text('Saved')));
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

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Manual search'), findsOneWidget);
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('AI suggestion'), findsOneWidget);
    expect(find.text('Upload image/PDF'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);

    await tester.tap(find.text('Manual search'));
    await tester.pumpAndSettle();

    final args = hubRouteExtra! as ProductSearchHubRouteArgs;
    expect(args.mode, ProductSearchHubMode.inventory);
    expect(args.initialIntent, ProductSearchHubInitialIntent.search);
  });

  testWidgets('inventory shell fab opens ai suggestion route', (tester) async {
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

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI suggestion'));
    await tester.pumpAndSettle();

    final args = hubRouteExtra! as ProductSearchHubRouteArgs;
    expect(args.mode, ProductSearchHubMode.inventory);
    expect(args.initialIntent, ProductSearchHubInitialIntent.ai);
  });

  testWidgets('inventory shell fab starts upload flow', (tester) async {
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

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload image/PDF'));
    await tester.pumpAndSettle();

    expect(coordinator.filePickerFlowCallCount, 1);
  });

  testWidgets('inventory shell fab starts camera flow when enabled', (
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

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(coordinator.cameraFlowCallCount, 1);
  });

  testWidgets('inventory shell fab disables camera when unsupported', (
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
        isCameraSupported: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(coordinator.cameraFlowCallCount, 0);
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
    expect(find.text('Bind meal'), findsNothing);
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

    expect(navLabel('Diary'), findsOneWidget);
    expect(navLabel('Inventory'), findsOneWidget);
    expect(navLabel('Cookbook'), findsOneWidget);
    expect(navLabel('Progress'), findsOneWidget);
    expect(
      tester.getCenter(navLabel('Diary')).dx,
      lessThan(tester.getCenter(navLabel('Inventory')).dx),
    );
    expect(
      tester.getCenter(navLabel('Inventory')).dx,
      lessThan(tester.getCenter(navLabel('Cookbook')).dx),
    );
    expect(
      tester.getCenter(navLabel('Cookbook')).dx,
      lessThan(tester.getCenter(navLabel('Progress')).dx),
    );
    expect(find.text('SETTINGS'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
