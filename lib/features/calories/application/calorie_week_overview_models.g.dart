// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_week_overview_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieWeekDayOverview _$CalorieWeekDayOverviewFromJson(
  Map<String, dynamic> json,
) => CalorieWeekDayOverview(
  date: DateTime.parse(json['date'] as String),
  totalKcal: (json['total_kcal'] as num).toDouble(),
  goalKcal: (json['goal_kcal'] as num).toDouble(),
  entryCount: (json['entry_count'] as num).toInt(),
  baseGoalKcal: (json['base_goal_kcal'] as num?)?.toDouble(),
  isPauseDay: json['is_pause_day'] as bool? ?? false,
);

Map<String, dynamic> _$CalorieWeekDayOverviewToJson(
  CalorieWeekDayOverview instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'total_kcal': instance.totalKcal,
  'goal_kcal': instance.goalKcal,
  'base_goal_kcal': instance.baseGoalKcal,
  'entry_count': instance.entryCount,
  'is_pause_day': instance.isPauseDay,
};

CalorieWeekOverview _$CalorieWeekOverviewFromJson(
  Map<String, dynamic> json,
) => CalorieWeekOverview(
  days: (json['days'] as List<dynamic>)
      .map((e) => CalorieWeekDayOverview.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalConsumedKcal: (json['total_consumed_kcal'] as num).toDouble(),
  totalGoalKcal: (json['total_goal_kcal'] as num).toDouble(),
  remainingKcal: (json['remaining_kcal'] as num).toDouble(),
  balanceStartDate: DateTime.parse(json['balance_start_date'] as String),
  carryoverBeforeTodayKcal: (json['carryover_before_today_kcal'] as num)
      .toDouble(),
  todayFlexibleGoalKcal: (json['today_flexible_goal_kcal'] as num).toDouble(),
  goalStartsInFuture: json['goal_starts_in_future'] as bool,
  nextGoalStartDate: json['next_goal_start_date'] == null
      ? null
      : DateTime.parse(json['next_goal_start_date'] as String),
  futureGoalKcal: (json['future_goal_kcal'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CalorieWeekOverviewToJson(
  CalorieWeekOverview instance,
) => <String, dynamic>{
  'days': instance.days.map((e) => e.toJson()).toList(),
  'total_consumed_kcal': instance.totalConsumedKcal,
  'total_goal_kcal': instance.totalGoalKcal,
  'remaining_kcal': instance.remainingKcal,
  'balance_start_date': instance.balanceStartDate.toIso8601String(),
  'carryover_before_today_kcal': instance.carryoverBeforeTodayKcal,
  'today_flexible_goal_kcal': instance.todayFlexibleGoalKcal,
  'goal_starts_in_future': instance.goalStartsInFuture,
  'next_goal_start_date': instance.nextGoalStartDate?.toIso8601String(),
  'future_goal_kcal': instance.futureGoalKcal,
};
