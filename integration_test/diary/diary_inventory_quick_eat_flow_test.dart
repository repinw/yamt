import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/memory_app_preferences.dart';

final _selectedDay = DateTime(2026, 5, 13);
const _userId = 'user-1';
const _householdId = 'household-1';
const _locale = Locale('de');
const _inventoryItemAmountFieldKey = Key('eat_page_amount_field');
const _inventoryItemAmountConfirmButtonKey = Key(
  'inventory_item_amount_dialog_confirm_button',
);
const _preparedMealPortionsFieldKey = Key('eat_page_amount_field');
const _preparedMealConfirmButtonKey = Key('prepared_meal_eat_confirm_button');

class _DiaryInventoryQuickEatHarness {
  const new({
    required this.app,
    required this.profileController,
    required this.logRepository,
    required this.inventoryItemsByOwnerId,
    required this.preparedMealsByOwnerId,
  });

  final Widget app;
  final StreamController<UserProfile?> profileController;
  final FakeCalorieLogRepository logRepository;
  final Map<String, List<InventoryItem>> inventoryItemsByOwnerId;
  final Map<String, List<PreparedMeal>> preparedMealsByOwnerId;

  List<InventoryItem> get householdInventoryItems {
    return inventoryItemsByOwnerId[_householdId] ?? const <InventoryItem>[];
  }

  List<PreparedMeal> get householdPreparedMeals {
    return preparedMealsByOwnerId[_householdId] ?? const <PreparedMeal>[];
  }

