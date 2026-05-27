// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_health_activity_trend_day_cache_codec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryHealthActivityTrendDayCacheSnapshot
_$DiaryHealthActivityTrendDayCacheSnapshotFromJson(Map<String, dynamic> json) =>
    DiaryHealthActivityTrendDayCacheSnapshot(
      version: (json['version'] as num).toInt(),
      cacheKey: json['cache_key'] as String,
      loadedAt: DateTime.parse(json['loaded_at'] as String),
      day: DateTime.parse(json['day'] as String),
      totalSteps: (json['total_steps'] as num).toInt(),
      activeEnergyKcal: (json['active_energy_kcal'] as num).toInt(),
    );

Map<String, dynamic> _$DiaryHealthActivityTrendDayCacheSnapshotToJson(
  DiaryHealthActivityTrendDayCacheSnapshot instance,
) => <String, dynamic>{
  'version': instance.version,
  'cache_key': instance.cacheKey,
  'loaded_at': instance.loadedAt.toIso8601String(),
  'day': instance.day.toIso8601String(),
  'total_steps': instance.totalSteps,
  'active_energy_kcal': instance.activeEnergyKcal,
};
