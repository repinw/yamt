import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

/// Render-ready diary dashboard data for one selected day.
class DiaryDayDashboardData {
  /// Creates diary dashboard data.
  const DiaryDayDashboardData({
    required this.selectedDay,
    required this.refreshedAt,
    required this.weekOverview,
    required this.selectedDayEntries,
    required this.runState,
    required this.mealSections,
    required this.nutritionBars,
  });

  /// Creates data from persisted cache json.
  factory DiaryDayDashboardData.fromJson(Map<String, dynamic> json) {
    return DiaryDayDashboardData(
      selectedDay: _readDate(json['selected_day']),
      refreshedAt: _readDate(json['refreshed_at']),
      weekOverview: _weekOverviewFromJson(_readMap(json['week_overview'])),
      selectedDayEntries: _readList(json['selected_day_entries'])
          .map((item) => CalorieEntry.fromJson(_readMap(item)))
          .toList(growable: false),
      runState: BurnWeekRunState.fromJson(_readMap(json['run_state'])),
      mealSections: _readList(json['meal_sections'])
          .map((item) => _mealSectionFromJson(_readMap(item)))
          .toList(growable: false),
      nutritionBars: _nutritionBarsFromJson(
        _readMap(json['nutrition_bars']),
      ),
    );
  }

  /// Selected diary day.
  final DateTime selectedDay;

  /// When this snapshot was loaded.
  final DateTime refreshedAt;

  /// Week overview used by balance widgets.
  final CalorieWeekOverview weekOverview;

  /// Entries for [selectedDay].
  final List<CalorieEntry> selectedDayEntries;

  /// Burn Week run state used by diary chrome and balance widgets.
  final BurnWeekRunState runState;

  /// Meal cards for [selectedDay].
  final List<DiaryMealSection> mealSections;

  /// Macro bars for [selectedDay].
  final DiaryNutritionBarsData nutritionBars;

  /// Converts data to persisted cache json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'selected_day': selectedDay.toIso8601String(),
      'refreshed_at': refreshedAt.toIso8601String(),
      'week_overview': _weekOverviewToJson(weekOverview),
      'selected_day_entries': [
        for (final entry in selectedDayEntries) _jsonSafeMap(entry.toJson()),
      ],
      'run_state': runState.toJson(),
      'meal_sections': [
        for (final section in mealSections) _mealSectionToJson(section),
      ],
      'nutrition_bars': _nutritionBarsToJson(nutritionBars),
    };
  }
}

Map<String, dynamic> _jsonSafeMap(Map<String, dynamic> json) {
  return <String, dynamic>{
    for (final entry in json.entries) entry.key: _jsonSafe(entry.value),
  };
}

Object? _jsonSafe(Object? value) {
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _jsonSafe(entry.value),
    };
  }
  if (value is List) {
    return [for (final item in value) _jsonSafe(item)];
  }
  return value;
}

Map<String, dynamic> _weekOverviewToJson(CalorieWeekOverview overview) {
  return <String, dynamic>{
    'days': [
      for (final day in overview.days) _weekDayOverviewToJson(day),
    ],
    'total_consumed_kcal': overview.totalConsumedKcal,
    'total_goal_kcal': overview.totalGoalKcal,
    'remaining_kcal': overview.remainingKcal,
    'balance_start_date': overview.balanceStartDate.toIso8601String(),
    'carryover_before_today_kcal': overview.carryoverBeforeTodayKcal,
    'today_flexible_goal_kcal': overview.todayFlexibleGoalKcal,
    'goal_starts_in_future': overview.goalStartsInFuture,
    'next_goal_start_date': overview.nextGoalStartDate?.toIso8601String(),
    'future_goal_kcal': overview.futureGoalKcal,
  };
}

CalorieWeekOverview _weekOverviewFromJson(Map<String, dynamic> json) {
  final days = _readList(json['days'])
      .map((item) => _weekDayOverviewFromJson(_readMap(item)))
      .toList(growable: false);
  if (days.isEmpty) {
    throw const FormatException('Diary dashboard cache has no week days.');
  }
  return CalorieWeekOverview(
    days: days,
    totalConsumedKcal: _readDouble(json['total_consumed_kcal']),
    totalGoalKcal: _readDouble(json['total_goal_kcal']),
    remainingKcal: _readDouble(json['remaining_kcal']),
    balanceStartDate: _readDate(json['balance_start_date']),
    carryoverBeforeTodayKcal: _readDouble(
      json['carryover_before_today_kcal'],
    ),
    todayFlexibleGoalKcal: _readDouble(json['today_flexible_goal_kcal']),
    goalStartsInFuture: json['goal_starts_in_future'] as bool? ?? false,
    nextGoalStartDate: _readOptionalDate(json['next_goal_start_date']),
    futureGoalKcal: _readOptionalDouble(json['future_goal_kcal']),
  );
}

