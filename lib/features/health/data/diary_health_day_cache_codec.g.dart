// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_health_day_cache_codec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryHealthDayCacheSnapshot _$DiaryHealthDayCacheSnapshotFromJson(
  Map<String, dynamic> json,
) => DiaryHealthDayCacheSnapshot(
  version: (json['version'] as num).toInt(),
  cacheKey: json['cache_key'] as String,
  dayStart: DateTime.parse(json['day_start'] as String),
  loadedAt: DateTime.parse(json['loaded_at'] as String),
  totalSteps: (json['total_steps'] as num).toInt(),
  workouts: (json['workouts'] as List<dynamic>)
      .map(
        (e) => DiaryHealthWorkoutCacheDto.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  unassignedActiveEnergySegments:
      (json['unassigned_active_energy_segments'] as List<dynamic>)
          .map(
            (e) => DiaryHealthEnergySegmentCacheDto.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
);

Map<String, dynamic> _$DiaryHealthDayCacheSnapshotToJson(
  DiaryHealthDayCacheSnapshot instance,
) => <String, dynamic>{
  'version': instance.version,
  'cache_key': instance.cacheKey,
  'day_start': instance.dayStart.toIso8601String(),
  'loaded_at': instance.loadedAt.toIso8601String(),
  'total_steps': instance.totalSteps,
  'workouts': instance.workouts.map((e) => e.toJson()).toList(),
  'unassigned_active_energy_segments': instance.unassignedActiveEnergySegments
      .map((e) => e.toJson())
      .toList(),
};

DiaryHealthWorkoutCacheDto _$DiaryHealthWorkoutCacheDtoFromJson(
  Map<String, dynamic> json,
) => DiaryHealthWorkoutCacheDto(
  id: json['id'] as String,
  start: DateTime.parse(json['start'] as String),
  endExclusive: DateTime.parse(json['end_exclusive'] as String),
  durationMinutes: (json['duration_minutes'] as num).toDouble(),
  totalCalories: (json['total_calories'] as num?)?.toInt(),
  totalSteps: (json['total_steps'] as num?)?.toInt(),
  activityLabel: json['activity_label'] as String?,
  sourceName: json['source_name'] as String?,
);

Map<String, dynamic> _$DiaryHealthWorkoutCacheDtoToJson(
  DiaryHealthWorkoutCacheDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'start': instance.start.toIso8601String(),
  'end_exclusive': instance.endExclusive.toIso8601String(),
  'duration_minutes': instance.durationMinutes,
  'activity_label': instance.activityLabel,
  'source_name': instance.sourceName,
  'total_calories': instance.totalCalories,
  'total_steps': instance.totalSteps,
};

DiaryHealthEnergySegmentCacheDto _$DiaryHealthEnergySegmentCacheDtoFromJson(
  Map<String, dynamic> json,
) => DiaryHealthEnergySegmentCacheDto(
  id: json['id'] as String,
  start: DateTime.parse(json['start'] as String),
  endExclusive: DateTime.parse(json['end_exclusive'] as String),
  durationMinutes: (json['duration_minutes'] as num).toDouble(),
  totalCalories: (json['total_calories'] as num).toInt(),
  totalSteps: (json['total_steps'] as num?)?.toInt(),
  sourceName: json['source_name'] as String?,
);

Map<String, dynamic> _$DiaryHealthEnergySegmentCacheDtoToJson(
  DiaryHealthEnergySegmentCacheDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'start': instance.start.toIso8601String(),
  'end_exclusive': instance.endExclusive.toIso8601String(),
  'duration_minutes': instance.durationMinutes,
  'source_name': instance.sourceName,
  'total_calories': instance.totalCalories,
  'total_steps': instance.totalSteps,
};
