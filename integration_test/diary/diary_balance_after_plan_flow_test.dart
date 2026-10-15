import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/presentation/diary_plan_details_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_entry_label_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_nutrition_bars/diary_nutrition_bars_content.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/helpers/memory_app_preferences.dart';

// The goal starts today, so no earlier day of the run moves its target.
final _today = DateTime(2026, 5, 13);
const _userId = 'user-1';

CalorieEntry _food({
  required String id,
  required String name,
  required MealType mealType,
  required int hour,
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
}) {
  return CalorieEntry.create(
    id: id,
    userId: _userId,
    name: name,
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: protein,
    per100Carbs: carbs,
    per100Fat: fat,
    loggedAt: _today.add(Duration(hours: hour)),
    createdAt: _today,
    updatedAt: _today,
  );
}

/// Shows the diary of today with a lunch of 1,000 kcal eaten and [planned].
Future<void> _pumpDiary(
  WidgetTester tester, {
  required List<CalorieEntry> planned,
}) async {
  final log = FakeCalorieLogRepository(
    initialEntries: [
      _food(
        id: 'lunch',
        name: 'Linsensuppe',
        mealType: MealType.lunch,
        hour: 11,
        kcal: 1000,
        protein: 50,
        carbs: 100,
        fat: 30,
      ),
    ],
  );
  final plans = FakePlannedEntryRepository(plans: planned);
  final settings = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: _today,
    ),
  );
  addTearDown(log.dispose);
  addTearDown(settings.dispose);
  final user = _MockUser();
  when(() => user.uid).thenReturn(_userId);
  final auth = _MockFirebaseAuth();
  when(() => auth.currentUser).thenReturn(user);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        clockProvider.overrideWithValue(
          () => _today.add(const Duration(hours: 12)),
        ),
        firebaseAuthProvider.overrideWithValue(auth),
        // A value, not a stream: a stream stays paused under a route.
        authStateChangesProvider.overrideWithValue(AsyncData(user)),
        userProfileProvider.overrideWithValue(
          const AsyncData(UserProfile(uid: _userId)),
        ),
        calorieLogRepositoryProvider.overrideWithValue(log),
        plannedEntryRepositoryProvider.overrideWithValue(plans),
        calorieSettingsRepositoryProvider.overrideWithValue(settings),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          const _StaticBurnWeekRunStateRepository(),
        ),
        healthConnectionServiceProvider.overrideWithValue(
          FakeHealthConnectionService(
            const HealthConnectionStatus.unsupported(),
          ),
        ),
        healthWeightServiceProvider.overrideWithValue(
          FakeHealthWeightService(const []),
        ),
        manualHealthWeightRepositoryProvider.overrideWithValue(
          FakeManualHealthWeightRepository(const []),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DiaryPage()),
      ),
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('after plan counts the open plans in the eaten totals until '
      'the chip is off', (tester) async {
    await _pumpDiary(
      tester,
      planned: [
        _food(
          id: 'plan-dinner',
          name: 'Nudeln',
          mealType: MealType.dinner,
          hour: 19,
          kcal: 500,
          protein: 20,
          carbs: 60,
          fat: 10,
        ),
      ],
    );
    final chip = find.byKey(DiaryBalanceCardKeys.afterPlanChip);
    await _pumpUntil(
      tester,
      () => chip.evaluate().length == 1,
      description: 'the after plan chip of today',
    );
    await tester.pumpAndSettle();

    String textOf(Key key) => tester.widget<Text>(find.byKey(key)).data!;
    // "Nach Plan" is on by default; a tap on the head shows the details.
    expect(textOf(DiaryBalanceCardKeys.kcalHeadValue), '500');
    expect(find.byKey(DiaryBalanceCardKeys.kcalHeadEaten), findsNothing);
    await tester.tap(find.byKey(DiaryBalanceCardKeys.kcalHeadValue));
    await tester.pumpAndSettle();

    expect(textOf(DiaryBalanceCardKeys.kcalHeadEaten), '1.500 mit Plan');
    // The default split of 2,000 kcal: 156 g protein, 200 g carbs, 64 g fat.
    expect(textOf(DiaryNutritionBarsContent.proteinTotalKey), '70 / 156 g');
    expect(textOf(DiaryNutritionBarsContent.carbsTotalKey), '160 / 200 g');
    expect(textOf(DiaryNutritionBarsContent.fatTotalKey), '40 / 64 g');

    // The budget details count the plans the same way.
    await tester.tap(find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsButton));
    await tester.pumpAndSettle();
    expect(
      find.byKey(DiaryBalanceCardKeys.dailyBudgetPlannedRow),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(DiaryBalanceCardKeys.dailyBudgetLeftRow),
        matching: find.text('500 kcal'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(textOf(DiaryBalanceCardKeys.kcalHeadValue), '1.000');
    expect(textOf(DiaryBalanceCardKeys.kcalHeadEaten), '1.000 gegessen');
    expect(textOf(DiaryNutritionBarsContent.proteinTotalKey), '50 / 156 g');
    expect(textOf(DiaryNutritionBarsContent.carbsTotalKey), '100 / 200 g');
    expect(textOf(DiaryNutritionBarsContent.fatTotalKey), '30 / 64 g');

    // Without "Nach Plan" the budget details stay at what was eaten.
    await tester.tap(find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsButton));
    await tester.pumpAndSettle();
    expect(
      find.byKey(DiaryBalanceCardKeys.dailyBudgetPlannedRow),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(DiaryBalanceCardKeys.dailyBudgetLeftRow),
        matching: find.text('1.000 kcal'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a reminder plan says its kcal are open and counts nowhere', (
    tester,
  ) async {
    final reminder = _food(
      id: 'plan-curry',
      name: 'Curry',
      mealType: MealType.dinner,
      hour: 19,
      kcal: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
    ).copyWith(nutritionPending: true);
    await _pumpDiary(tester, planned: [reminder]);
    final row = find.byKey(
      DiaryMealsSectionKeys.plannedEntryTile('plan-curry'),
    );
    await _pumpUntil(
      tester,
      () => row.evaluate().length == 1,
      description: 'the reminder row',
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: row, matching: find.text('kcal offen')),
      findsOneWidget,
    );
    // Nothing to count, so no "Nach Plan".
    expect(find.byKey(DiaryBalanceCardKeys.afterPlanChip), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(DiaryBalanceCardKeys.kcalHeadValue)).data,
      '1.000',
    );

    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(DiaryPlanDetailsPage), findsOneWidget);
    expect(find.byType(DiaryEntryLabelSection), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
}) async {
  final end = tester.binding.clock.fromNowBy(const Duration(seconds: 8));
  while (!condition()) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $description.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _MockUser extends Mock implements User;

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

/// Keeps the run where the goal starts: live sync reads the real date, which
/// would move a stored run away from the fixed clock.
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
