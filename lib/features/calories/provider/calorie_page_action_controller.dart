import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/application/'
    'calorie_debug_dump_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_controller.dart';
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

/// Controller for calorie page actions.
final caloriePageActionControllerProvider =
    AsyncNotifierProvider<CaloriePageActionController, void>(
      CaloriePageActionController.new,
    );
