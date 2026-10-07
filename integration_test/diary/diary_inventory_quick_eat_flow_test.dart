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
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_inventory_food_picker.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/presentation/diary_plan_details_page.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_inventory_food_picker/diary_inventory_food_picker_status.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_inventory_food_picker/diary_inventory_food_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_plan_days_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_quick_eat_actions.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/home/presentation/widgets/home_action_panel.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_portions_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_when_menu.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/prepared_meal_eat_sheet_body.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/helpers/memory_app_preferences.dart';
import '../../test/helpers/sheet_launcher.dart';

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
    required this.planRepository,
  });

  final Widget app;
  final StreamController<UserProfile?> profileController;
  final FakeCalorieLogRepository logRepository;
  final Map<String, List<InventoryItem>> inventoryItemsByOwnerId;
  final Map<String, List<PreparedMeal>> preparedMealsByOwnerId;
  final FakePlannedEntryRepository planRepository;

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
  DateTime? today,
  DateTime? goalStart,
  List<CalorieEntry> calorieEntries = const <CalorieEntry>[],
  List<CalorieEntry> plans = const <CalorieEntry>[],
}) {
  final profileController = StreamController<UserProfile?>();
  final planRepository = FakePlannedEntryRepository(plans: List.of(plans));
  final user = _MockUser();
  when(() => user.uid).thenReturn(_userId);
  final auth = _MockFirebaseAuth();
  when(() => auth.currentUser).thenReturn(user);
  final logRepository = FakeCalorieLogRepository(
    initialEntries: List<CalorieEntry>.of(calorieEntries),
  );
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2200,
      calculatorProfile: null,
      effectiveDate:
          goalStart ?? _selectedDay.subtract(const Duration(days: 14)),
    ),
  );
  final router = GoRouter(
    initialLocation: AppRoutes.homeCalories,
    routes: [
      GoRoute(
        path: AppRoutes.homeCalories,
        builder: (context, state) {
          // The quick-eat sheet opens from the home bar's action button.
          return const Scaffold(
            body: DiaryPage(),
            bottomNavigationBar: SafeArea(
              child: SheetLauncher(actions: diaryQuickEatActions),
            ),
          );
        },
      ),
      // Stands in for the "Gekocht" page that an open meal leads to.
      GoRoute(
        path: AppRoutes.homeCookedMeal,
        builder: (context, state) =>
            Scaffold(body: Text('cooked:${state.pathParameters['mealId']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(logRepository.dispose);
  addTearDown(settingsRepository.dispose);
  // close() completes only after the stream had a listener, and only the
  // Vorrat picker listens. Scenarios that never open it would hang here.
  addTearDown(() => unawaited(profileController.close()));

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
      plannedEntryRepositoryProvider.overrideWithValue(planRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      calorieWeeklyCheckInDataProvider.overrideWith(
        (ref) => _emptyWeeklyCheckInData(),
      ),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        const _StaticBurnWeekRunStateRepository(),
      ),
      clockProvider.overrideWithValue(
        () => (today ?? _selectedDay).add(const Duration(hours: 12)),
      ),
      diaryCalendarControllerProvider.overrideWith(
        () => _StaticDiaryCalendarController(_selectedDay, today: today),
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
          ownerId: ref.watch(activeHouseholdIdProvider),
          itemsByOwnerId: inventoryItemsByOwnerId,
        ),
      ),
      inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
        _MemoryCommitStore(inventoryItemsByOwnerId, logRepository),
      ),
      preparedMealCalorieEntryCommitStoreProvider.overrideWithValue(
        _MemoryMealCommitStore(
          preparedMealsByOwnerId,
          logRepository,
          saveShouldFail: preparedMealSaveShouldFail,
        ),
      ),
      preparedMealRepositoryProvider.overrideWith(
        (ref) => _OwnerScopedPreparedMealRepository(
          ownerId: ref.watch(activeHouseholdIdProvider),
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
    planRepository: planRepository,
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

/// Waits until the day head shows once: while a slow device switches the
/// head, the old and the new one are both on screen for a moment.
Future<void> _pumpUntilOneHead(WidgetTester tester) {
  return _pumpUntil(
    tester,
    () =>
        find.byKey(DiaryBalanceCardKeys.kcalHeadLabel).evaluate().length == 1 &&
        find.byKey(DiaryBalanceCardKeys.kcalHeadValue).evaluate().length == 1,
    description: 'one day head',
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
  await tester.tap(find.byKey(SheetLauncher.buttonKey));
  await tester.pumpAndSettle();
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
  await _pumpUntil(
    tester,
    () => find.byType(HomeActionPanel).evaluate().isEmpty,
    description: 'closed action panel',
  );
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
  DateTime? today,
}) async {
  final harness = _buildHarness(
    inventoryItems: inventoryItems,
    preparedMeals: preparedMeals,
    preparedMealSaveShouldFail: preparedMealSaveShouldFail,
    today: today,
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

    await _pumpUntilFound(
      tester,
      find.byType(DiaryInventoryFoodPickerLoading),
      description: 'inventory picker loading state',
    );
    expect(find.text('Aus Vorrat essen'), findsOneWidget);
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
    await _pumpUntil(
      tester,
      () => find.text('Aus Vorrat essen').evaluate().isEmpty,
      description: 'inventory picker to close',
    );

    expect(find.text('Brötchen'), findsOneWidget);
    expect(find.textContaining(_currentMealName().toUpperCase()), findsWidgets);
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

    await _pumpUntilFound(
      tester,
      find.byType(DiaryInventoryFoodPickerLoading),
      description: 'inventory picker loading state',
    );
    expect(find.text('Aus Vorrat essen'), findsOneWidget);
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
    await _pumpUntil(
      tester,
      () => find.text('Aus Vorrat essen').evaluate().isEmpty,
      description: 'inventory picker to close',
    );

    expect(find.text('Chili sin Carne'), findsOneWidget);
    expect(find.textContaining(_currentMealName().toUpperCase()), findsWidgets);
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

  testWidgets('a meal in the pot shows greyed out and opens Gekocht', (
    tester,
  ) async {
    final harness = await _pumpAndOpenInventoryQuickEat(
      tester,
      inventoryItems: const <InventoryItem>[],
      preparedMeals: [
        _preparedMeal(id: 'pot-1', name: 'Linsensuppe').copyWith(inPot: true),
      ],
    );
    harness.publishHouseholdProfile();
    final row = find.byKey(DiaryInventoryFoodPicker.mealKey('pot-1'));
    await _pumpUntilFound(tester, row, description: 'meal in the pot');

    expect(tester.widget<DiaryInventoryFoodTile>(row).isMuted, isTrue);
    expect(find.text('Im Topf'), findsOneWidget);

    await tester.tap(row);
    await _pumpUntilFound(
      tester,
      find.text('cooked:pot-1'),
      description: 'Gekocht page of the meal',
    );
    expect(harness.logRepository.entries, isEmpty);
  });

  testWidgets('a meal with open rows opens its detail page to fill them', (
    tester,
  ) async {
    final harness = await _pumpAndOpenInventoryQuickEat(
      tester,
      inventoryItems: const <InventoryItem>[],
      preparedMeals: [
        _preparedMeal(
          id: 'rows-1',
          name: 'Curry',
        ).copyWith(pendingRecipeIngredients: ['Reis']),
      ],
    );
    harness.publishHouseholdProfile();
    final row = find.byKey(DiaryInventoryFoodPicker.mealKey('rows-1'));
    await _pumpUntilFound(tester, row, description: 'meal with open rows');

    expect(tester.widget<DiaryInventoryFoodTile>(row).isMuted, isTrue);
    expect(find.text('1 Zeile offen'), findsOneWidget);

    await tester.tap(row);
    await _pumpUntilFound(
      tester,
      find.byType(PreparedMealEatSheetBody),
      description: 'detail page of the meal',
    );
    expect(harness.logRepository.entries, isEmpty);
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
      await _pumpUntilFound(
        tester,
        find.byType(DiaryInventoryFoodPickerLoading),
        description: 'inventory picker loading state',
      );
      expect(find.text('Aus Vorrat essen'), findsOneWidget);
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

  testWidgets('a Vorrat item on tomorrow is planned and keeps its stock', (
    tester,
  ) async {
    final harness = await _pumpAndOpenInventoryQuickEat(
      tester,
      today: _selectedDay.subtract(const Duration(days: 1)),
    );
    harness.publishHouseholdProfile();
    final item = find.byKey(DiaryInventoryFoodPicker.itemKey('broetchen'));
    await _pumpUntilFound(tester, item, description: 'household item');
    await _pumpUntilOnScreen(tester, item, description: 'visible item');
    await tester.tap(item);
    final confirmButton = find.byKey(_inventoryItemAmountConfirmButtonKey);
    await _pumpUntilFound(
      tester,
      confirmButton,
      description: 'inventory item eat sheet',
    );
    await _pumpUntilOnScreen(
      tester,
      confirmButton,
      description: 'inventory item confirm button',
    );
    await tester.tap(confirmButton);
    await _pumpUntil(
      tester,
      () => harness.planRepository.plans.length == 1,
      description: 'saved plan',
    );

    final plan = harness.planRepository.plans.single;
    expect(plan.sourceInventoryItemId, 'broetchen');
    expect(harness.householdInventoryItems.single.currentAmount, 100);
    expect(harness.logRepository.entries, isEmpty);
    await _pumpUntilFound(
      tester,
      find.byKey(DiaryMealsSectionKeys.plannedEntryTile(plan.id)),
      description: 'plan row of the Vorrat item',
    );
  });

  testWidgets('the plan button plans a Vorrat item on today, and the check '
      'button eats it', (tester) async {
    final harness = await _pumpAndOpenInventoryQuickEat(tester);
    harness.publishHouseholdProfile();
    final item = find.byKey(DiaryInventoryFoodPicker.itemKey('broetchen'));
    await _pumpUntilFound(tester, item, description: 'household item');
    await _pumpUntilOnScreen(tester, item, description: 'visible item');
    await tester.tap(item);
    final planButton = find.byKey(EatPageScaffold.planButtonKey);
    await _pumpUntilFound(tester, planButton, description: 'plan button');
    await tester.tap(planButton);
    // The day picker starts on the selected day; OK plans on it.
    final ok = find.text('OK');
    await _pumpUntilFound(tester, ok, description: 'plan day picker');
    await _pumpUntilOnScreen(tester, ok.last, description: 'picker OK button');
    // Let the picker finish opening, so the tap lands on the button.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(ok.last);
    await _pumpUntil(
      tester,
      () => harness.planRepository.plans.length == 1,
      description: 'saved plan',
    );

    final plan = harness.planRepository.plans.single;
    expect(plan.sourceInventoryItemId, 'broetchen');
    expect(harness.householdInventoryItems.single.currentAmount, 100);
    expect(harness.logRepository.entries, isEmpty);

    // On its day the check button eats the plan from the Vorrat.
    final accept = find.byKey(DiaryMealsSectionKeys.planAcceptButton(plan.id));
    await _pumpUntilFound(tester, accept, description: 'accept button');
    await _pumpUntilOnScreen(tester, accept, description: 'visible accept');
    await tester.tap(accept);
    await _pumpUntil(
      tester,
      () => harness.logRepository.entries.length == 1,
      description: 'accepted entry',
    );
    expect(harness.planRepository.plans, isEmpty);
    expect(
      harness.logRepository.entries.single.sourceInventoryItemId,
      'broetchen',
    );
    await _pumpUntil(
      tester,
      () => harness.householdInventoryItems.single.currentAmount < 100,
      description: 'stock taken',
    );

    // Undo gives the stock back and brings the plan back.
    final undo = find.byType(SnackBarAction).last;
    await _pumpUntilOnScreen(tester, undo, description: 'undo button');
    // Let the snack bar finish sliding in, so the tap lands on the button.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(undo);
    await _pumpUntil(
      tester,
      () => harness.planRepository.plans.length == 1,
      description: 'plan back after undo',
    );
    expect(harness.logRepository.entries, isEmpty);
    expect(harness.householdInventoryItems.single.currentAmount, 100);
  });

  testWidgets('a cooked meal on tomorrow is planned and keeps its portions', (
    tester,
  ) async {
    final harness = await _pumpAndOpenInventoryQuickEat(
      tester,
      inventoryItems: const <InventoryItem>[],
      preparedMeals: [_preparedMeal(id: 'meal-1', name: 'Chili sin Carne')],
      today: _selectedDay.subtract(const Duration(days: 1)),
    );
    harness.publishHouseholdProfile();
    final meal = find.byKey(DiaryInventoryFoodPicker.mealKey('meal-1'));
    await _pumpUntilFound(tester, meal, description: 'household prepared meal');
    await _pumpUntilOnScreen(tester, meal, description: 'visible meal');
    await tester.tap(meal);
    final confirmButton = find.byKey(_preparedMealConfirmButtonKey);
    await _pumpUntilFound(
      tester,
      confirmButton,
      description: 'prepared meal eat sheet',
    );
    await _pumpUntilOnScreen(
      tester,
      confirmButton,
      description: 'prepared meal confirm button',
    );
    await tester.tap(confirmButton);
    await _pumpUntil(
      tester,
      () => harness.planRepository.plans.length == 1,
      description: 'saved plan',
    );

    final plan = harness.planRepository.plans.single;
    expect(plan.bundleSourcePreparedMealId, 'meal-1');
    expect(harness.householdPreparedMeals.single.remainingPortions, 2);
    expect(harness.logRepository.entries, isEmpty);
    final planRow = find.byKey(DiaryMealsSectionKeys.plannedEntryTile(plan.id));
    await _pumpUntilFound(
      tester,
      planRow,
      description: 'plan row of the cooked meal',
    );

    // The plan details change its portions, once the eat sheet has closed.
    await tester.pumpAndSettle();
    await tester.ensureVisible(planRow);
    await tester.pumpAndSettle();
    await tester.tap(planRow);
    final increase = find.byKey(EatMealPortionsRow.increaseKey);
    await _pumpUntilFound(tester, increase, description: 'plan portions');
    await tester.pumpAndSettle();
    await tester.ensureVisible(increase);
    await tester.pumpAndSettle();
    await tester.tap(increase);
    await tester.pump();
    await tester.tap(find.byKey(DiaryPlanDetailsPage.acceptButtonKey));
    await _pumpUntil(
      tester,
      () => harness.planRepository.plans.single.bundleConsumedPortions == 2,
      description: 'plan with two portions',
    );
    expect(harness.planRepository.plans.single.id, plan.id);
    expect(harness.householdPreparedMeals.single.remainingPortions, 2);
  });

  testWidgets('diary shows tomorrow as a plan of its goal', (tester) async {
    final harness = _buildHarness(
      today: _selectedDay.subtract(const Duration(days: 1)),
      calorieEntries: [
        CalorieEntry.create(
          id: 'planned-breakfast',
          userId: _userId,
          name: 'Haferflocken',
          mealType: MealType.breakfast,
          consumedAmount: 100,
          consumedUnit: ConsumedUnit.grams,
          per100Kcal: 900,
          per100Protein: 10,
          per100Carbs: 60,
          per100Fat: 7,
          loggedAt: _selectedDay.add(const Duration(hours: 8)),
          createdAt: _selectedDay,
          updatedAt: _selectedDay,
        ),
      ],
    );
    await tester.pumpWidget(harness.app);
    await _pumpUntilFound(
      tester,
      find.byKey(DiaryBalanceCardKeys.kcalHeadTarget),
      description: 'planned head of tomorrow',
    );

    await _pumpUntilOneHead(tester);
    String textOf(Key key) => tester.widget<Text>(find.byKey(key)).data!;
    expect(textOf(DiaryBalanceCardKeys.kcalHeadLabel), 'GEPLANT');
    expect(textOf(DiaryBalanceCardKeys.kcalHeadValue), '900');
    // The goal without a carryover from today, which is not finished yet.
    expect(textOf(DiaryBalanceCardKeys.kcalHeadTarget), 'von 2.200');
  });

  testWidgets('eat all plans of a meal at once', (tester) async {
    CalorieEntry plan(String id, String name) => CalorieEntry.create(
      id: id,
      userId: _userId,
      name: name,
      mealType: MealType.dinner,
      consumedAmount: 100,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: 300,
      per100Protein: 10,
      per100Carbs: 40,
      per100Fat: 10,
      loggedAt: _selectedDay.add(const Duration(hours: 19)),
      createdAt: _selectedDay,
      updatedAt: _selectedDay,
    );
    final harness = _buildHarness(
      plans: [plan('plan-pasta', 'Nudeln'), plan('plan-salad', 'Salat')],
    );
    await tester.pumpWidget(harness.app);
    // Eating a plan reads the Vorrat, which waits for the household.
    harness.publishHouseholdProfile();
    final acceptAll = find.byKey(
      DiaryMealsSectionKeys.planAcceptAllButton(MealType.dinner),
    );
    await _pumpUntilFound(tester, acceptAll, description: 'eat all button');
    await _pumpUntilOnScreen(tester, acceptAll, description: 'visible button');

    await tester.tap(acceptAll);
    await _pumpUntil(
      tester,
      () => harness.logRepository.entries.length == 2,
      description: 'both plans eaten',
    );
    expect(harness.planRepository.plans, isEmpty);
  });

  testWidgets(
    'a plan on tomorrow counts in its head and its details remove it',
    (tester) async {
      final planRow = find.byKey(
        DiaryMealsSectionKeys.plannedEntryTile('plan-dinner'),
      );
      final harness = _buildHarness(
        today: _selectedDay.subtract(const Duration(days: 1)),
        plans: [
          CalorieEntry.create(
            id: 'plan-dinner',
            userId: _userId,
            name: 'Nudeln',
            mealType: MealType.dinner,
            consumedAmount: 100,
            consumedUnit: ConsumedUnit.grams,
            per100Kcal: 600,
            per100Protein: 20,
            per100Carbs: 90,
            per100Fat: 10,
            loggedAt: _selectedDay.add(const Duration(hours: 19)),
            createdAt: _selectedDay,
            updatedAt: _selectedDay,
          ),
        ],
      );
      await tester.pumpWidget(harness.app);
      await _pumpUntilFound(
        tester,
        planRow,
        description: 'plan row of tomorrow',
      );

      await _pumpUntilOneHead(tester);
      String textOf(Key key) => tester.widget<Text>(find.byKey(key)).data!;
      expect(textOf(DiaryBalanceCardKeys.kcalHeadLabel), 'GEPLANT');
      expect(textOf(DiaryBalanceCardKeys.kcalHeadValue), '600');

      await tester.ensureVisible(planRow);
      await tester.tap(planRow);
      // Before its day the plan cannot be eaten yet.
      final remove = find.byKey(DiaryPlanDetailsPage.removeKey);
      await _pumpUntilFound(tester, remove, description: 'plan details');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(DiaryPlanDetailsPage.acceptButtonKey),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await _pumpUntil(
        tester,
        // The diary is offstage until the details page has closed.
        () =>
            find
                .byKey(DiaryBalanceCardKeys.kcalHeadValue)
                .evaluate()
                .isNotEmpty &&
            textOf(DiaryBalanceCardKeys.kcalHeadValue) == '0',
        description: 'head without the deleted plan',
      );
      expect(planRow, findsNothing);
      expect(harness.planRepository.plans, isEmpty);
    },
  );

  testWidgets('the plan details move a plan of tomorrow to lunch', (
    tester,
  ) async {
    final planRow = find.byKey(
      DiaryMealsSectionKeys.plannedEntryTile('plan-dinner'),
    );
    final harness = _buildHarness(
      today: _selectedDay.subtract(const Duration(days: 1)),
      plans: [
        CalorieEntry.create(
          id: 'plan-dinner',
          userId: _userId,
          name: 'Nudeln',
          mealType: MealType.dinner,
          consumedAmount: 100,
          consumedUnit: ConsumedUnit.grams,
          per100Kcal: 600,
          per100Protein: 20,
          per100Carbs: 90,
          per100Fat: 10,
          loggedAt: _selectedDay.add(const Duration(hours: 19)),
          createdAt: _selectedDay,
          updatedAt: _selectedDay,
        ),
      ],
    );
    await tester.pumpWidget(harness.app);
    await _pumpUntilFound(tester, planRow, description: 'plan row of tomorrow');

    await tester.ensureVisible(planRow);
    await tester.tap(planRow);
    final menu = find.byKey(EatWhenMenu.buttonKey);
    await _pumpUntilFound(tester, menu, description: 'plan details');
    // The details page slides in; the menu takes taps once it is in place.
    await tester.pumpAndSettle();
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EatWhenMenu.mealKey(MealType.lunch)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryPlanDetailsPage.acceptButtonKey));
    await _pumpUntil(
      tester,
      () => harness.planRepository.plans.single.mealType == MealType.lunch,
      description: 'plan moved to lunch',
    );
    await _pumpUntilFound(tester, planRow, description: 'moved plan row');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the plan details plan a plan of tomorrow on one more day', (
    tester,
  ) async {
    final today = _selectedDay.subtract(const Duration(days: 1));
    final planRow = find.byKey(
      DiaryMealsSectionKeys.plannedEntryTile('plan-dinner'),
    );
    final harness = _buildHarness(
      today: today,
      plans: [
        CalorieEntry.create(
          id: 'plan-dinner',
          userId: _userId,
          name: 'Nudeln',
          mealType: MealType.dinner,
          consumedAmount: 100,
          consumedUnit: ConsumedUnit.grams,
          per100Kcal: 600,
          per100Protein: 20,
          per100Carbs: 90,
          per100Fat: 10,
          loggedAt: _selectedDay.add(const Duration(hours: 19)),
          createdAt: _selectedDay,
          updatedAt: _selectedDay,
        ),
      ],
    );
    await tester.pumpWidget(harness.app);
    await _pumpUntilFound(tester, planRow, description: 'plan row of tomorrow');

    await tester.ensureVisible(planRow);
    await tester.tap(planRow);
    final copy = find.byKey(DiaryPlanDetailsPage.copyKey);
    await _pumpUntilFound(tester, copy, description: 'plan details');
    await tester.pumpAndSettle();
    await tester.ensureVisible(copy);
    await tester.pumpAndSettle();
    await tester.tap(copy);
    final dayAfter = DateTime(today.year, today.month, today.day + 2);
    final dayCell = find.byKey(DiaryPlanDaysSheet.dayKey(dayAfter));
    await _pumpUntilFound(tester, dayCell, description: 'days sheet');
    await tester.pumpAndSettle();
    await tester.tap(dayCell);
    await tester.pump();
    await tester.tap(find.byKey(DiaryPlanDaysSheet.confirmKey));
    await _pumpUntil(
      tester,
      () => harness.planRepository.plans.length == 2,
      description: 'copy saved',
    );
    final copied = harness.planRepository.plans.firstWhere(
      (plan) => plan.id != 'plan-dinner',
    );
    expect(
      copied.loggedAt,
      DateTime(dayAfter.year, dayAfter.month, dayAfter.day, 19),
    );
    expect(copied.mealType, MealType.dinner);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the plan details change the amount of a plan of tomorrow', (
    tester,
  ) async {
    final planRow = find.byKey(
      DiaryMealsSectionKeys.plannedEntryTile('plan-dinner'),
    );
    final harness = _buildHarness(
      today: _selectedDay.subtract(const Duration(days: 1)),
      plans: [
        CalorieEntry.create(
          id: 'plan-dinner',
          userId: _userId,
          name: 'Nudeln',
          mealType: MealType.dinner,
          consumedAmount: 100,
          consumedUnit: ConsumedUnit.grams,
          per100Kcal: 600,
          per100Protein: 20,
          per100Carbs: 90,
          per100Fat: 10,
          loggedAt: _selectedDay.add(const Duration(hours: 19)),
          createdAt: _selectedDay,
          updatedAt: _selectedDay,
        ),
      ],
    );
    await tester.pumpWidget(harness.app);
    await _pumpUntilFound(tester, planRow, description: 'plan row of tomorrow');

    await tester.ensureVisible(planRow);
    await tester.tap(planRow);
    final amount = find.descendant(
      of: find.byKey(DiaryPlanDetailsPage.amountKey),
      matching: find.byType(TextField),
    );
    await _pumpUntilFound(tester, amount, description: 'plan amount');
    await tester.pumpAndSettle();
    await tester.enterText(amount, '150');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryPlanDetailsPage.acceptButtonKey));
    await _pumpUntil(
      tester,
      () => harness.planRepository.plans.single.consumedAmount == 150,
      description: 'plan amount saved',
    );
    expect(harness.planRepository.plans.single.totalKcal, 900);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tomorrow plans with the carryover once the day before is '
      'closed', (tester) async {
    final harness = _buildHarness(
      today: _selectedDay.subtract(const Duration(days: 1)),
      // The run started on Sunday, so tomorrow is in its middle.
      goalStart: _selectedDay.subtract(const Duration(days: 10)),
      plans: [
        CalorieEntry.create(
          id: 'plan-breakfast',
          userId: _userId,
          name: 'Brötchen',
          mealType: MealType.breakfast,
          consumedAmount: 100,
          consumedUnit: ConsumedUnit.grams,
          per100Kcal: 300,
          per100Protein: 10,
          per100Carbs: 50,
          per100Fat: 5,
          loggedAt: _selectedDay.add(const Duration(hours: 8)),
          createdAt: _selectedDay,
          updatedAt: _selectedDay,
        ),
      ],
    );
    await tester.pumpWidget(harness.app);
    final closeButton = find.byKey(DiaryBalanceCardKeys.previousDayCloseButton);
    await _pumpUntilFound(
      tester,
      closeButton,
      description: 'close button of the day before',
    );
    await _pumpUntilOneHead(tester);
    String textOf(Key key) => tester.widget<Text>(find.byKey(key)).data!;
    expect(textOf(DiaryBalanceCardKeys.kcalHeadTarget), 'von 2.200');

    await tester.tap(closeButton);
    // Tomorrow then counts like a started day, and its plan still counts.
    await _pumpUntil(
      tester,
      () => textOf(DiaryBalanceCardKeys.kcalHeadLabel) == 'ÜBRIG NACH PLAN',
      description: 'started head after its plan',
    );
    expect(
      find.byKey(DiaryBalanceCardKeys.kcalHeadWithoutPlan),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DiaryBalanceCardKeys.afterPlanChip));
    await _pumpUntil(
      tester,
      () => textOf(DiaryBalanceCardKeys.kcalHeadLabel) == 'ÜBRIG',
      description: 'started head without its plan',
    );
    expect(find.byKey(DiaryBalanceCardKeys.previousDayClosed), findsOneWidget);
    expect(find.byKey(DiaryBalanceCardKeys.kcalHeadTarget), findsNothing);

    await tester.tap(find.byKey(DiaryBalanceCardKeys.previousDayReopenButton));
    await _pumpUntil(
      tester,
      () => textOf(DiaryBalanceCardKeys.kcalHeadLabel) == 'GEPLANT',
      description: 'planned head after reopening',
    );
    expect(textOf(DiaryBalanceCardKeys.kcalHeadTarget), 'von 2.200');
    expect(closeButton, findsOneWidget);
  });

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
  new(this.day, {this.today});

  final DateTime day;

  /// Today when it differs from the selected [day].
  final DateTime? today;

  @override
  DiaryCalendarState build() {
    final normalizedDay = normalizeDiaryDay(day);
    return DiaryCalendarState(
      today: normalizeDiaryDay(today ?? day),
      selectedDay: normalizedDay,
    );
  }
}

/// Takes the stock of an eat from the household's items and saves the
/// entry, like the one Firestore batch does.
class _MemoryCommitStore implements InventoryCalorieEntryCommitStore {
  const new(this.itemsByOwnerId, this.diary);

  final Map<String, List<InventoryItem>> itemsByOwnerId;
  final FakeCalorieLogRepository diary;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) async {
    final items = itemsByOwnerId[_householdId]!;
    final results = <InventoryCalorieEntryCommitResult>[];
    for (final pending in pendingConsumptions) {
      final index = items.indexWhere((item) => item.id == pending.itemId);
      final reduced = items[index].reducedBy(pending.amount)!;
      items[index] = reduced;
      results.add(
        InventoryCalorieEntryCommitResult(
          itemId: reduced.id,
          quantity: reduced.quantity,
          currentAmount: reduced.currentAmount,
        ),
      );
    }
    await diary.saveEntry(entry);
    return results;
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> saveEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async => null;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async {
    final items = itemsByOwnerId[_householdId]!;
    final results = <InventoryCalorieEntryCommitResult>[];
    for (final MapEntry(key: itemId, value: amount)
        in amountsByItemId.entries) {
      final index = items.indexWhere((item) => item.id == itemId);
      final restored = items[index].restoredBy(amount)!;
      items[index] = restored;
      results.add(
        InventoryCalorieEntryCommitResult(
          itemId: restored.id,
          quantity: restored.quantity,
          currentAmount: restored.currentAmount,
        ),
      );
    }
    await diary.deleteEntry(entry.id);
    return results;
  }
}

/// Writes an eaten meal entry with its portions, as the Firestore batch
/// does.
class _MemoryMealCommitStore implements PreparedMealCalorieEntryCommitStore {
  const new(this.mealsByOwnerId, this.diary, {required this.saveShouldFail});

  final Map<String, List<PreparedMeal>> mealsByOwnerId;
  final FakeCalorieLogRepository diary;
  final bool saveShouldFail;

  @override
  Future<bool> commitEntryAndPreparedMeal({required CalorieEntry entry}) async {
    final meals = mealsByOwnerId[_householdId]!;
    final index = meals.indexWhere(
      (meal) => meal.id == entry.bundleSourcePreparedMealId,
    );
    final portions = entry.bundleConsumedPortions ?? 0;
    if (saveShouldFail ||
        index < 0 ||
        !meals[index].allowsPortions(PreparedMealAction.eat, portions)) {
      return false;
    }
    meals[index] = meals[index].withPortionsTaken(portions, entry.updatedAt);
    await diary.saveEntry(entry);
    return true;
  }

  @override
  Future<CalorieEntryDeleteResult> deleteEntryAndRestorePreparedMeal({
    required CalorieEntry entry,
  }) async => const CalorieEntryDeleteResult.failure(
    CalorieEntryDeleteFailureReason.sourceMissing,
  );
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
  Future<bool> save(PreparedMeal meal) => _saveAll([
    for (final stored in _mealsForOwner() ?? const <PreparedMeal>[])
      if (stored.id != meal.id) stored,
    meal,
  ]);

  @override
  Future<bool> delete(String mealId) => _saveAll([
    for (final stored in _mealsForOwner() ?? const <PreparedMeal>[])
      if (stored.id != mealId) stored,
  ]);

  Future<bool> _saveAll(List<PreparedMeal> meals) async {
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
