import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_page.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';
import 'package:yamt/features/calories/presentation/calories_page.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_pager.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_health_trends_window_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../../../support/fake_local_image_store.dart';
import '../support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User {}

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  required MealType mealType,
  String name = 'Skyr',
  String? imageUrl,
  String? sourceInventoryItemId,
  int? sourceInventoryAmountToRestore,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: name,
    imageUrl: imageUrl,
    mealType: mealType,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    sourceInventoryItemId: sourceInventoryItemId,
    sourceInventoryAmountToRestore: sourceInventoryAmountToRestore,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

CalorieEntry _bundleEntry(
  String id, {
  required DateTime loggedAt,
  required MealType mealType,
  String? imageAssetId,
  List<CalorieEntryBundleComponent>? bundleComponents,
}) {
  return CalorieEntry.bundle(
    id: id,
    userId: 'user-1',
    name: 'Chili',
    imageAssetId: imageAssetId,
    mealType: mealType,
    totalKcal: 420,
    totalProtein: 28,
    totalCarbs: 35,
    totalFat: 18,
    bundleSourcePreparedMealId: 'prepared-1',
    bundleConsumedPortions: 2,
    bundleTotalPortions: 4,
    bundleComponents:
        bundleComponents ??
        const [
          CalorieEntryBundleComponent(
            name: 'Beans',
            amountLabel: '150 g',
            brand: 'Acme',
            imageUrl: 'https://images.example.com/beans.jpg',
            totalKcal: 120,
            totalProtein: 8,
            totalCarbs: 18,
            totalFat: 1,
          ),
        ],
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

DateTime _normalizeDay(DateTime day) {
  return DateTime(day.year, day.month, day.day);
}

List<CalorieEntry> _weeklyCheckInEntries(DateTime dueDay) {
  final windowStart = _normalizeDay(dueDay).subtract(const Duration(days: 7));
  return <CalorieEntry>[
    for (var index = 0; index < 7; index += 1)
      _entry(
        'weekly-$index',
        loggedAt: windowStart.add(Duration(days: index, hours: 8)),
        mealType: MealType.breakfast,
        name: 'Weekly $index',
      ),
  ];
}

List<ManualHealthWeightEntry> _weeklyCheckInWeights(
  DateTime dueDay, {
  bool includeStart = true,
  bool includeEnd = true,
}) {
  final windowStart = _normalizeDay(dueDay).subtract(const Duration(days: 7));
  final windowEnd = windowStart.add(const Duration(days: 6));
  return <ManualHealthWeightEntry>[
    if (includeStart) ManualHealthWeightEntry(day: windowStart, weightKg: 84),
    if (includeEnd) ManualHealthWeightEntry(day: windowEnd, weightKg: 83.4),
  ];
}

List<Override> _weeklyCheckInOverrides({
  required DateTime today,
  required List<ManualHealthWeightEntry> weights,
}) {
  return <Override>[
    calorieBalanceNowProvider.overrideWithValue(() => today),
    authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(null)),
    healthConnectionServiceProvider.overrideWithValue(
      FakeHealthConnectionService(const HealthConnectionStatus.unsupported()),
    ),
    manualHealthWeightRepositoryProvider.overrideWithValue(
      FakeManualHealthWeightRepository(weights),
    ),
  ];
}

@Dependencies([
  calorieEntryDeleteFlow,
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Widget _buildHarness({
  required FakeCalorieLogRepository logRepository,
  required FakeCalorieSettingsRepository settingsRepository,
  List<Override> overrides = const <Override>[],
  DateTime? referenceNow,
  bool authenticated = true,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeCalories,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.homeCalories,
        builder: (context, state) {
          return Scaffold(body: CaloriesPage(referenceNow: referenceNow));
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryCreate,
        builder: (context, state) {
          final args = state.extra is CalorieEntryCreateArgs
              ? state.extra! as CalorieEntryCreateArgs
              : null;
          final mealType = args?.preselectedMealType?.name ?? 'none';
          return Scaffold(body: Text('Create:$mealType'));
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryDetails,
        builder: (context, state) {
          return CalorieEntryEditorPage(
            entryId: state.pathParameters['entryId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesBurnWeekMock,
        builder: (context, state) => const BurnWeekMockPage(),
      ),
      GoRoute(
        path: AppRoutes.homeStatisticsWeight,
        builder: (context, state) => const Scaffold(body: Text('Trends')),
      ),
    ],
  );

  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');

  return _ManagedProviderContainerScope(
    key: UniqueKey(),
    overrides: [
      if (authenticated)
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(user),
        ),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ...overrides,
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

class _ManagedProviderContainerScope extends StatefulWidget {
  const _ManagedProviderContainerScope({
    required this.overrides,
    required this.child,
    super.key,
  });

  final List<Override> overrides;
  final Widget child;

  @override
  State<_ManagedProviderContainerScope> createState() =>
      _ManagedProviderContainerScopeState();
}

class _ManagedProviderContainerScopeState
    extends State<_ManagedProviderContainerScope> {
  late final ProviderContainer _container = ProviderContainer(
    overrides: widget.overrides,
  );

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: _container,
      child: widget.child,
    );
  }
}

@Dependencies([
  calorieEntryDeleteFlow,
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Widget _buildHarnessWithContainer({required ProviderContainer container}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeCalories,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.homeCalories,
        builder: (context, state) => const Scaffold(body: CaloriesPage()),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryCreate,
        builder: (context, state) {
          final args = state.extra is CalorieEntryCreateArgs
              ? state.extra! as CalorieEntryCreateArgs
              : null;
          final mealType = args?.preselectedMealType?.name ?? 'none';
          return Scaffold(body: Text('Create:$mealType'));
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryDetails,
        builder: (context, state) {
          return CalorieEntryEditorPage(
            entryId: state.pathParameters['entryId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesBurnWeekMock,
        builder: (context, state) => const BurnWeekMockPage(),
      ),
      GoRoute(
        path: AppRoutes.homeStatisticsWeight,
        builder: (context, state) => const Scaffold(body: Text('Trends')),
      ),
    ],
  );

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

Finder get _pageListView => find.byType(ListView).first;

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 12; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.pumpAndSettle();
      return;
    }

    await tester.drag(
      _pageListView,
      const Offset(0, -300),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  expect(finder, findsOneWidget);
}

class _CountingDiaryHealthService implements DiaryHealthService {
  int loadCallCount = 0;

  @override
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  }) async {
    loadCallCount += 1;
    return const DiaryHealthDayData(totalSteps: 0, workouts: []);
  }
}

@Dependencies([
  calorieEntryDeleteFlow,
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
void main() {
  testWidgets('shows loading indicator while entries are loading', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository()
      ..initialEmissionDelay = const Duration(seconds: 1);
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.summaryCard), findsNothing);
  });

  testWidgets('shows error state and retries loading entries', (tester) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'retry-entry',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
          name: 'Retry entry',
        ),
      ],
    )..watchError = StateError('permission denied');
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pump();

    expect(find.text('Could not load calorie entries.'), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.retryButton), findsOneWidget);

    logRepository.watchError = null;
    await tester.tap(find.byKey(CaloriesPageKeys.retryButton));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryCard), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('retry-entry')),
    );
    expect(
      find.byKey(CaloriesPageKeys.entryTile('retry-entry')),
      findsOneWidget,
    );
  });

  testWidgets('refreshes Apple Health workouts after app resume', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    final diaryHealthService = _CountingDiaryHealthService();
    const readyStatus = HealthConnectionStatus(
      platform: HealthPlatform.ios,
      healthConnectAvailability: HealthConnectAvailability.notApplicable,
      permissionState: HealthPermissionState.granted,
      historyAccess: HealthHistoryAccess.notApplicable,
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        overrides: <Override>[
          healthConnectionServiceProvider.overrideWithValue(
            FakeHealthConnectionService(readyStatus),
          ),
          diaryHealthServiceProvider.overrideWithValue(diaryHealthService),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final initialLoadCount = diaryHealthService.loadCallCount;
    expect(initialLoadCount, greaterThan(0));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(diaryHealthService.loadCallCount, greaterThan(initialLoadCount));
  });

  testWidgets('renders redesigned diary summary and meal sections', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'b-1',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(today.year, today.month, today.day),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryCard), findsOneWidget);
    expect(find.byType(CaloriesDayNavigationPager), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.sectionCard(MealType.breakfast.name)),
    );
    expect(
      find.byKey(CaloriesPageKeys.sectionCard(MealType.breakfast.name)),
      findsOneWidget,
    );
    expect(find.text('Skyr'), findsOneWidget);
  });

  testWidgets('opens Burn Week mock from diary button', (tester) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'entry-1',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(today.year, today.month, today.day),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.burnWeekMockOpenButton),
    );
    await tester.tap(find.byKey(CaloriesPageKeys.burnWeekMockOpenButton));
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.burnWeekMockBar), findsOneWidget);
    expect(find.text('Burn Week'), findsWidgets);
  });

  testWidgets('opens detail sheet when tapping regular diary entry', (
    tester,
  ) async {
    final today = DateTime(2026, 3, 20);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'edit-me',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
          name: 'Edit me',
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        referenceNow: today,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('edit-me')),
    );
    await tester.tap(find.byKey(CaloriesPageKeys.entryTile('edit-me')));
    await tester.pumpAndSettle();

    expect(find.text('Calorie entry details'), findsOneWidget);
  });

  testWidgets('week balance banner no longer shows open chart button', (
    tester,
  ) async {
    final today = DateTime(2026, 3, 20);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'trend-entry',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(today.year, today.month, today.day),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        referenceNow: today,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsNothing);
  });

  testWidgets('weekly check-in dialog auto-opens on due diary day', (
    tester,
  ) async {
    final today = DateTime(2026, 3, 20);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: _weeklyCheckInEntries(today),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 3, 13),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        overrides: _weeklyCheckInOverrides(
          today: today,
          weights: _weeklyCheckInWeights(today),
        ),
        referenceNow: today,
        authenticated: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CalorieWeeklyCheckInDialogKeys.dialog),
      findsOneWidget,
    );
    expect(
      find.byKey(CalorieWeeklyCheckInDialogKeys.applyButton),
      findsOneWidget,
    );
  });

  testWidgets('weekly check-in Apply saves without disposed controller crash', (
    tester,
  ) async {
    final today = DateTime(2026, 3, 20);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: _weeklyCheckInEntries(today),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 3, 13),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        overrides: _weeklyCheckInOverrides(
          today: today,
          weights: _weeklyCheckInWeights(today),
        ),
        referenceNow: today,
        authenticated: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieWeeklyCheckInDialogKeys.applyButton));
    await tester.pumpAndSettle();

    expect(
      find.byKey(CalorieWeeklyCheckInDialogKeys.dialog),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    final settings = await settingsRepository.readSettings();
    expect(settings.latestGoalEntry?.source, CalorieGoalSource.weeklyCheckIn);
    expect(settings.pendingWeeklyCheckIn, isNull);
  });

  testWidgets('weekly check-in Later leaves hint and can reopen dialog', (
    tester,
  ) async {
    final today = DateTime(2026, 3, 20);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: _weeklyCheckInEntries(today),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 3, 13),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        overrides: _weeklyCheckInOverrides(
          today: today,
          weights: _weeklyCheckInWeights(today),
        ),
        referenceNow: today,
        authenticated: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieWeeklyCheckInDialogKeys.laterButton));
    await tester.pumpAndSettle();

    expect(
      find.byKey(CalorieWeeklyCheckInDialogKeys.dialog),
      findsNothing,
    );
    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.weeklyCheckInHintCard),
    );
    expect(find.byKey(CaloriesPageKeys.weeklyCheckInHintCard), findsOneWidget);

    await tester.tap(
      find.byKey(CaloriesPageKeys.weeklyCheckInContinueButton),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CalorieWeeklyCheckInDialogKeys.dialog),
      findsOneWidget,
    );
  });

  testWidgets('blocked weekly check-in offers trends when end weight missing', (
    tester,
  ) async {
    final today = DateTime(2026, 3, 20);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: _weeklyCheckInEntries(today),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 3, 13),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        ..._weeklyCheckInOverrides(
          today: today,
          weights: _weeklyCheckInWeights(today, includeEnd: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildHarnessWithContainer(container: container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(CalorieWeeklyCheckInDialogKeys.applyButton),
      findsNothing,
    );
    expect(
      find.byKey(CalorieWeeklyCheckInDialogKeys.openTrendsButton),
      findsOneWidget,
    );
    expect(find.textContaining('Mar 19, 2026'), findsOneWidget);

    await tester.tap(
      find.byKey(CalorieWeeklyCheckInDialogKeys.openTrendsButton),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trends'), findsOneWidget);
    expect(
      container.read(calorieHealthTrendsWindowControllerProvider),
      DateTime(2026, 3, 19),
    );
  });

  testWidgets('Diary hint skip action toggles skipped intake day', (
    tester,
  ) async {
    final today = DateTime(2026, 4, 15);
    final selectedDay = DateTime(2026, 4, 11);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'entry-0',
          loggedAt: DateTime(2026, 4, 8, 8),
          mealType: MealType.breakfast,
        ),
        _entry(
          'entry-1',
          loggedAt: DateTime(2026, 4, 9, 8),
          mealType: MealType.breakfast,
        ),
        _entry(
          'entry-2',
          loggedAt: DateTime(2026, 4, 10, 8),
          mealType: MealType.breakfast,
        ),
        _entry(
          'entry-4',
          loggedAt: DateTime(2026, 4, 12, 8),
          mealType: MealType.breakfast,
        ),
        _entry(
          'entry-5',
          loggedAt: DateTime(2026, 4, 13, 8),
          mealType: MealType.breakfast,
        ),
        _entry(
          'entry-6',
          loggedAt: DateTime(2026, 4, 14, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 8),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        ..._weeklyCheckInOverrides(
          today: today,
          weights: _weeklyCheckInWeights(today),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(
          calorieVisibleWindowControllerProvider.notifier,
        )
        .setWindowEnd(today);
    container.read(calorieDayControllerProvider.notifier).setDay(selectedDay);

    await tester.pumpWidget(_buildHarnessWithContainer(container: container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(CalorieWeeklyCheckInDialogKeys.laterButton));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.weeklyCheckInSkipDayButton),
    );
    await tester.tap(find.byKey(CaloriesPageKeys.weeklyCheckInSkipDayButton));
    await tester.pumpAndSettle();

    expect(
      (await settingsRepository.readSettings()).isSkippedIntakeDay(selectedDay),
      isTrue,
    );

    await tester.tap(find.byKey(CaloriesPageKeys.weeklyCheckInSkipDayButton));
    await tester.pumpAndSettle();

    expect(
      (await settingsRepository.readSettings()).isSkippedIntakeDay(selectedDay),
      isFalse,
    );
  });

  testWidgets(
    'defaults to balance mode first and persists a switch to classic',
    (tester) async {
      final today = DateTime.now();
      final preferences = MemoryAppPreferences();
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'b-1',
            loggedAt: DateTime(today.year, today.month, today.day, 8),
            mealType: MealType.breakfast,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2200,
          calculatorProfile: null,
          effectiveDate: DateTime(today.year, today.month, today.day),
        ),
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          overrides: [appPreferencesProvider.overrideWithValue(preferences)],
        ),
      );
      await tester.pumpAndSettle();

      final balanceModeFinder = find.byKey(
        CaloriesPageKeys.summaryModeOption('balance'),
      );
      final classicModeFinder = find.byKey(
        CaloriesPageKeys.summaryModeOption('classic'),
      );

      expect(find.text('EATEN'), findsOneWidget);
      expect(
        tester.getCenter(balanceModeFinder).dx,
        lessThan(tester.getCenter(classicModeFinder).dx),
      );

      await tester.tap(classicModeFinder);
      await tester.pumpAndSettle();

      expect(find.text('EATEN'), findsNothing);
      expect(
        await preferences.getString('calories_summary_view_mode'),
        'classic',
      );

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          overrides: [appPreferencesProvider.overrideWithValue(preferences)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EATEN'), findsNothing);
    },
  );

  testWidgets('long press on diary entry does not open delete dialog', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'delete-me',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
          name: 'Delete Me',
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('delete-me')),
    );
    await tester.longPress(find.byKey(CaloriesPageKeys.entryTile('delete-me')));
    await tester.pumpAndSettle();

    expect(find.text('Delete entry?'), findsNothing);
    expect(find.text('Delete Me'), findsOneWidget);
  });

  testWidgets('long press on prepared meal does not open return dialog', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _bundleEntry(
          'bundle-delete',
          loggedAt: DateTime(today.year, today.month, today.day, 12),
          mealType: MealType.lunch,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('bundle-delete')),
    );
    await tester.longPress(
      find.byKey(CaloriesPageKeys.entryTile('bundle-delete')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Return meal to inventory?'), findsNothing);
    expect(find.text('Chili'), findsOneWidget);
  });

  testWidgets('does not render meal add buttons in diary sections', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'goal',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CaloriesPageKeys.sectionAddButton(MealType.breakfast.name)),
      findsNothing,
    );
  });

  testWidgets('renders product image when diary entry has imageUrl', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'image-entry',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
          imageUrl: 'https://images.example.com/skyr.jpg',
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('image-entry')),
    );

    final imageFinder = find.byKey(CaloriesPageKeys.entryImage('image-entry'));
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<AppCachedNetworkImage>(imageFinder);
    expect(imageWidget.imageUrl, 'https://images.example.com/skyr.jpg');
  });

  testWidgets('opens detail sheet when tapping prepared meal diary entry', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _bundleEntry(
          'bundle-entry',
          loggedAt: DateTime(today.year, today.month, today.day, 12),
          mealType: MealType.lunch,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('bundle-entry')),
    );
    await tester.tap(find.byKey(CaloriesPageKeys.entryTile('bundle-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Calorie entry details'), findsOneWidget);
  });

  testWidgets(
    'renders prepared meal image when bundle entry has imageAssetId',
    (tester) async {
      final today = DateTime.now();
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _bundleEntry(
            'bundle-image-entry',
            loggedAt: DateTime(today.year, today.month, today.day, 12),
            mealType: MealType.lunch,
            imageAssetId: 'asset-bundle-image-entry',
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      final localImageStore = FakeLocalImageStore();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await localImageStore.saveBytes(
        imageRef: localImageAssetRef('asset-bundle-image-entry'),
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          overrides: [
            localImageStoreProvider.overrideWithValue(localImageStore),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byKey(CaloriesPageKeys.entryTile('bundle-image-entry')),
      );

      final imageFinder = find.byKey(
        CaloriesPageKeys.entryImage('bundle-image-entry'),
      );
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<MemoryImage>());
    },
  );

  testWidgets(
    'renders prepared meal image from local device storage for bundle entry',
    (tester) async {
      final today = DateTime.now();
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _bundleEntry(
            'bundle-local-image-entry',
            loggedAt: DateTime(today.year, today.month, today.day, 12),
            mealType: MealType.lunch,
            imageAssetId: 'asset-bundle-local-image-entry',
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      final localImageStore = FakeLocalImageStore();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await localImageStore.saveBytes(
        imageRef: localImageAssetRef('asset-bundle-local-image-entry'),
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          overrides: [
            localImageStoreProvider.overrideWithValue(localImageStore),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byKey(CaloriesPageKeys.entryTile('bundle-local-image-entry')),
      );

      final imageFinder = find.byKey(
        CaloriesPageKeys.entryImage('bundle-local-image-entry'),
      );
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<MemoryImage>());
    },
  );

  testWidgets('renders empty state text for meal sections without entries', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.sectionCard(MealType.breakfast.name)),
    );

    expect(find.text('No entries yet.'), findsWidgets);
  });

  testWidgets('falls back to zeroed week overview when provider errors', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'b-1',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(today.year, today.month, today.day),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        overrides: <Override>[
          calorieWeekOverviewProvider.overrideWith(
            (ref) async => throw StateError('week overview failed'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CaloriesDayNavigationPager), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.summaryCard), findsOneWidget);
  });
}
