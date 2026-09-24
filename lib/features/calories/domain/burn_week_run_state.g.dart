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
      starBrokeThisWeek: json['star_broke_this_week'] as bool? ?? false,
      missedTrackingThisWeek:
          json['missed_tracking_this_week'] as bool? ?? false,
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
      'star_broke_this_week': instance.starBrokeThisWeek,
      'missed_tracking_this_week': instance.missedTrackingThisWeek,
      'run_limit_warning_this_week': instance.runLimitWarningThisWeek,
    };
