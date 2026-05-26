import 'dart:convert';

import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';

const _cacheVersion = 1;

/// Persisted diary health activity trend cache snapshot.
class DiaryHealthActivityTrendCacheSnapshot {
  /// Creates an activity trend cache snapshot.
  const DiaryHealthActivityTrendCacheSnapshot({
    required this.startInclusive,
    required this.endExclusive,
    required this.loadedAt,
    required this.days,
  });

  /// The normalized range start.
  final DateTime startInclusive;

  /// The normalized exclusive range end.
  final DateTime endExclusive;

  /// Time when the aggregate totals were loaded.
  final DateTime loadedAt;

  /// Cached derived aggregate trend totals.
  final List<DiaryHealthActivityTrendDay> days;

  /// Encodes the snapshot as a versioned JSON string.
  String encode({required String cacheKey}) {
    return jsonEncode(<String, Object?>{
      'version': _cacheVersion,
      'cache_key': cacheKey,
      'start_inclusive': startInclusive.toIso8601String(),
      'end_exclusive': endExclusive.toIso8601String(),
      'loaded_at': loadedAt.toIso8601String(),
      'days': days.map(_trendDayToJson).toList(growable: false),
    });
  }

  /// Decodes a versioned JSON string.
  static DiaryHealthActivityTrendCacheSnapshot? decode(
    String raw, {
    required String cacheKey,
  }) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(decoded);
    if (json['version'] != _cacheVersion || json['cache_key'] != cacheKey) {
      return null;
    }
    final startInclusive = _parseDateTime(json['start_inclusive']);
    final endExclusive = _parseDateTime(json['end_exclusive']);
    final loadedAt = _parseDateTime(json['loaded_at']);
    final days = _parseList(json['days'], _trendDayFromJson);
    if (startInclusive == null ||
        endExclusive == null ||
        loadedAt == null ||
        days == null) {
      return null;
    }
    return DiaryHealthActivityTrendCacheSnapshot(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      loadedAt: loadedAt,
      days: List<DiaryHealthActivityTrendDay>.unmodifiable(days),
    );
  }
}

Map<String, Object?> _trendDayToJson(DiaryHealthActivityTrendDay day) {
  return <String, Object?>{
    'day': day.day.toIso8601String(),
    'total_steps': day.totalSteps,
    'active_energy_kcal': day.activeEnergyKcal,
  };
}

DiaryHealthActivityTrendDay? _trendDayFromJson(Map<String, dynamic> json) {
  final day = _parseDateTime(json['day']);
  final totalSteps = _parseInt(json['total_steps']);
  final activeEnergyKcal = _parseInt(json['active_energy_kcal']);
  if (day == null || totalSteps == null || activeEnergyKcal == null) {
    return null;
  }
  return DiaryHealthActivityTrendDay(
    day: day,
    totalSteps: totalSteps,
    activeEnergyKcal: activeEnergyKcal,
  );
}

List<T>? _parseList<T>(
  Object? value,
  T? Function(Map<String, dynamic> json) parse,
) {
  if (value is! List) {
    return null;
  }
  final items = <T>[];
  for (final item in value) {
    if (item is! Map) {
      return null;
    }
    final parsed = parse(Map<String, dynamic>.from(item));
    if (parsed == null) {
      return null;
    }
    items.add(parsed);
  }
  return items;
}

DateTime? _parseDateTime(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value);
}

int? _parseInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return null;
}
