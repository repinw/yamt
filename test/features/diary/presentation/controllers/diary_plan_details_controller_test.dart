import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_details_controller.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/prepared_meal_diary_entry.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../support/diary_dashboard_test_support.dart';

PreparedMeal _meal({int total = 3, num remaining = 3}) => PreparedMeal(
  id: 'chili',
  name: 'Chili',
  totalPortions: total,
  remainingPortions: remaining,
  totalKcal: 600,
  totalProtein: 30,
  totalCarbs: 60,
  totalFat: 15,
  createdAt: DateTime(2026, 10, 5),
  updatedAt: DateTime(2026, 10, 5),
  components: const [],
);

void main() {
  final today = DateTime(2026, 10, 5);
  final plan = buildConsumedPreparedMealCalorieEntry(
    meal: _meal(),
    consumedPortions: 1,
    mealType: MealType.dinner,
    now: () => DateTime(2026, 10, 5, 12),
    nextEntryId: () => 'meal-plan',
    loggedDay: DateTime(2026, 10, 6),
  )!;
  final planDay = DateTime(2026, 10, 6);

  ProviderContainer setUp(Stream<List<PreparedMeal>> meals) {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 5, 13)),
        inventoryQuickEatMealsProvider.overrideWith((ref) => meals),
        diaryDayDashboardControllerProvider(planDay).overrideWithValue(
          diaryDashboardLoadedStateForTest(
            selectedDay: planDay,
            plannedEntries: [plan],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      diaryPlanDetailsControllerProvider(plan.id, planDay, today),
      (_, _) {},
    );
    return container;
  }

  test('a plan as stored is eaten as is', () async {
    final container = setUp(Stream.value([_meal()]));
    await pumpEventQueue();

    final state = container.read(
      diaryPlanDetailsControllerProvider(plan.id, planDay, today),
    )!;
    expect(state.isChanged, isFalse);
    expect(state.portions, 1);
    expect(state.maxPortions, 3);
  });

  test('other portions change the plan, kept on its day and meal', () async {
    final container = setUp(Stream.value([_meal()]));
    await pumpEventQueue();
    final provider = diaryPlanDetailsControllerProvider(
      plan.id,
      planDay,
      today,
    );

    container.read(provider.notifier)
      ..setPortions(2)
      ..setMealType(MealType.lunch);

    final state = container.read(provider)!;
    expect(state.isChanged, isTrue);
    expect(state.preview.totalKcal, 400);
    expect(state.changed.id, plan.id);
    expect(state.changed.loggedAt, plan.loggedAt);
    expect(state.changed.mealType, MealType.lunch);
    expect(state.changed.bundleConsumedPortions, 2);
  });

  test('a picked day keeps the time of day', () async {
    final container = setUp(Stream.value([_meal()]));
    final provider = diaryPlanDetailsControllerProvider(
      plan.id,
      planDay,
      today,
    );

    container.read(provider.notifier).setDay(DateTime(2026, 10, 9));

    final loggedAt = container.read(provider)!.changed.loggedAt;
    expect(loggedAt.day, 9);
    expect(loggedAt.hour, plan.loggedAt.hour);
    expect(loggedAt.minute, plan.loggedAt.minute);
  });

  test('a meal portioned anew counts the plan in its new portions', () async {
    final container = setUp(Stream.value([_meal(total: 6, remaining: 6)]));
    await pumpEventQueue();

    final state = container.read(
      diaryPlanDetailsControllerProvider(plan.id, planDay, today),
    )!;
    expect(state.portions, 2);
    expect(state.isChanged, isFalse);
  });

  test('a meal that leaves the Vorrat hides the counter', () async {
    final meals = StreamController<List<PreparedMeal>>();
    addTearDown(meals.close);
    final container = setUp(meals.stream);
    final provider = diaryPlanDetailsControllerProvider(
      plan.id,
      planDay,
      today,
    );
    meals.add([_meal()]);
    await pumpEventQueue();
    container.read(provider.notifier).setPortions(2);

    meals.add(const []);
    await pumpEventQueue();

    final state = container.read(provider)!;
    expect(state.portions, isNull);
    expect(state.isChanged, isFalse);
  });

  test('a plan gone from its day leaves no state', () async {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 5, 13)),
        diaryDayDashboardControllerProvider(planDay).overrideWithValue(
          diaryDashboardLoadedStateForTest(selectedDay: planDay),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(
        diaryPlanDetailsControllerProvider('gone', planDay, today),
      ),
      isNull,
    );
  });

  group('the day changes while the page is open', () {
    late FakeDiaryDayDashboardController day;
    late ProviderContainer container;
    final provider = diaryPlanDetailsControllerProvider(
      'meal-plan',
      DateTime(2026, 10, 6),
      DateTime(2026, 10, 5),
    );

    void setUpDay(PreparedMeal meal) {
      day = FakeDiaryDayDashboardController(
        diaryDashboardLoadedStateForTest(
          selectedDay: planDay,
          plannedEntries: [plan],
        ),
      );
      container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 5, 13)),
          inventoryQuickEatMealsProvider.overrideWith(
            (ref) => Stream.value([meal]),
          ),
          diaryDayDashboardControllerProvider(planDay).overrideWith(() => day),
        ],
      );
      addTearDown(container.dispose);
      container.listen(provider, (_, _) {});
    }

    test('a reload without data keeps the page and its picks', () async {
      setUpDay(_meal());
      await pumpEventQueue();
      container.read(provider.notifier).setPortions(2);

      replaceFakeDiaryDashboardState(
        day,
        const DiaryDayDashboardState(
          data: null,
          isFromCache: false,
          isRefreshing: true,
          error: null,
        ),
      );

      expect(container.read(provider)?.portions, 2);
    });

    test('a plan moved elsewhere moves the page along', () async {
      setUpDay(_meal());
      await pumpEventQueue();

      final moved = plan.copyWith(mealType: MealType.lunch);
      replaceFakeDiaryDashboardState(
        day,
        diaryDashboardLoadedStateForTest(
          selectedDay: planDay,
          plannedEntries: [moved],
        ),
      );

      final state = container.read(provider)!;
      expect(state.mealType, MealType.lunch);
      expect(state.isChanged, isFalse);
    });

    test('picked portions never exceed what the meal has left', () async {
      setUpDay(_meal(remaining: 1));
      await pumpEventQueue();

      container.read(provider.notifier).setPortions(3);

      expect(container.read(provider)?.portions, 1);
    });
  });

  test('an amount the user did not type follows the plan', () {
    CalorieEntry oats(double grams) => CalorieEntry.create(
      id: 'oats',
      userId: 'user-1',
      name: 'Oats',
      mealType: MealType.breakfast,
      consumedAmount: grams,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: 370,
      per100Protein: 13,
      per100Carbs: 59,
      per100Fat: 7,
      loggedAt: DateTime(2026, 10, 6, 8),
      createdAt: DateTime(2026, 10, 5),
      updatedAt: DateTime(2026, 10, 5),
    );
    final day = FakeDiaryDayDashboardController(
      diaryDashboardLoadedStateForTest(
        selectedDay: planDay,
        plannedEntries: [oats(200)],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 5, 13)),
        diaryDayDashboardControllerProvider(planDay).overrideWith(() => day),
      ],
    );
    addTearDown(container.dispose);
    final provider = diaryPlanDetailsControllerProvider('oats', planDay, today);
    container.listen(provider, (_, _) {});

    replaceFakeDiaryDashboardState(
      day,
      diaryDashboardLoadedStateForTest(
        selectedDay: planDay,
        plannedEntries: [oats(300)],
      ),
    );

    final state = container.read(provider)!;
    expect(state.amount.amountText, '300');
    expect(state.isChanged, isFalse);
  });
}
