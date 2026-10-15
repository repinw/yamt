import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/prepared_meal_diary_entry.dart';
import 'package:yamt/features/inventory/application/prepared_meal_reminder_plan_service.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../../support/prepared_meal_test_data.dart';
import '../../calories/support/fake_planned_entry_repository.dart';

class _MockMeals extends Mock implements PreparedMealRepository;

final _now = DateTime(2026, 10, 15, 9);

/// 4 portions with 800 kcal; "Salz" is still open.
PreparedMeal _open() => preparedMealTestData(
  totalPortions: 4,
  remainingPortions: 4,
).copyWith(totalKcal: 800, pendingRecipeIngredients: const ['Salz']);

CalorieEntry _reminder(PreparedMeal meal, {String id = 'plan'}) =>
    buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.lunch,
      now: () => _now,
      nextEntryId: () => id,
      loggedDay: DateTime(2026, 10, 16),
    )!;

void main() {
  late FakePlannedEntryRepository plans;
  late _MockMeals meals;
  late ProviderContainer container;

  setUp(() {
    plans = FakePlannedEntryRepository();
    meals = _MockMeals();
    container = ProviderContainer(
      overrides: [
        plannedEntryRepositoryProvider.overrideWithValue(plans),
        preparedMealRepositoryProvider.overrideWithValue(meals),
        clockProvider.overrideWithValue(() => _now),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> refresh(String mealId) =>
      container.read(preparedMealReminderPlanServiceProvider).refresh(mealId);

  test('a meal with open rows plans a reminder without kcal', () {
    final plan = _reminder(_open());

    expect(plan.nutritionPending, isTrue);
    expect(plan.totalKcal, 0);
    expect(plan.totalProtein, 0);
    expect(plan.bundleConsumedPortions, 1);
    expect(CalorieEntry.fromJson(plan.toJson()).nutritionPending, isTrue);
    // Only a reminder stores the key.
    final counted = _reminder(_open().copyWith(pendingRecipeIngredients: []));
    expect(counted.toJson().containsKey('nutrition_pending'), isFalse);
    expect(CalorieEntry.fromJson(counted.toJson()).nutritionPending, isFalse);
  });

  test('the reminders get the values once no row is open', () async {
    final open = _open();
    final reminder = _reminder(open);
    plans.plans.addAll([
      reminder,
      _reminder(open.copyWith(id: 'other'), id: 'other-plan'),
    ]);
    final filled = open.copyWith(pendingRecipeIngredients: const []);
    when(() => meals.readAllForChange()).thenAnswer((_) async => [filled]);
    final revision = container.read(calorieOverviewRevisionProvider);

    await refresh(open.id);

    final counted = plans.plans.firstWhere((plan) => plan.id == 'plan');
    expect(counted.nutritionPending, isFalse);
    expect(counted.totalKcal, 200);
    // It stays on its day and time.
    expect(counted.loggedAt, reminder.loggedAt);
    // A plan of another meal stays a reminder.
    expect(
      plans.plans
          .firstWhere((plan) => plan.id == 'other-plan')
          .nutritionPending,
      isTrue,
    );
    expect(container.read(calorieOverviewRevisionProvider), isNot(revision));
  });

  test('plans turn back into reminders when a row opens again', () async {
    final filled = _open().copyWith(pendingRecipeIngredients: const []);
    plans.plans.add(_reminder(filled));
    expect(plans.plans.single.totalKcal, 200);
    when(() => meals.readAllForChange()).thenAnswer((_) async => [_open()]);

    await refresh(filled.id);

    expect(plans.plans.single.nutritionPending, isTrue);
    expect(plans.plans.single.totalKcal, 0);
  });

  test('the reminders wait while a row is still open', () async {
    final open = _open();
    plans.plans.add(_reminder(open));
    when(() => meals.readAllForChange()).thenAnswer((_) async => [open]);

    await refresh(open.id);

    expect(plans.plans.single.nutritionPending, isTrue);
    expect(plans.plans.single.totalKcal, 0);
  });
}
