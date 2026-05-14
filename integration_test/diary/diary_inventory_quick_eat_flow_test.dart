import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/models/user_profile.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/domain/diary_intro_preferences.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/provider/diary_calendar_controller.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/memory_app_preferences.dart';

class _DiaryInventoryQuickEatHarness {
  const _DiaryInventoryQuickEatHarness({
    required this.app,
    required this.profileController,
    required this.preparedMealsController,
  });

  final Widget app;
  final StreamController<UserProfile?> profileController;
  final _StaticPreparedMealsController preparedMealsController;
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  inventoryBackedCalorieEntrySaveFlow,
])
_DiaryInventoryQuickEatHarness _buildHarness({
  List<InventoryItem>? inventoryItems,
  List<PreparedMeal> preparedMeals = const <PreparedMeal>[],
}) {
  final selectedDay = DateTime(2026, 5, 13);
  final profileController = StreamController<UserProfile?>();
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  final logRepository = FakeCalorieLogRepository();
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2200,
      calculatorProfile: null,
      effectiveDate: selectedDay.subtract(const Duration(days: 14)),
    ),
  );
  final router = GoRouter(
    initialLocation: AppRoutes.homeCalories,
    routes: [
      GoRoute(
        path: AppRoutes.homeCalories,
        builder: (context, state) {
          return const Scaffold(body: DiaryPage());
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(logRepository.dispose);
  addTearDown(settingsRepository.dispose);
  addTearDown(profileController.close);

  final householdItems =
      inventoryItems ?? [_inventoryItem(id: 'broetchen', name: 'Brötchen')];
  final preparedMealsController = _StaticPreparedMealsController(
    preparedMeals,
  );

  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(
        MemoryAppPreferences(
          initialStrings: DiaryIntroPreferences.initialSeenStrings(),
        ),
      ),
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
      userProfileProvider.overrideWith((ref) => profileController.stream),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      calorieWeeklyCheckInViewModelProvider.overrideWith(
        (ref) => _emptyWeeklyCheckInViewModel(),
      ),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        const _StaticBurnWeekRunStateRepository(),
      ),
      diaryCalendarControllerProvider.overrideWith(
        () => _StaticDiaryCalendarController(selectedDay),
      ),
      healthConnectionServiceProvider.overrideWithValue(
        FakeHealthConnectionService(
          const HealthConnectionStatus.unsupported(),
        ),
      ),
      diaryHealthServiceProvider.overrideWithValue(
        FakeDiaryHealthService(const <String, DiaryHealthDayData>{}),
      ),
      healthWeightServiceProvider.overrideWithValue(
        FakeHealthWeightService(const <HealthWeightSample>[]),
      ),
      manualHealthWeightRepositoryProvider.overrideWithValue(
        FakeManualHealthWeightRepository(<ManualHealthWeightEntry>[]),
      ),
      inventoryItemRepositoryProvider.overrideWith(
        (ref) => _OwnerScopedInventoryItemRepository(
          ownerId: ref.watch(effectiveHouseholdDataOwnerUserIdProvider),
          itemsByOwnerId: {
            'household-1': householdItems,
          },
        ),
      ),
      preparedMealsControllerProvider.overrideWith(
        () => preparedMealsController,
      ),
    ],
  );
  addTearDown(container.dispose);

  return _DiaryInventoryQuickEatHarness(
    profileController: profileController,
    preparedMealsController: preparedMealsController,
    app: UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('de'),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

CalorieWeeklyCheckInViewModel _emptyWeeklyCheckInViewModel() {
  return const CalorieWeeklyCheckInViewModel(
    pendingWeeklyCheckIn: null,
    shouldAutoOpen: false,
    days: <CalorieWeeklyCheckInWindowDay>[],
    calculation: null,
    blockedReason: null,
    missingIntakeDays: <DateTime>[],
    missingWeightDays: <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final end = tester.binding.clock.fromNowBy(timeout);
  while (!condition()) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $description.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required String description,
  Duration timeout = const Duration(seconds: 8),
}) {
  return _pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    description: description,
    timeout: timeout,
  );
}

Future<void> _pumpUntilOnScreen(
  WidgetTester tester,
  Finder finder, {
  required String description,
  Duration timeout = const Duration(seconds: 8),
}) {
  return _pumpUntil(
    tester,
    () => _isFinderCenterOnScreen(tester, finder),
    description: description,
    timeout: timeout,
  );
}

bool _isFinderCenterOnScreen(WidgetTester tester, Finder finder) {
  if (finder.evaluate().isEmpty) {
    return false;
  }
  final center = tester.getCenter(finder);
  final view = tester.view;
  final logicalSize = Size(
    view.physicalSize.width / view.devicePixelRatio,
    view.physicalSize.height / view.devicePixelRatio,
  );
  return (Offset.zero & logicalSize).contains(center);
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  inventoryBackedCalorieEntrySaveFlow,
])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('diary breakfast quick add waits for household inventory', (
    tester,
  ) async {
    final harness = _buildHarness();
    await tester.pumpWidget(harness.app);
    await tester.pump();

    final breakfastAddButton = find.byKey(
      const Key('diary_quick_add_button_breakfast'),
    );
    await tester.scrollUntilVisible(
      breakfastAddButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    await tester.tap(breakfastAddButton);
    final inventorySource = find.byKey(
      const Key('diary_quick_add_source_inventory'),
    );
    await _pumpUntilFound(
      tester,
      inventorySource,
      description: 'inventory quick-add source',
    );

    await tester.tap(inventorySource);
    await tester.pump();

    expect(find.text('Aus Vorrat essen'), findsNothing);
    expect(find.text('Brötchen'), findsNothing);

    harness.profileController.add(
      const UserProfile(uid: 'user-1', householdId: 'household-1'),
    );
    await _pumpUntilFound(
      tester,
      find.text('Brötchen'),
      description: 'household inventory item',
    );

    expect(find.text('Aus Vorrat essen'), findsOneWidget);
    expect(find.text('Brötchen'), findsOneWidget);

    await tester.tap(find.text('Brötchen'));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      description: 'inventory item eat sheet',
    );

    expect(find.text('Brötchen'), findsOneWidget);
    expect(find.text('Frühstück'), findsWidgets);
    expect(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
      findsOneWidget,
    );
  });

  testWidgets('diary breakfast quick add waits for household prepared meals', (
    tester,
  ) async {
    final harness = _buildHarness(
      inventoryItems: const <InventoryItem>[],
      preparedMeals: [
        _preparedMeal(id: 'meal-1', name: 'Chili sin Carne'),
      ],
    );
    await tester.pumpWidget(harness.app);
    await tester.pump();

    final breakfastAddButton = find.byKey(
      const Key('diary_quick_add_button_breakfast'),
    );
    await tester.scrollUntilVisible(
      breakfastAddButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    await tester.tap(breakfastAddButton);
    final inventorySource = find.byKey(
      const Key('diary_quick_add_source_inventory'),
    );
    await _pumpUntilFound(
      tester,
      inventorySource,
      description: 'inventory quick-add source',
    );

    await tester.tap(inventorySource);
    await tester.pump();

    expect(find.text('Aus Vorrat essen'), findsNothing);
    expect(find.text('Chili sin Carne'), findsNothing);

    harness.profileController.add(
      const UserProfile(uid: 'user-1', householdId: 'household-1'),
    );
    await _pumpUntilFound(
      tester,
      find.text('Chili sin Carne'),
      description: 'household prepared meal',
    );

    expect(find.text('Aus Vorrat essen'), findsOneWidget);
    expect(find.text('Chili sin Carne'), findsOneWidget);

    await tester.tap(find.text('Chili sin Carne'));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('prepared_meal_portions_field')),
      description: 'prepared meal eat sheet',
    );

    expect(find.text('Chili sin Carne'), findsOneWidget);
    expect(find.text('Frühstück'), findsWidgets);
    expect(
      find.byKey(const Key('prepared_meal_portions_field')),
      findsOneWidget,
    );

    final confirmButton = find.byKey(
      const Key('prepared_meal_eat_confirm_button'),
    );
    expect(confirmButton, findsOneWidget);
    await _pumpUntilOnScreen(
      tester,
      confirmButton,
      description: 'prepared meal confirm button',
    );
    await tester.tap(confirmButton);
    await _pumpUntil(
      tester,
      () => harness.preparedMealsController.consumedMeals.length == 1,
      description: 'prepared meal consumption',
    );

    expect(harness.preparedMealsController.consumedMeals, hasLength(1));
    final consumption = harness.preparedMealsController.consumedMeals.single;
    expect(consumption.mealId, 'meal-1');
    expect(consumption.consumedPortions, 1);
    expect(consumption.mealType, MealType.breakfast);
  });
}

