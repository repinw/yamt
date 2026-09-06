// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_day_dashboard_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryDayDashboardData _$DiaryDayDashboardDataFromJson(
  Map<String, dynamic> json,
) => DiaryDayDashboardData(
  selectedDay: DateTime.parse(json['selected_day'] as String),
  refreshedAt: DateTime.parse(json['refreshed_at'] as String),
  weekOverview: CalorieWeekOverview.fromJson(
    json['week_overview'] as Map<String, dynamic>,
  ),
  selectedDayEntries: (json['selected_day_entries'] as List<dynamic>)
      .map(
        (e) => const _CachedCalorieEntryConverter().fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  runState: BurnWeekRunState.fromJson(
    json['run_state'] as Map<String, dynamic>,
  ),
  mealSections: (json['meal_sections'] as List<dynamic>)
      .map((e) => DiaryMealSection.fromJson(e as Map<String, dynamic>))
      .toList(),
  nutritionBars: DiaryNutritionBarsData.fromJson(
    json['nutrition_bars'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$DiaryDayDashboardDataToJson(
  DiaryDayDashboardData instance,
) => <String, dynamic>{
  'selected_day': instance.selectedDay.toIso8601String(),
  'refreshed_at': instance.refreshedAt.toIso8601String(),
  'week_overview': instance.weekOverview.toJson(),
  'selected_day_entries': instance.selectedDayEntries
      .map(const _CachedCalorieEntryConverter().toJson)
      .toList(),
  'run_state': instance.runState.toJson(),
  'meal_sections': instance.mealSections.map((e) => e.toJson()).toList(),
  'nutrition_bars': instance.nutritionBars.toJson(),
};
