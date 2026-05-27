import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';

part 'diary_health_activity_trend_day_cache_codec.g.dart';

const _cacheVersion = 1;

/// Persisted aggregate activity totals for one diary day.
@JsonSerializable(fieldRename: FieldRename.snake)
class DiaryHealthActivityTrendDayCacheSnapshot {
  /// Creates a persisted activity trend day snapshot.
  const DiaryHealthActivityTrendDayCacheSnapshot({
    required this.version,
    required this.cacheKey,
    required this.loadedAt,
    required this.day,
    required this.totalSteps,
    required this.activeEnergyKcal,
  });

  /// Creates snapshot from domain data.
  factory DiaryHealthActivityTrendDayCacheSnapshot.fromDomain({
    required String cacheKey,
    required DateTime loadedAt,
    required DiaryHealthActivityTrendDay day,
  }) {
    return DiaryHealthActivityTrendDayCacheSnapshot(
      version: _cacheVersion,
      cacheKey: cacheKey,
      loadedAt: loadedAt,
      day: day.day,
      totalSteps: day.totalSteps,
      activeEnergyKcal: day.activeEnergyKcal,
    );
  }

  /// Creates snapshot from JSON.
  factory DiaryHealthActivityTrendDayCacheSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    return _$DiaryHealthActivityTrendDayCacheSnapshotFromJson(json);
  }

  /// Cache payload version.
  final int version;

  /// Store key this payload belongs to.
  final String cacheKey;

  /// Time when Health aggregate data was loaded.
  final DateTime loadedAt;

  /// Diary day.
  final DateTime day;

  /// Total steps.
  final int totalSteps;

  /// Active energy in kcal.
  final int activeEnergyKcal;

  /// Converts snapshot to domain day.
  DiaryHealthActivityTrendDay toDomain() {
    return DiaryHealthActivityTrendDay(
      day: day,
      totalSteps: totalSteps,
      activeEnergyKcal: activeEnergyKcal,
    );
  }

  /// Encodes snapshot to versioned JSON.
  String encode() {
    return jsonEncode(toJson());
  }

  /// Converts snapshot to JSON.
  Map<String, dynamic> toJson() {
    return _$DiaryHealthActivityTrendDayCacheSnapshotToJson(this);
  }

  /// Decodes versioned JSON.
  static DiaryHealthActivityTrendDayCacheSnapshot? decode(
    String raw, {
    required String cacheKey,
  }) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    final snapshot = DiaryHealthActivityTrendDayCacheSnapshot.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (snapshot.version != _cacheVersion || snapshot.cacheKey != cacheKey) {
      return null;
    }
    return snapshot;
  }
}
