// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_day_dashboard_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryDayDashboardSnapshot _$DiaryDayDashboardSnapshotFromJson(
  Map<String, dynamic> json,
) => DiaryDayDashboardSnapshot(
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
  plannedEntries: (json['planned_entries'] as List<dynamic>)
      .map(
        (e) => const _CachedCalorieEntryConverter().fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  runState: BurnWeekRunState.fromJson(
    json['run_state'] as Map<String, dynamic>,
  ),
  goalKcal: (json['goal_kcal'] as num).toDouble(),
  macroTargets: DiaryMacroTargets.fromJson(
    json['macro_targets'] as Map<String, dynamic>,
  ),
  carryoverMacroDelta: DiaryMacroTargets.fromJson(
    json['carryover_macro_delta'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$DiaryDayDashboardSnapshotToJson(
  DiaryDayDashboardSnapshot instance,
) => <String, dynamic>{
  'selected_day': instance.selectedDay.toIso8601String(),
  'refreshed_at': instance.refreshedAt.toIso8601String(),
  'week_overview': instance.weekOverview.toJson(),
  'selected_day_entries': instance.selectedDayEntries
      .map(const _CachedCalorieEntryConverter().toJson)
      .toList(),
  'planned_entries': instance.plannedEntries
      .map(const _CachedCalorieEntryConverter().toJson)
      .toList(),
  'run_state': instance.runState.toJson(),
  'goal_kcal': instance.goalKcal,
  'macro_targets': instance.macroTargets.toJson(),
  'carryover_macro_delta': instance.carryoverMacroDelta.toJson(),
};