class _MockUser extends Mock implements User {}

class _StaticBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  const _StaticBurnWeekRunStateRepository();

  @override
  Future<BurnWeekRunState> readState() async {
    return const BurnWeekRunState.initial();
  }

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    return true;
  }
}

class _StaticDiaryCalendarController extends DiaryCalendarController {
  _StaticDiaryCalendarController(this.day);

  final DateTime day;

  @override
  DiaryCalendarState build() {
    final normalizedDay = normalizeDiaryDay(day);
    return DiaryCalendarState(
      today: normalizedDay,
      selectedDay: normalizedDay,
      todayRequest: 0,
    );
  }
}

class _StaticPreparedMealsController extends PreparedMealsController {
  _StaticPreparedMealsController(this.meals);

  final List<PreparedMeal> meals;
  final List<_PreparedMealConsumption> consumedMeals =
      <_PreparedMealConsumption>[];

  @override
  FutureOr<List<PreparedMeal>> build() {
    return meals;
  }

  @override
  Future<bool> consumePreparedMeal({
    required String mealId,
    required num consumedPortions,
    required MealType mealType,
    DateTime? loggedDay,
  }) async {
    consumedMeals.add((
      mealId: mealId,
      consumedPortions: consumedPortions,
      mealType: mealType,
      loggedDay: loggedDay,
    ));
    return true;
  }
}

