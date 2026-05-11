import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/application/'
    'calorie_debug_dump_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_controller.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_repository_provider.dart';

/// Result from printing calorie debug dump.
sealed class CalorieDebugDumpPrintResult {
  const CalorieDebugDumpPrintResult();
}

/// Successful calorie debug dump print.
class CalorieDebugDumpPrintSuccess extends CalorieDebugDumpPrintResult {
  /// Creates success result.
  const CalorieDebugDumpPrintSuccess({required this.rowCount});

  /// Number of rows printed.
  final int rowCount;
}

/// Failed calorie debug dump print.
class CalorieDebugDumpPrintFailure extends CalorieDebugDumpPrintResult {
  /// Creates failure result.
  const CalorieDebugDumpPrintFailure();
}

/// Result from printing calorie settings debug dump.
sealed class CalorieSettingsDebugDumpPrintResult {
  const CalorieSettingsDebugDumpPrintResult();
}

/// Successful calorie settings debug dump print.
class CalorieSettingsDebugDumpPrintSuccess
    extends CalorieSettingsDebugDumpPrintResult {
  /// Creates success result.
  const CalorieSettingsDebugDumpPrintSuccess({required this.entryCount});

  /// Number of goal-history entries printed.
  final int entryCount;
}

/// Failed calorie settings debug dump print.
class CalorieSettingsDebugDumpPrintFailure
    extends CalorieSettingsDebugDumpPrintResult {
  /// Creates failure result.
  const CalorieSettingsDebugDumpPrintFailure();
}

/// Result from printing calorie weekly check-in debug dump.
sealed class CalorieWeeklyCheckInDebugDumpPrintResult {
  const CalorieWeeklyCheckInDebugDumpPrintResult();
}

/// Successful calorie weekly check-in debug dump print.
class CalorieWeeklyCheckInDebugDumpPrintSuccess
    extends CalorieWeeklyCheckInDebugDumpPrintResult {
  /// Creates success result.
  const CalorieWeeklyCheckInDebugDumpPrintSuccess();
}

/// Failed calorie weekly check-in debug dump print.
class CalorieWeeklyCheckInDebugDumpPrintFailure
    extends CalorieWeeklyCheckInDebugDumpPrintResult {
  /// Creates failure result.
  const CalorieWeeklyCheckInDebugDumpPrintFailure();
}

/// Handles calorie page actions that need providers.
class CaloriePageActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  /// Prints calorie debug dump.
  Future<CalorieDebugDumpPrintResult> printDebugDump(DateTime now) async {
    final calorieLogRepository = ref.read(calorieLogRepositoryProvider);
    final diaryHealthService = ref.read(diaryHealthServiceProvider);
    final healthWeightService = ref.read(healthWeightServiceProvider);
    final manualWeightRepository = ref.read(
      manualHealthWeightRepositoryProvider,
    );
    final healthStatusFuture = ref.read(
      healthConnectionControllerProvider.future,
    );
    final settingsFuture = ref.read(calorieGoalControllerProvider.future);

    try {
      final result = await buildCalorieDebugDump(
        calorieLogRepository: calorieLogRepository,
        diaryHealthService: diaryHealthService,
        healthWeightService: healthWeightService,
        manualWeightRepository: manualWeightRepository,
        healthStatusFuture: healthStatusFuture,
        settingsFuture: settingsFuture,
        now: now,
      );
      developer.log(
        'Calorie debug dump\n${result.table}',
        name: 'CalorieDebugDump',
      );
      return CalorieDebugDumpPrintSuccess(rowCount: result.rowCount);
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to build calorie debug dump.',
        name: 'CalorieDebugDump',
        error: error,
        stackTrace: stackTrace,
      );
      return const CalorieDebugDumpPrintFailure();
    }
  }

  /// Prints calorie settings debug dump.
  Future<CalorieSettingsDebugDumpPrintResult> printSettingsDebugDump() async {
    try {
      final settings = await ref.read(calorieGoalControllerProvider.future);
      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(_jsonDebugValue(settings.toJson()));
      _logCalorieSettingsDebugDump(
        'users/<uid>/calorie_settings/default\n$encoded',
      );
      return CalorieSettingsDebugDumpPrintSuccess(
        entryCount: settings.goalHistory.length,
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to build calorie settings debug dump.',
        name: 'CalorieSettingsDebugDump',
        error: error,
        stackTrace: stackTrace,
      );
      return const CalorieSettingsDebugDumpPrintFailure();
    }
  }

  /// Prints calorie weekly check-in debug dump.
  Future<CalorieWeeklyCheckInDebugDumpPrintResult>
  printWeeklyCheckInDebugDump() async {
    try {
      final viewModel = await ref.read(
        calorieWeeklyCheckInViewModelProvider.future,
      );
      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(_weeklyCheckInViewModelDebugJson(viewModel));
      _logDebugDump(
        name: 'CalorieWeeklyCheckInDebugDump',
        dump: 'calorieWeeklyCheckInViewModel\n$encoded',
      );
      return const CalorieWeeklyCheckInDebugDumpPrintSuccess();
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to build calorie weekly check-in debug dump.',
        name: 'CalorieWeeklyCheckInDebugDump',
        error: error,
        stackTrace: stackTrace,
      );
      return const CalorieWeeklyCheckInDebugDumpPrintFailure();
    }
  }

  /// Toggles skipped-intake state for a calorie day.
  Future<bool> setSkippedIntakeDay({
    required DateTime selectedDay,
    required bool isSkipped,
  }) {
    final controller = ref.read(
      calorieWeeklyCheckInControllerProvider.notifier,
    );
    return controller.setSkippedIntakeDay(
      day: selectedDay,
      isSkipped: isSkipped,
    );
  }
}

