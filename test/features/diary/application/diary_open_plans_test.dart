import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/application/diary_open_plans.dart';

import '../support/diary_dashboard_test_support.dart';

final _day = DateTime(2026, 4, 27);

CalorieEntry _plan(double kcal) => CalorieEntry.create(
  id: 'plan-$kcal',
  userId: 'user-1',
  name: 'Plan',
  mealType: MealType.lunch,
  consumedAmount: 100,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: kcal,
  per100Protein: 10,
  per100Carbs: 20,
  per100Fat: 5,
  loggedAt: _day.add(const Duration(hours: 12)),
  createdAt: _day,
  updatedAt: _day,
);

DiaryOpenPlans? _openPlans({
  required DateTime today,
  List<CalorieEntry>? plans,
  bool countsPlans = false,
}) => DiaryOpenPlans.of(
  diaryDashboardLoadedStateForTest(
    selectedDay: _day,
    plannedEntries: plans ?? [_plan(300), _plan(200)],
    countsPlans: countsPlans,
  ).data!,
  today: today,
  counted: true,
);

void main() {
  test('today sums its plans', () {
    final open = _openPlans(today: _day.add(const Duration(hours: 9)))!;

    expect(open.kcal, 500);
    expect(open.protein, 20);
    expect(open.carbs, 40);
    expect(open.fat, 10);
    expect(open.counted, isTrue);
  });

  test('nothing to offer without plans, when they count, once overdue, or '
      'on a planned tomorrow', () {
    expect(_openPlans(today: _day, plans: const []), isNull);
    expect(_openPlans(today: _day, countsPlans: true), isNull);
    expect(_openPlans(today: _day.add(const Duration(days: 1))), isNull);
    // A tomorrow whose day before is open is a plan itself.
    expect(_openPlans(today: _day.subtract(const Duration(days: 1))), isNull);
  });
}