typedef _PreparedMealConsumption = ({
  String mealId,
  num consumedPortions,
  MealType mealType,
  DateTime? loggedDay,
});

class _OwnerScopedInventoryItemRepository implements InventoryItemRepository {
  const _OwnerScopedInventoryItemRepository({
    required this.ownerId,
    required this.itemsByOwnerId,
  });

  final String? ownerId;
  final Map<String, List<InventoryItem>> itemsByOwnerId;

  @override
  Future<List<InventoryItem>> readAll() async {
    return _itemsForOwner() ?? const <InventoryItem>[];
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    final items = _itemsForOwner();
    if (items == null) {
      return const Stream<List<InventoryItem>>.empty();
    }
    return Stream<List<InventoryItem>>.value(items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  List<InventoryItem>? _itemsForOwner() {
    final resolvedOwnerId = ownerId;
    if (resolvedOwnerId == null) {
      return null;
    }
    return List<InventoryItem>.from(
      itemsByOwnerId[resolvedOwnerId] ?? const <InventoryItem>[],
    );
  }
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 5, 13),
    storeName: 'Bäckerei',
    quantity: 1,
    initialAmount: 100,
    currentAmount: 100,
    amountUnit: InventoryAmountUnit.gram,
    weight: '100g',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 260,
      per100Protein: 8,
      per100Carbs: 52,
      per100Fat: 2,
    ),
  );
}

PreparedMeal _preparedMeal({
  required String id,
  required String name,
}) {
  return PreparedMeal(
    id: id,
    name: name,
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 520,
    totalProtein: 24,
    totalCarbs: 64,
    totalFat: 18,
    createdAt: DateTime(2026, 5, 13),
    updatedAt: DateTime(2026, 5, 13),
    components: const <PreparedMealComponent>[],
  );
}