Object? _jsonDebugValue(Object? value) {
  return switch (value) {
    DateTime() => value.toIso8601String(),
    Map<Object?, Object?>() => value.map(
      (key, value) => MapEntry(key.toString(), _jsonDebugValue(value)),
    ),
    Iterable<Object?>() => value.map(_jsonDebugValue).toList(growable: false),
    _ => value,
  };
}

Map<String, Object?> _weeklyCheckInViewModelDebugJson(
  CalorieWeeklyCheckInViewModel viewModel,
) {
  return <String, Object?>{
    'today': diaryDayKey(DateTime.now()),
    'has_pending': viewModel.hasPending,
    'should_auto_open': viewModel.shouldAutoOpen,
    'show_diary_hint': viewModel.showDiaryHint,
    'is_ready': viewModel.isReady,
    'is_blocked': viewModel.isBlocked,
    'blocked_reason': viewModel.blockedReason?.name,
    'missing_intake_days': viewModel.missingIntakeDays
        .map(diaryDayKey)
        .toList(growable: false),
    'missing_weight_days': viewModel.missingWeightDays
        .map(diaryDayKey)
        .toList(growable: false),
    'freshness': viewModel.freshness.name,
    'latest_learned_tdee_at': viewModel.latestLearnedTdeeAt?.toIso8601String(),
    'low_confidence': viewModel.lowConfidence,
    'input_hash': viewModel.inputHash,
    'pending_weekly_check_in': _pendingWeeklyCheckInDebugJson(
      viewModel.pendingWeeklyCheckIn,
    ),
    'cache_weekly_check_in': _pendingWeeklyCheckInDebugJson(
      viewModel.cacheWeeklyCheckIn,
    ),
    'calculation': _calculationDebugJson(viewModel.calculation),
    'days': viewModel.days.map(_windowDayDebugJson).toList(growable: false),
  };
}

Map<String, Object?>? _pendingWeeklyCheckInDebugJson(
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

Map<String, Object?>? _calculationDebugJson(
  CalorieWeeklyCheckInCalculation? calculation,
) {
  if (calculation == null) {
    return null;
  }
  return <String, Object?>{
    'trend_weight_change_per_day': calculation.trendWeightChangePerDay,
    'average_intake_kcal': calculation.averageIntakeKcal,
    'measured_true_tdee_kcal': calculation.measuredTrueTdeeKcal,
    'calculated_true_tdee_kcal': calculation.calculatedTrueTdeeKcal,
    'new_goal_kcal': calculation.newGoalKcal,
    'last_week_average_active_kcal': calculation.lastWeekAverageActiveKcal,
    'today_active_kcal': calculation.todayActiveKcal,
    'activity_delta_kcal': calculation.activityDeltaKcal,
    'dynamic_goal_today_kcal': calculation.dynamicGoalTodayKcal,
  };
}

Map<String, Object?> _windowDayDebugJson(CalorieWeeklyCheckInWindowDay day) {
  return <String, Object?>{
    'day': diaryDayKey(day.day),
    'has_entries': day.hasEntries,
    'logged_intake_kcal': day.loggedIntakeKcal,
    'resolved_intake_kcal': day.resolvedIntakeKcal,
    'is_skipped_intake_day': day.isSkippedIntakeDay,
    'is_heart_day': day.isHeartDay,
    'active_kcal': day.activeKcal,
    'weight_kg': day.weightKg,
  };
}

void _logCalorieSettingsDebugDump(String dump) {
  _logDebugDump(name: 'CalorieSettingsDebugDump', dump: dump);
}

void _logDebugDump({required String name, required String dump}) {
  const chunkLength = 800;
  for (var offset = 0; offset < dump.length; offset += chunkLength) {
    final end = offset + chunkLength > dump.length
        ? dump.length
        : offset + chunkLength;
    developer.log(
      dump.substring(offset, end),
      name: name,
    );
  }
}

/// Controller for calorie page actions.
final caloriePageActionControllerProvider =
    AsyncNotifierProvider<CaloriePageActionController, void>(
      CaloriePageActionController.new,
    );