  void publishHouseholdProfile() {
    profileController.add(
      const UserProfile(uid: _userId, householdId: _householdId),
    );
  }
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

_DiaryInventoryQuickEatHarness _buildHarness({
  List<InventoryItem>? inventoryItems,
  List<PreparedMeal> preparedMeals = const <PreparedMeal>[],
  bool preparedMealSaveShouldFail = false,
}) {
  final profileController = StreamController<UserProfile?>();
  final user = _MockUser();
  when(() => user.uid).thenReturn(_userId);
  final auth = _MockFirebaseAuth();
  final logRepository = FakeCalorieLogRepository();
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2200,
      calculatorProfile: null,
      effectiveDate: _selectedDay.subtract(const Duration(days: 14)),
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

  final inventoryItemsByOwnerId = {
    _householdId:
        inventoryItems ?? [_inventoryItem(id: 'broetchen', name: 'Brötchen')],
  };
  final preparedMealsByOwnerId = {
    _householdId: List<PreparedMeal>.from(preparedMeals),
  };

  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
      firebaseAuthProvider.overrideWithValue(auth),
      userProfileProvider.overrideWith((ref) => profileController.stream),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      calorieWeeklyCheckInDataProvider.overrideWith(
        (ref) => _emptyWeeklyCheckInData(),
      ),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        const _StaticBurnWeekRunStateRepository(),
      ),
      diaryCalendarControllerProvider.overrideWith(
        () => _StaticDiaryCalendarController(_selectedDay),
      ),
      healthConnectionServiceProvider.overrideWithValue(
        FakeHealthConnectionService(const HealthConnectionStatus.unsupported()),
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
          itemsByOwnerId: inventoryItemsByOwnerId,
        ),
      ),
      preparedMealRepositoryProvider.overrideWith(
        (ref) => _OwnerScopedPreparedMealRepository(
          ownerId: ref.watch(effectiveHouseholdDataOwnerUserIdProvider),
          mealsByOwnerId: preparedMealsByOwnerId,
          saveShouldFail: preparedMealSaveShouldFail,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  return _DiaryInventoryQuickEatHarness(
    profileController: profileController,
    logRepository: logRepository,
    inventoryItemsByOwnerId: inventoryItemsByOwnerId,
    preparedMealsByOwnerId: preparedMealsByOwnerId,
    app: UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: _locale,
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

CalorieWeeklyCheckInData _emptyWeeklyCheckInData() {
  return const CalorieWeeklyCheckInData(
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

Future<void> _openInventoryQuickEat(WidgetTester tester) async {
  final inventorySource = find.byKey(
    DiaryMealsSectionKeys.quickEatSource(DiaryQuickEatSource.inventory),
  );
  await _pumpUntilFound(
    tester,
    inventorySource,
    description: 'inventory quick-eat source',
  );
  await tester.ensureVisible(inventorySource);
  await tester.pump();

  await tester.tap(inventorySource);
  await tester.pump();
}

/// Meal type the diary preselects for food logged right now.
MealType _currentMealType() => MealType.defaultForDateTime(DateTime.now());

String _currentMealName() =>
    _currentMealType().localizedName(lookupAppLocalizations(_locale));

Future<_DiaryInventoryQuickEatHarness> _pumpAndOpenInventoryQuickEat(
  WidgetTester tester, {
  List<InventoryItem>? inventoryItems,
  List<PreparedMeal> preparedMeals = const <PreparedMeal>[],
  bool preparedMealSaveShouldFail = false,
}) async {
  final harness = _buildHarness(
    inventoryItems: inventoryItems,
    preparedMeals: preparedMeals,
    preparedMealSaveShouldFail: preparedMealSaveShouldFail,
  );
  await tester.pumpWidget(harness.app);
  await tester.pump();
  await _openInventoryQuickEat(tester);
  return harness;
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('diary quick eat waits for household inventory', (tester) async {
    final harness = await _pumpAndOpenInventoryQuickEat(tester);

    expect(find.text('Aus Vorrat essen'), findsNothing);
    expect(find.text('Brötchen'), findsNothing);

    harness.publishHouseholdProfile();
    await _pumpUntilFound(
      tester,
      find.text('Brötchen'),
      description: 'household inventory item',
    );
    await _pumpUntilOnScreen(
      tester,
      find.text('Brötchen'),
      description: 'visible household inventory item',
    );

    expect(find.text('Aus Vorrat essen'), findsOneWidget);
    expect(find.text('Brötchen'), findsOneWidget);

    await tester.tap(find.text('Brötchen'));
    await _pumpUntilFound(
      tester,
      find.byKey(_inventoryItemAmountFieldKey),
      description: 'inventory item eat sheet',
    );

    expect(find.text('Brötchen'), findsOneWidget);
    expect(find.text(_currentMealName()), findsWidgets);
    expect(find.byKey(_inventoryItemAmountFieldKey), findsOneWidget);
    expect(find.byKey(_inventoryItemAmountConfirmButtonKey), findsOneWidget);
  });

  testWidgets('diary quick eat waits for household prepared meals', (
    tester,
  ) async {
    final harness = await _pumpAndOpenInventoryQuickEat(
      tester,
      inventoryItems: const <InventoryItem>[],
      preparedMeals: [_preparedMeal(id: 'meal-1', name: 'Chili sin Carne')],
    );

    expect(find.text('Aus Vorrat essen'), findsNothing);
    expect(find.text('Chili sin Carne'), findsNothing);

    harness.publishHouseholdProfile();
    await _pumpUntilFound(
      tester,
      find.text('Chili sin Carne'),
      description: 'household prepared meal',
    );
    await _pumpUntilOnScreen(
      tester,
      find.text('Chili sin Carne'),
      description: 'visible household prepared meal',
    );

    expect(find.text('Aus Vorrat essen'), findsOneWidget);
    expect(find.text('Chili sin Carne'), findsOneWidget);

    await tester.tap(find.text('Chili sin Carne'));
    await _pumpUntilFound(
      tester,
      find.byKey(_preparedMealPortionsFieldKey),
      description: 'prepared meal eat sheet',
    );

    expect(find.text('Chili sin Carne'), findsOneWidget);
    expect(find.text(_currentMealName()), findsWidgets);
    expect(find.byKey(_preparedMealPortionsFieldKey), findsOneWidget);

    final confirmButton = find.byKey(_preparedMealConfirmButtonKey);
    expect(confirmButton, findsOneWidget);
    await _pumpUntilOnScreen(
      tester,
      confirmButton,
      description: 'prepared meal confirm button',
    );
    await tester.tap(confirmButton);
    await _pumpUntil(
      tester,
      () =>
          harness.householdPreparedMeals.single.remainingPortions == 1 &&
          harness.logRepository.entries.length == 1,
      description: 'prepared meal consumption',
    );

    expect(harness.householdPreparedMeals.single.remainingPortions, 1);
    expect(harness.logRepository.entries, hasLength(1));
    expect(harness.logRepository.entries.single.name, 'Chili sin Carne');
    expect(harness.logRepository.entries.single.mealType, _currentMealType());
  });

  testWidgets(
    'diary inventory quick add shows empty state after provider load',
    (tester) async {
      final harness = await _pumpAndOpenInventoryQuickEat(
        tester,
        inventoryItems: [
          _inventoryItem(
            id: 'empty-broetchen',
            name: 'Leeres Brötchen',
            currentAmount: 0,
          ),
        ],
      );
      expect(find.text('Aus Vorrat essen'), findsNothing);
      expect(find.text('Leeres Brötchen'), findsNothing);

      harness.publishHouseholdProfile();
      await _pumpUntilFound(
        tester,
        find.text('Kein verfügbares Essen im Vorrat.'),
        description: 'loaded inventory empty state',
      );

      expect(find.text('Aus Vorrat essen'), findsOneWidget);
      expect(find.text('Leeres Brötchen'), findsNothing);
    },
  );

  testWidgets(
    'diary inventory quick add shows action error without nutrition',
    (tester) async {
      final harness = await _pumpAndOpenInventoryQuickEat(
        tester,
        inventoryItems: [
          _inventoryItem(
            id: 'no-nutrition',
            name: 'Mystery Snack',
            nutrition: null,
          ),
        ],
      );
      harness.publishHouseholdProfile();
      await _pumpUntilFound(
        tester,
        find.text('Mystery Snack'),
        description: 'inventory item without nutrition',
      );
      await _pumpUntilOnScreen(
        tester,
        find.text('Mystery Snack'),
        description: 'visible inventory item without nutrition',
      );

      await tester.tap(find.text('Mystery Snack'));
      await _pumpUntilFound(
        tester,
        find.byKey(_inventoryItemAmountConfirmButtonKey),
        description: 'inventory item eat sheet',
      );

      final confirmButton = find.byKey(_inventoryItemAmountConfirmButtonKey);
      await _pumpUntilOnScreen(
        tester,
        confirmButton,
        description: 'inventory item confirm button',
      );
      await tester.tap(confirmButton);
      await _pumpUntilFound(
        tester,
        find.text('Aktion fehlgeschlagen. Bitte erneut versuchen.'),
        description: 'inventory item action failed snackbar',
      );
      expect(harness.householdInventoryItems, hasLength(1));
      expect(harness.householdInventoryItems.single.currentAmount, 100);
      expect(harness.logRepository.entries, isEmpty);
    },
  );

  testWidgets('diary prepared meal quick add shows save failure snackbar', (
    tester,
  ) async {
    final harness = await _pumpAndOpenInventoryQuickEat(
      tester,
      inventoryItems: const <InventoryItem>[],
      preparedMeals: [_preparedMeal(id: 'meal-fail', name: 'Gulasch')],
      preparedMealSaveShouldFail: true,
    );
    harness.publishHouseholdProfile();
    await _pumpUntilFound(
      tester,
      find.text('Gulasch'),
      description: 'prepared meal with failing save',
    );
    await _pumpUntilOnScreen(
      tester,
      find.text('Gulasch'),
      description: 'visible prepared meal with failing save',
    );

    await tester.tap(find.text('Gulasch'));
    await _pumpUntilFound(
      tester,
      find.byKey(_preparedMealConfirmButtonKey),
      description: 'prepared meal eat sheet',
    );

    final confirmButton = find.byKey(_preparedMealConfirmButtonKey);
    await _pumpUntilOnScreen(
      tester,
      confirmButton,
      description: 'prepared meal confirm button',
    );
    await tester.tap(confirmButton);
    await _pumpUntilFound(
      tester,
      find.text('Mahlzeit-Aktion fehlgeschlagen. Bitte versuche es erneut.'),
      description: 'prepared meal action failed snackbar',
    );

    expect(harness.householdPreparedMeals.single.remainingPortions, 2);
    expect(harness.logRepository.entries, isEmpty);
  });
}

class _MockUser extends Mock implements User;

class _StaticBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  const new();

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
  new(this.day);

  final DateTime day;

  @override
  DiaryCalendarState build() {
    final normalizedDay = normalizeDiaryDay(day);
    return DiaryCalendarState(today: normalizedDay, selectedDay: normalizedDay);
  }
}

class _OwnerScopedInventoryItemRepository implements InventoryItemRepository {
  const new({required this.ownerId, required this.itemsByOwnerId});

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
    final resolvedOwnerId = ownerId;
    if (resolvedOwnerId == null) {
      return false;
    }
    itemsByOwnerId[resolvedOwnerId] = List<InventoryItem>.from(items);
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    final resolvedOwnerId = ownerId;
    if (resolvedOwnerId == null) {
      return false;
    }
    itemsByOwnerId[resolvedOwnerId] = [
      ...(itemsByOwnerId[resolvedOwnerId] ?? const <InventoryItem>[]),
      ...items,
    ];
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

class _OwnerScopedPreparedMealRepository implements PreparedMealRepository {
  const new({
    required this.ownerId,
    required this.mealsByOwnerId,
    required this.saveShouldFail,
  });

  final String? ownerId;
  final Map<String, List<PreparedMeal>> mealsByOwnerId;
  final bool saveShouldFail;

  @override
  Future<List<PreparedMeal>> readAll() async {
    return _mealsForOwner() ?? const <PreparedMeal>[];
  }

  @override
  Stream<List<PreparedMeal>> watchAll() {
    final meals = _mealsForOwner();
    if (meals == null) {
      return const Stream<List<PreparedMeal>>.empty();
    }
    return Stream<List<PreparedMeal>>.value(meals);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async {
    if (saveShouldFail) {
      return false;
    }
    final resolvedOwnerId = ownerId;
    if (resolvedOwnerId == null) {
      return false;
    }
    mealsByOwnerId[resolvedOwnerId] = List<PreparedMeal>.from(meals);
    return true;
  }

  List<PreparedMeal>? _mealsForOwner() {
    final resolvedOwnerId = ownerId;
    if (resolvedOwnerId == null) {
      return null;
    }
    return List<PreparedMeal>.from(
      mealsByOwnerId[resolvedOwnerId] ?? const <PreparedMeal>[],
    );
  }
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  int quantity = 1,
  int initialAmount = 100,
  int currentAmount = 100,
  GlobalFoodNutrition? nutrition = const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 260,
    per100Protein: 8,
    per100Carbs: 52,
    per100Fat: 2,
  ),
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 5, 13),
    storeName: 'Bäckerei',
    quantity: quantity,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.gram,
    weight: '100g',
    nutrition: nutrition,
  );
}

PreparedMeal _preparedMeal({required String id, required String name}) {
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
