import 'dart:convert';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';

part 'diary_day_dashboard_cache_store.g.dart';

const _cacheLogName = 'DiaryDayDashboardCacheStore';
const _cacheVersion = 2;

/// Stores last good diary dashboard snapshots for instant startup.
class DiaryDayDashboardCacheStore {
  /// Creates diary dashboard cache store.
  const DiaryDayDashboardCacheStore();

  /// Reads cached data synchronously.
  DiaryDayDashboardData? readSync({
    required AppPreferences preferences,
    required String userId,
    required DateTime day,
  }) {
    final dayKey = diaryDayKey(day);
    final raw = preferences.getStringSync(_key(userId: userId, dayKey: dayKey));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final json = Map<String, dynamic>.from(decoded);
      if (json['version'] != _cacheVersion ||
          json['user_id'] != userId ||
          json['day_key'] != dayKey) {
        return null;
      }
      final data = DiaryDayDashboardData.fromJson(
        Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      );
      if (diaryDayKey(data.selectedDay) != dayKey) {
        return null;
      }
      return data;
    } on Object catch (error, stackTrace) {
      log(
        'Ignoring malformed diary dashboard cache.',
        name: _cacheLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Saves cached data.
  Future<bool> save({
    required AppPreferences preferences,
    required String userId,
    required DiaryDayDashboardData data,
  }) {
    final dayKey = diaryDayKey(data.selectedDay);
    final encoded = jsonEncode(<String, dynamic>{
      'version': _cacheVersion,
      'user_id': userId,
      'day_key': dayKey,
      'data': data.toJson(),
    });
    return preferences.setString(
      _key(userId: userId, dayKey: dayKey),
      encoded,
    );
  }

  String _key({required String userId, required String dayKey}) {
    return 'diary_day_dashboard_v$_cacheVersion:$userId:$dayKey';
  }
}

/// Provides the diary dashboard cache store.
@riverpod
DiaryDayDashboardCacheStore diaryDayDashboardCacheStore(Ref ref) {
  return const DiaryDayDashboardCacheStore();
}
