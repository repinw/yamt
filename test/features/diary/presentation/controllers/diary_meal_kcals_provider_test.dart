import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_kcals_provider.dart';

final _day = DateTime(2026, 4, 27);

class _LoadingDashboard extends DiaryDayDashboardController {
  @override
  DiaryDayDashboardState build(DateTime selectedDay) =>
      const DiaryDayDashboardState(
        data: null,
        isFromCache: false,
        isRefreshing: true,
        error: null,
      );
}

DiaryMealEntry _entry(String id, double kcal, {bool pending = false}) =>
    DiaryMealEntry(
      id: id,
      mealType: MealType.lunch,
      name: id,
      totalKcal: kcal,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      nutritionPending: pending,
    );

/// Lunch with 600 kcal eaten and a 400 kcal plan, plus a plan whose
/// nutrition is still pending.
DiaryMealSection _lunch({required bool countsPlans}) => DiaryMealSection(
  mealType: MealType.lunch,
  entries: [_entry('soup', 250), _entry('bread', 350)],
  plannedEntries: [_entry('pasta', 400), _entry('later', 300, pending: true)],
  countsPlans: countsPlans,
  totalKcal: countsPlans ? 1000 : 600,
);

void main() {
  test('is null while the day loads', () {
    final container = ProviderContainer(
      overrides: [
        diaryDayDashboardControllerProvider(_day)
            .overrideWith(_LoadingDashboard.new),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(diaryMealKcalsProvider(_day)), isNull);
  });

  test('a plan that does not count adds nothing to the meal', () {
    final [meal] = diaryMealKcalsOf([
      _lunch(countsPlans: false),
    ], withOpenPlans: false);

    expect(meal.mealType, MealType.lunch);
    expect(meal.eaten, 600);
    expect(meal.planned, 0);
  });

  test('open plans the user counts add their kcal, pending ones not', () {
    final [meal] = diaryMealKcalsOf([
      _lunch(countsPlans: false),
    ], withOpenPlans: true);

    expect(meal.eaten, 600);
    expect(meal.planned, 400);
    expect(meal.total, 1000);
  });

  test('on a planned day the plans are part of the heading total', () {
    final [meal] = diaryMealKcalsOf([
      _lunch(countsPlans: true),
    ], withOpenPlans: false);

    expect(meal.eaten, 600);
    expect(meal.planned, 400);
  });
}
