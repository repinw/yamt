import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

part 'diary_health_day_cache_codec.g.dart';

const _cacheVersion = 1;

/// Persisted derived health data for one diary day.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DiaryHealthDayCacheSnapshot {
  /// Creates a persisted diary health day snapshot.
  const DiaryHealthDayCacheSnapshot({
    required this.version,
    required this.cacheKey,
    required this.dayStart,
    required this.loadedAt,
    required this.totalSteps,
    required this.workouts,
    required this.unassignedActiveEnergySegments,
  });

  /// Creates a snapshot from domain data.
  factory DiaryHealthDayCacheSnapshot.fromDomain({
    required String cacheKey,
    required DateTime dayStart,
    required DateTime loadedAt,
    required DiaryHealthDayData data,
  }) {
    return DiaryHealthDayCacheSnapshot(
      version: _cacheVersion,
      cacheKey: cacheKey,
      dayStart: dayStart,
      loadedAt: loadedAt,
      totalSteps: data.totalSteps,
      workouts: data.workouts
          .map(DiaryHealthWorkoutCacheDto.fromDomain)
          .toList(growable: false),
      unassignedActiveEnergySegments: data.unassignedActiveEnergySegments
          .map(DiaryHealthEnergySegmentCacheDto.fromDomain)
          .toList(growable: false),
    );
  }

  /// Creates a persisted diary health day snapshot from JSON.
  factory DiaryHealthDayCacheSnapshot.fromJson(Map<String, dynamic> json) {
    return _$DiaryHealthDayCacheSnapshotFromJson(json);
  }

  /// Cache payload version.
  final int version;

  /// Store key this payload belongs to.
  final String cacheKey;

  /// Normalized local day start.
  final DateTime dayStart;

  /// Time when Health data was loaded.
  final DateTime loadedAt;

  /// Total steps.
  final int totalSteps;

  /// Persisted workouts.
  final List<DiaryHealthWorkoutCacheDto> workouts;

  /// Persisted unassigned active energy segments.
  final List<DiaryHealthEnergySegmentCacheDto> unassignedActiveEnergySegments;

  /// Converts this snapshot to domain data.
  DiaryHealthDayData toDomain() {
    return DiaryHealthDayData(
      totalSteps: totalSteps,
      workouts: List<HealthWorkoutSession>.unmodifiable(
        workouts.map((workout) => workout.toDomain()),
      ),
      unassignedActiveEnergySegments: List<HealthEnergySegment>.unmodifiable(
        unassignedActiveEnergySegments.map(
          (segment) => segment.toDomain(),
        ),
      ),
    );
  }

  /// Encodes the snapshot as versioned JSON.
  String encode() {
    return jsonEncode(toJson());
  }

  /// Converts snapshot to JSON.
  Map<String, dynamic> toJson() => _$DiaryHealthDayCacheSnapshotToJson(this);

  /// Decodes versioned JSON.
  static DiaryHealthDayCacheSnapshot? decode(
    String raw, {
    required String cacheKey,
  }) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    final snapshot = DiaryHealthDayCacheSnapshot.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (snapshot.version != _cacheVersion || snapshot.cacheKey != cacheKey) {
      return null;
    }
    return snapshot;
  }
}

/// Persisted workout session DTO.
@JsonSerializable(fieldRename: FieldRename.snake)
class DiaryHealthWorkoutCacheDto {
  /// Creates a persisted workout session DTO.
  const DiaryHealthWorkoutCacheDto({
    required this.id,
    required this.start,
    required this.endExclusive,
    required this.durationMinutes,
    required this.totalCalories,
    required this.totalSteps,
    this.activityLabel,
    this.sourceName,
  });

  /// Creates DTO from domain workout.
  factory DiaryHealthWorkoutCacheDto.fromDomain(
    HealthWorkoutSession workout,
  ) {
    return DiaryHealthWorkoutCacheDto(
      id: workout.id,
      start: workout.start,
      endExclusive: workout.endExclusive,
      durationMinutes: workout.durationMinutes,
      activityLabel: workout.activityLabel,
      sourceName: workout.sourceName,
      totalCalories: workout.totalCalories,
      totalSteps: workout.totalSteps,
    );
  }

  /// Creates DTO from JSON.
  factory DiaryHealthWorkoutCacheDto.fromJson(Map<String, dynamic> json) {
    return _$DiaryHealthWorkoutCacheDtoFromJson(json);
  }

  /// Stable workout id.
  final String id;

  /// Start time.
  final DateTime start;

  /// Exclusive end time.
  final DateTime endExclusive;

  /// Duration in minutes.
  final double durationMinutes;

  /// Activity label.
  final String? activityLabel;

  /// Source app/device name.
  final String? sourceName;

  /// Workout calories.
  final int? totalCalories;

  /// Workout steps.
  final int? totalSteps;

  /// Converts DTO to domain workout.
  HealthWorkoutSession toDomain() {
    return HealthWorkoutSession(
      id: id,
      start: start,
      endExclusive: endExclusive,
      durationMinutes: durationMinutes,
      activityLabel: activityLabel,
      sourceName: sourceName,
      totalCalories: totalCalories,
      totalSteps: totalSteps,
    );
  }

  /// Converts DTO to JSON.
  Map<String, dynamic> toJson() => _$DiaryHealthWorkoutCacheDtoToJson(this);
}

/// Persisted unassigned energy segment DTO.
@JsonSerializable(fieldRename: FieldRename.snake)
class DiaryHealthEnergySegmentCacheDto {
  /// Creates a persisted unassigned energy segment DTO.
  const DiaryHealthEnergySegmentCacheDto({
    required this.id,
    required this.start,
    required this.endExclusive,
    required this.durationMinutes,
    required this.totalCalories,
    required this.totalSteps,
    this.sourceName,
  });

  /// Creates DTO from domain segment.
  factory DiaryHealthEnergySegmentCacheDto.fromDomain(
    HealthEnergySegment segment,
  ) {
    return DiaryHealthEnergySegmentCacheDto(
      id: segment.id,
      start: segment.start,
      endExclusive: segment.endExclusive,
      durationMinutes: segment.durationMinutes,
      sourceName: segment.sourceName,
      totalCalories: segment.totalCalories,
      totalSteps: segment.totalSteps,
    );
  }

  /// Creates DTO from JSON.
  factory DiaryHealthEnergySegmentCacheDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return _$DiaryHealthEnergySegmentCacheDtoFromJson(json);
  }

  /// Stable segment id.
  final String id;

  /// Start time.
  final DateTime start;

  /// Exclusive end time.
  final DateTime endExclusive;

  /// Duration in minutes.
  final double durationMinutes;

  /// Source app/device name.
  final String? sourceName;

  /// Calories.
  final int totalCalories;

  /// Estimated/known steps.
  final int? totalSteps;

  /// Converts DTO to domain segment.
  HealthEnergySegment toDomain() {
    return HealthEnergySegment(
      id: id,
      start: start,
      endExclusive: endExclusive,
      durationMinutes: durationMinutes,
      sourceName: sourceName,
      totalCalories: totalCalories,
      totalSteps: totalSteps,
    );
  }

  /// Converts DTO to JSON.
  Map<String, dynamic> toJson() {
    return _$DiaryHealthEnergySegmentCacheDtoToJson(this);
  }
}
