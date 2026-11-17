// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_week_balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeekBalanceDay _$WeekBalanceDayFromJson(Map<String, dynamic> json) =>
    WeekBalanceDay(
      date: DateTime.parse(json['date'] as String),
      goalKcal: (json['goal_kcal'] as num).toDouble(),
      eatenKcal: (json['eaten_kcal'] as num).toDouble(),
      hasEntries: json['has_entries'] as bool,
      isPauseDay: json['is_pause_day'] as bool,
      carryoverKcal: (json['carryover_kcal'] as num).toDouble(),
    );

Map<String, dynamic> _$WeekBalanceDayToJson(WeekBalanceDay instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'goal_kcal': instance.goalKcal,
      'eaten_kcal': instance.eatenKcal,
      'has_entries': instance.hasEntries,
      'is_pause_day': instance.isPauseDay,
      'carryover_kcal': instance.carryoverKcal,
    };

WeekBalance _$WeekBalanceFromJson(Map<String, dynamic> json) => WeekBalance(
  mode: $enumDecode(_$WeekBalanceModeEnumMap, json['mode']),
  weightGoal: $enumDecode(_$CalorieGoalModeEnumMap, json['weight_goal']),
  days: (json['days'] as List<dynamic>)
      .map((e) => WeekBalanceDay.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WeekBalanceToJson(WeekBalance instance) =>
    <String, dynamic>{
      'mode': _$WeekBalanceModeEnumMap[instance.mode]!,
      'weight_goal': _$CalorieGoalModeEnumMap[instance.weightGoal]!,
      'days': instance.days.map((e) => e.toJson()).toList(),
    };

const _$WeekBalanceModeEnumMap = {
  WeekBalanceMode.off: 'off',
  WeekBalanceMode.show: 'show',
  WeekBalanceMode.carryover: 'carryover',
};

const _$CalorieGoalModeEnumMap = {
  CalorieGoalMode.lose: 'lose',
  CalorieGoalMode.maintain: 'maintain',
  CalorieGoalMode.gain: 'gain',
};
