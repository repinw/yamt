import 'dart:developer' as developer;

import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/debug/calorie_debug_dump_service.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

/// Builds debug dump text from dump result.
String calorieDebugDumpText({
  required CalorieDebugDumpResult result,
  required DateTime generatedAt,
}) {
  final rangeLabel =
      '${formatDebugDumpDate(result.startInclusive)}'
      '..${formatDebugDumpDate(previousDiaryDay(result.endExclusive))}';
  return [
    'YAMT diary debug dump',
    'Generated: ${generatedAt.toLocal().toIso8601String()}',
    'Range: $rangeLabel',
    'Rows: ${result.rowCount}',
    '',
    result.table,
  ].join('\n');
}

/// Generates debug dump file name.
String calorieDebugDumpFileName(DateTime now) {
  final local = now.toLocal();
  return 'yamt_diary_debug_${formatDebugDumpStamp(local)}.txt';
}

/// Formats date time as a timestamp string for file naming.
String formatDebugDumpStamp(DateTime dateTime) {
  return '${dateTime.year.toString().padLeft(4, '0')}'
      '${dateTime.month.toString().padLeft(2, '0')}'
      '${dateTime.day.toString().padLeft(2, '0')}_'
      '${dateTime.hour.toString().padLeft(2, '0')}'
      '${dateTime.minute.toString().padLeft(2, '0')}'
      '${dateTime.second.toString().padLeft(2, '0')}';
}

/// Formats date for debug dump headers.
String formatDebugDumpDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// Recursively prepares an object for JSON debug encoding.
Object? jsonDebugValue(Object? value) {
  return switch (value) {
    DateTime() => value.toIso8601String(),
    Map<Object?, Object?>() => value.map(
      (key, value) => MapEntry(key.toString(), jsonDebugValue(value)),
    ),
    Iterable<Object?>() => value.map(jsonDebugValue).toList(growable: false),
    _ => value,
  };
}

/// Converts weekly check-in data to debug JSON map.
Map<String, Object?> weeklyCheckInDataDebugJson(
  CalorieWeeklyCheckInData checkInData,
) {
  return <String, Object?>{
    'today': diaryDayKey(DateTime.now()),
    'has_pending': checkInData.hasPending,
    'should_auto_open': checkInData.shouldAutoOpen,
    'show_diary_hint': checkInData.showDiaryHint,
    'is_ready': checkInData.isReady,
    'is_blocked': checkInData.isBlocked,
    'blocked_reason': checkInData.blockedReason?.name,
    'missing_intake_days': checkInData.missingIntakeDays
        .map(diaryDayKey)
        .toList(growable: false),
    'missing_weight_days': checkInData.missingWeightDays
        .map(diaryDayKey)
        .toList(growable: false),
    'freshness': checkInData.freshness.name,
    'latest_learned_tdee_at': checkInData.latestLearnedTdeeAt
        ?.toIso8601String(),
    'low_confidence': checkInData.lowConfidence,
    'input_hash': checkInData.inputHash,
    'pending_weekly_check_in': pendingWeeklyCheckInDebugJson(
      checkInData.pendingWeeklyCheckIn,
    ),
    'cache_weekly_check_in': pendingWeeklyCheckInDebugJson(
      checkInData.cacheWeeklyCheckIn,
    ),
    'calculation': calculationDebugJson(checkInData.calculation),
    'days': checkInData.days.map(windowDayDebugJson).toList(growable: false),
  };
}

/// Converts pending weekly check-in to debug JSON map.
Map<String, Object?>? pendingWeeklyCheckInDebugJson(
  PendingCalorieGoalWeeklyCheckIn? pending,
) {
  if (pending == null) {
    return null;
  }
  return <String, Object?>{
    'window_start_date': diaryDayKey(pending.windowStartDate),
    'window_end_date': diaryDayKey(pending.windowEndDate),
    'due_date': diaryDayKey(pending.dueDate),
    'dismissed_at': pending.dismissedAt?.toIso8601String(),
    'window_key': pending.windowKey,
  };
}

/// Converts calculation to debug JSON map.
Map<String, Object?>? calculationDebugJson(
  CalorieWeeklyCheckInCalculation? calculation,
) {
  if (calculation == null) {
    return null;
  }
  return <String, Object?>{
    'trend_weight_change_per_day': calculation.trendWeightChangePerDay,
    'average_intake_kcal': calculation.averageIntakeKcal,
    'measured_tdee_kcal': calculation.measuredTdeeKcal,
    'calculated_tdee_kcal': calculation.calculatedTdeeKcal,
    'new_base_goal_kcal': calculation.newGoalKcal,
    'new_target_kcal': calculation.newGoalKcal,
  };
}

/// Converts window day to debug JSON map.
Map<String, Object?> windowDayDebugJson(CalorieWeeklyCheckInWindowDay day) {
  return <String, Object?>{
    'day': diaryDayKey(day.day),
    'has_entries': day.hasEntries,
    'logged_intake_kcal': day.loggedIntakeKcal,
    'resolved_intake_kcal': day.resolvedIntakeKcal,
    'is_skipped_intake_day': day.isSkippedIntakeDay,
    'is_pause_day': day.isPauseDay,
    'weight_kg': day.weightKg,
  };
}

/// Logs calorie settings dump in chunks.
void logCalorieSettingsDebugDump(String dump) {
  logDebugDump(name: 'CalorieSettingsDebugDump', dump: dump);
}

/// Logs debug dump string in chunks to avoid developer.log truncation.
void logDebugDump({required String name, required String dump}) {
  const chunkLength = 800;
  for (var offset = 0; offset < dump.length; offset += chunkLength) {
    final end = offset + chunkLength > dump.length
        ? dump.length
        : offset + chunkLength;
    developer.log(dump.substring(offset, end), name: name);
  }
}
