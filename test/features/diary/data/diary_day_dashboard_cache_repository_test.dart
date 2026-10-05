import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/data/diary_day_dashboard_cache_repository.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  const userId = 'user-1';
  final day = DateTime(2026, 5, 24);

  test('saves and reads dashboard snapshot synchronously', () async {
    final preferences = MemoryAppPreferences();
    const repository = DiaryDayDashboardCacheRepository();
    final data = _dashboardData(day);

    final didSave = await repository.save(
      preferences: preferences,
      userId: userId,
      data: data,
    );
    final cached = repository.readSync(
      preferences: preferences,
      userId: userId,
      day: day,
    );

    expect(didSave, isTrue);
    expect(cached, isNotNull);
    expect(cached!.selectedDay, day);
    expect(cached.selectedDayEntries.single.name, 'Oats');
    expect(cached.mealSections.single.entries.single.name, 'Oats');
    expect(cached.mealSections.single.entries.single.consumedAmount, 60);
    expect(
      cached.mealSections.single.entries.single.consumedUnit,
      ConsumedUnit.grams,
    );
    expect(cached.nutritionBars.carbs, 30);
    expect(cached.nutritionBars.goals, data.nutritionBars.goals);
    expect(
      cached.selectedDayEntries.single.loggedAt,
      data.selectedDayEntries.single.loggedAt,
    );
    expect(cached.runState.toJson(), data.runState.toJson());
  });

  test('returns null for a snapshot without week days', () async {
    final preferences = MemoryAppPreferences();
    const repository = DiaryDayDashboardCacheRepository();
    await repository.save(
      preferences: preferences,
      userId: userId,
      data: _dashboardData(day),
    );
    final json = jsonDecode(
      preferences.getStringSync(_cacheKey(userId, day))!,
    ) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    final overview = data['week_overview'] as Map<String, dynamic>;
    overview['days'] = <dynamic>[];
    await preferences.setString(_cacheKey(userId, day), jsonEncode(json));
    expect(
      repository.readSync(preferences: preferences, userId: userId, day: day),
      isNull,
    );
  });

  test('ignores cache for another user or day', () async {
    final preferences = MemoryAppPreferences();
    const repository = DiaryDayDashboardCacheRepository();
    await repository.save(
      preferences: preferences,
      userId: userId,
      data: _dashboardData(day),
    );

    expect(
      repository.readSync(preferences: preferences, userId: 'user-2', day: day),
      isNull,
    );
    expect(
      repository.readSync(
        preferences: preferences,
        userId: userId,
        day: day.add(const Duration(days: 1)),
      ),
      isNull,
    );
  });

  test('ignores malformed and wrong-version json', () {
    final malformedPreferences = MemoryAppPreferences(
      initialStrings: {_cacheKey(userId, day): '{bad json'},
    );
    final wrongVersionPreferences = MemoryAppPreferences(
      initialStrings: {
        _cacheKey(userId, day): jsonEncode(<String, Object?>{
          'version': 999,
          'user_id': userId,
          'day_key': _dayKey(day),
          'data': _dashboardData(day).toJson(),
        }),
      },
    );
    const repository = DiaryDayDashboardCacheRepository();

    expect(
      repository.readSync(
        preferences: malformedPreferences,
        userId: userId,
        day: day,
      ),
      isNull,
    );
    expect(
      repository.readSync(
        preferences: wrongVersionPreferences,
        userId: userId,
        day: day,
      ),
      isNull,
    );
  });
}

DiaryDayDashboardData _dashboardData(DateTime day) {
  final loggedAt = day.add(const Duration(hours: 8));
  final entry = CalorieEntry(
    isQuickEntry: false,
    id: 'entry-1',
    userId: 'user-1',
    name: 'Oats',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 120,
    per100Protein: 10,
    per100Carbs: 30,
    per100Fat: 4,
    totalKcal: 120,
    totalProtein: 10,
    totalCarbs: 30,
    totalFat: 4,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );

  return DiaryDayDashboardData(
    selectedDay: day,
    refreshedAt: day.add(const Duration(hours: 9)),
    weekOverview: _weekOverview(day),
    selectedDayEntries: [entry],
    plannedEntries: const [],
    countsPlans: false,
    runState: const BurnWeekRunState.initial(),
    mealSections: [
      DiaryMealSection(
        mealType: MealType.breakfast,
        plannedEntries: const [],
        countsPlans: false,
        entries: [
          const DiaryMealEntry(
            id: 'entry-1',
            mealType: MealType.breakfast,
            name: 'Oats',
            totalKcal: 120,
            totalProtein: 10,
            totalCarbs: 30,
            totalFat: 4,
            consumedAmount: 60,
            consumedUnit: ConsumedUnit.grams,
          ),
        ],
        totalKcal: 120,
      ),
    ],
    nutritionBars: const DiaryNutritionBarsData(
      carbs: 30,
      protein: 10,
      fat: 4,
      goals: DiaryMacroTargets(carbs: 250, protein: 120, fat: 70),
    ),
    carryoverMacroDelta: const DiaryMacroTargets(carbs: 0, protein: 0, fat: 0),
  );
}

CalorieWeekOverview _weekOverview(DateTime day) {
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: day.subtract(Duration(days: offset)),
        totalKcal: offset == 0 ? 120 : 0,
        goalKcal: 2000,
        entryCount: offset == 0 ? 1 : 0,
      ),
  ];

  return CalorieWeekOverview(
    isPreviousDayClosed: false,
    days: days,
    totalConsumedKcal: 120,
    totalGoalKcal: 14000,
    remainingKcal: 13880,
    balanceStartDate: day.subtract(const Duration(days: 6)),
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: 2000,
    goalStartsInFuture: false,
    nextGoalStartDate: null,
    futureGoalKcal: null,
  );
}

String _cacheKey(String userId, DateTime day) {
  return 'diary_day_dashboard_v4:$userId:${_dayKey(day)}';
}

String _dayKey(DateTime day) => diaryDayKey(day);
