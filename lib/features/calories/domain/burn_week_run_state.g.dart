// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'burn_week_run_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BurnWeekRunState _$BurnWeekRunStateFromJson(Map<String, dynamic> json) =>
    BurnWeekRunState(
      currentWeekStartDayKey: json['current_week_start_day_key'] as String?,
      runWeekNumber: (json['run_week_number'] as num?)?.toInt() ?? 1,
      starCount: (json['star_count'] as num?)?.toInt() ?? 0,
      heartCount: (json['heart_count'] as num?)?.toInt() ?? 1,
      heartCreditKcal: (json['heart_credit_kcal'] as num?)?.toDouble() ?? 0,
      starBrokeThisWeek: json['star_broke_this_week'] as bool? ?? false,
      missedTrackingThisWeek:
          json['missed_tracking_this_week'] as bool? ?? false,
      heartDayKeys: json['heart_day_keys'] == null
          ? const <String>[]
          : _decodeHeartDayKeys(json['heart_day_keys']),
      heartStarBreakDayKeys: json['heart_star_break_day_keys'] == null
          ? const <String>[]
          : _decodeHeartDayKeys(json['heart_star_break_day_keys']),
      runLimitWarningThisWeek:
          json['run_limit_warning_this_week'] as bool? ?? false,
      lastActiveDayKey: json['last_active_day_key'] as String?,
    );

Map<String, dynamic> _$BurnWeekRunStateToJson(BurnWeekRunState instance) =>
    <String, dynamic>{
      'current_week_start_day_key': instance.currentWeekStartDayKey,
      'last_active_day_key': instance.lastActiveDayKey,
      'run_week_number': instance.runWeekNumber,
      'star_count': instance.starCount,
      'heart_count': instance.heartCount,
      'heart_credit_kcal': instance.heartCreditKcal,
      'star_broke_this_week': instance.starBrokeThisWeek,
      'missed_tracking_this_week': instance.missedTrackingThisWeek,
      'heart_day_keys': instance.heartDayKeys,
      'heart_star_break_day_keys': instance.heartStarBreakDayKeys,
      'run_limit_warning_this_week': instance.runLimitWarningThisWeek,
    };
