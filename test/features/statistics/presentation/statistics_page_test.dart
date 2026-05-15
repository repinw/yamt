import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_health_trend_snapshot.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_health_trend_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/statistics/presentation/'
    'calorie_health_trends_page.dart';
import 'package:yamt/features/statistics/presentation/statistics_page.dart';
import 'package:yamt/features/statistics/presentation/statistics_page_keys.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_error_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _FakeInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  const _FakeInventoryDiscardEventRepository(this.events);

  final List<InventoryDiscardEvent> events;

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    return events;
  }

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async {
    return true;
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    return true;
  }
}

@Dependencies([InventoryItemsController])
void main() {
  testWidgets('switches between spending waste and calories tabs', (
    tester,
  ) async {
    final inventoryController = _InventoryItemsDataController([
      InventoryItem.create(
        id: 'rice',
        name: 'Rice',
        entryDate: DateTime.now(),
        storeName: 'REWE',
        quantity: 2,
        initialQuantity: 2,
        unitPrice: 2,
        receiptDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
    final mealsController = _PreparedMealsDataController(
      const <PreparedMeal>[],
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry('breakfast', loggedAt: DateTime.now()),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: DateTime.now().subtract(const Duration(days: 6)),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        inventoryController: inventoryController,
        mealsController: mealsController,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tracked spending'), findsOneWidget);

    await tester.tap(find.text('Food Waste'));
    await tester.pumpAndSettle();
    expect(find.text('Food waste overview'), findsOneWidget);

    await tester.tap(find.text('Calories'));
    await tester.pumpAndSettle();
    expect(find.text('Calories overview'), findsOneWidget);
  });

  testWidgets('shows loading state while inventory data is pending', (
    tester,
  ) async {
    final inventoryController = _InventoryItemsLoadingController();
    final mealsController = _PreparedMealsDataController(
      const <PreparedMeal>[],
    );
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        inventoryController: inventoryController,
        mealsController: mealsController,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error card and retry action for household data errors', (
    tester,
  ) async {
    final inventoryController = _InventoryItemsErrorController();
    final mealsController = _PreparedMealsDataController(
      const <PreparedMeal>[],
    );
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        inventoryController: inventoryController,
        mealsController: mealsController,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsErrorCard), findsOneWidget);

    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(inventoryController._refreshCount, 1);
  });

  testWidgets('shows error card when calorie statistics provider fails', (
    tester,
  ) async {
    final inventoryController = _InventoryItemsDataController(
      const <InventoryItem>[],
    );
    final mealsController = _PreparedMealsDataController(
      const <PreparedMeal>[],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: DateTime.now().subtract(const Duration(days: 6)),
      ),
    );
    final logRepository = _ThrowingCalorieLogRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        inventoryController: inventoryController,
        mealsController: mealsController,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calories'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsErrorCard), findsOneWidget);
  });

  testWidgets('weight card shows latest weight value from trend snapshot', (
    tester,
  ) async {
    final inventoryController = _InventoryItemsDataController(
      const <InventoryItem>[],
    );
    final mealsController = _PreparedMealsDataController(
      const <PreparedMeal>[],
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry('breakfast', loggedAt: DateTime.now()),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: DateTime.now().subtract(const Duration(days: 6)),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemsControllerProvider.overrideWith(
            () => inventoryController,
          ),
          preparedMealsControllerProvider.overrideWith(
            () => mealsController,
          ),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          inventoryDiscardEventRepositoryProvider.overrideWithValue(
            const _FakeInventoryDiscardEventRepository(
              <InventoryDiscardEvent>[],
            ),
          ),
          calorieHealthTrendSnapshotProvider.overrideWith((ref) async {
            return CalorieHealthTrendSnapshot(
              points: [
                CalorieHealthTrendPoint(
                  day: DateTime(2026, 3, 20),
                  intakeKcal: 1800,
                  burnedKcal: 400,
                  weightKg: 71.3,
                  weightSource: CalorieHealthTrendWeightSource.health,
                ),
              ],
              healthAccessState: HealthDataAccessState.ready,
              healthPlatform: HealthPlatform.android,
            );
          }),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: StatisticsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calories'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(StatisticsPageKeys.weightCard),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('71.3 kg'), findsOneWidget);
  });

  testWidgets('weight card opens trends page from statistics', (tester) async {
    final inventoryController = _InventoryItemsDataController(
      const <InventoryItem>[],
    );
    final mealsController = _PreparedMealsDataController(
      const <PreparedMeal>[],
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry('breakfast', loggedAt: DateTime.now()),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: DateTime.now().subtract(const Duration(days: 6)),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildRouterHarness(
        inventoryController: inventoryController,
        mealsController: mealsController,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calories'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(StatisticsPageKeys.weightCard),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(StatisticsPageKeys.weightCard));
    await tester.pumpAndSettle();

    expect(find.byType(CalorieHealthTrendsPage), findsOneWidget);
  });

  testWidgets(
    'statistics page stays scrollable on compact display-size layouts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final inventoryController = _InventoryItemsDataController(
        const <InventoryItem>[],
      );
      final mealsController = _PreparedMealsDataController(
        const <PreparedMeal>[],
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry('breakfast', loggedAt: DateTime.now()),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: DateTime.now().subtract(const Duration(days: 6)),
        ),
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          inventoryController: inventoryController,
          mealsController: mealsController,
          logRepository: logRepository,
          settingsRepository: settingsRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calories'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(StatisticsPageKeys.weightCard),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(StatisticsPageKeys.weightCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

@Dependencies([InventoryItemsController])
Widget _buildHarness({
  required InventoryItemsController inventoryController,
  required PreparedMealsController mealsController,
  required CalorieLogRepositoryContract logRepository,
  required CalorieSettingsRepository settingsRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      inventoryItemsControllerProvider.overrideWith(() => inventoryController),
      preparedMealsControllerProvider.overrideWith(() => mealsController),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      inventoryDiscardEventRepositoryProvider.overrideWithValue(
        const _FakeInventoryDiscardEventRepository(<InventoryDiscardEvent>[]),
      ),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StatisticsPage()),
    ),
  );
}

@Dependencies([InventoryItemsController])
Widget _buildRouterHarness({
  required InventoryItemsController inventoryController,
  required PreparedMealsController mealsController,
  required CalorieLogRepositoryContract logRepository,
  required CalorieSettingsRepository settingsRepository,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeStatistics,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.homeStatistics,
        builder: (context, state) => const Scaffold(body: StatisticsPage()),
      ),
      GoRoute(
        path: AppRoutes.homeStatisticsWeight,
        builder: (context, state) => const CalorieHealthTrendsPage(),
      ),
    ],
  );

  final container = ProviderContainer(
    overrides: [
      inventoryItemsControllerProvider.overrideWith(() => inventoryController),
      preparedMealsControllerProvider.overrideWith(() => mealsController),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      inventoryDiscardEventRepositoryProvider.overrideWithValue(
        const _FakeInventoryDiscardEventRepository(<InventoryDiscardEvent>[]),
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

CalorieEntry _entry(String id, {required DateTime loggedAt}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Entry $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

class _InventoryItemsDataController extends InventoryItemsController {
  _InventoryItemsDataController(this.items);

  final List<InventoryItem> items;

  @override
  FutureOr<List<InventoryItem>> build() => items;

  @override
  Future<void> refresh() async {
    state = AsyncData(items);
  }
}

class _InventoryItemsLoadingController extends InventoryItemsController {
  final _pending = Completer<List<InventoryItem>>();

  @override
  FutureOr<List<InventoryItem>> build() => _pending.future;
}

class _InventoryItemsErrorController extends InventoryItemsController {
  var _refreshCount = 0;

  @override
  FutureOr<List<InventoryItem>> build() {
    throw StateError('inventory failed');
  }

  @override
  Future<void> refresh() async {
    _refreshCount += 1;
  }
}

class _PreparedMealsDataController extends PreparedMealsController {
  _PreparedMealsDataController(this.meals);

  final List<PreparedMeal> meals;

  @override
  FutureOr<List<PreparedMeal>> build() => meals;

  @override
  Future<void> refresh() async {
    state = AsyncData(meals);
  }
}

class _ThrowingCalorieLogRepository extends FakeCalorieLogRepository {
  @override
  Future<DateTime?> readFirstEntryDate() async {
    throw StateError('statistics failed');
  }
}