Map<String, dynamic> _weekDayOverviewToJson(
  CalorieWeekDayOverview overview,
) {
  return <String, dynamic>{
    'date': overview.date.toIso8601String(),
    'total_kcal': overview.totalKcal,
    'goal_kcal': overview.goalKcal,
    'entry_count': overview.entryCount,
    'base_goal_kcal': overview.baseGoalKcal,
    'activity_bonus_kcal': overview.activityBonusKcal,
    'is_heart_day': overview.isHeartDay,
  };
}

CalorieWeekDayOverview _weekDayOverviewFromJson(Map<String, dynamic> json) {
  return CalorieWeekDayOverview(
    date: _readDate(json['date']),
    totalKcal: _readDouble(json['total_kcal']),
    goalKcal: _readDouble(json['goal_kcal']),
    entryCount: _readInt(json['entry_count']),
    baseGoalKcal: _readDouble(json['base_goal_kcal']),
    activityBonusKcal: _readDouble(json['activity_bonus_kcal']),
    isHeartDay: json['is_heart_day'] as bool? ?? false,
  );
}

Map<String, dynamic> _mealSectionToJson(DiaryMealSection section) {
  return <String, dynamic>{
    'meal_type': section.mealType.jsonValue,
    'total_kcal': section.totalKcal,
    'entries': [
      for (final entry in section.entries) _mealEntryToJson(entry),
    ],
  };
}

DiaryMealSection _mealSectionFromJson(Map<String, dynamic> json) {
  return DiaryMealSection(
    mealType: _mealTypeFromJson(json['meal_type']),
    entries: _readList(
      json['entries'],
    ).map((item) => _mealEntryFromJson(_readMap(item))).toList(growable: false),
    totalKcal: _readDouble(json['total_kcal']),
  );
}

Map<String, dynamic> _mealEntryToJson(DiaryMealEntry entry) {
  return <String, dynamic>{
    'id': entry.id,
    'meal_type': entry.mealType.jsonValue,
    'name': entry.name,
    'image_url': entry.imageUrl,
    'image_asset_id': entry.imageAssetId,
    'total_kcal': entry.totalKcal,
    'total_protein': entry.totalProtein,
    'total_carbs': entry.totalCarbs,
    'total_fat': entry.totalFat,
  };
}

DiaryMealEntry _mealEntryFromJson(Map<String, dynamic> json) {
  return DiaryMealEntry(
    id: json['id'] as String? ?? '',
    mealType: _mealTypeFromJson(json['meal_type']),
    name: json['name'] as String? ?? '',
    imageUrl: json['image_url'] as String?,
    imageAssetId: json['image_asset_id'] as String?,
    totalKcal: _readDouble(json['total_kcal']),
    totalProtein: _readDouble(json['total_protein']),
    totalCarbs: _readDouble(json['total_carbs']),
    totalFat: _readDouble(json['total_fat']),
  );
}

Map<String, dynamic> _nutritionBarsToJson(DiaryNutritionBarsData data) {
  return <String, dynamic>{
    'carbs': data.carbs,
    'protein': data.protein,
    'fat': data.fat,
    'goals': <String, dynamic>{
      'carbs': data.goals.carbs,
      'protein': data.goals.protein,
      'fat': data.goals.fat,
    },
  };
}

DiaryNutritionBarsData _nutritionBarsFromJson(Map<String, dynamic> json) {
  final goals = _readMap(json['goals']);
  return DiaryNutritionBarsData(
    carbs: _readDouble(json['carbs']),
    protein: _readDouble(json['protein']),
    fat: _readDouble(json['fat']),
    goals: DiaryMacroTargets(
      carbs: _readDouble(goals['carbs']),
      protein: _readDouble(goals['protein']),
      fat: _readDouble(goals['fat']),
    ),
  );
}

MealType _mealTypeFromJson(Object? value) {
  for (final mealType in MealType.values) {
    if (mealType.jsonValue == value || mealType.name == value) {
      return mealType;
    }
  }
  return MealType.breakfast;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

List<Object?> _readList(Object? value) {
  if (value is List) {
    return value;
  }
  return const <Object?>[];
}

DateTime _readDate(Object? value) {
  return _readOptionalDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _readOptionalDate(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

double _readDouble(Object? value) {
  return _readOptionalDouble(value) ?? 0;
}

double? _readOptionalDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int _readInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
