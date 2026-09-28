import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_debug_action_formatting.dart';
import 'package:yamt/features/calories/application/calorie_debug_dump_service.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/calories/data/calorie_debug_file_exporter.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/presentation/models/calorie_debug_action_results.dart';
import 'package:yamt/features/health/application/health_connection_controller.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';

part 'calorie_debug_action_controller.g.dart';

/// Handles calorie debug actions that need providers.
@riverpod
class CalorieDebugActionController extends _$CalorieDebugActionController {
  @override
  FutureOr<void> build() {
    return null;
  }

  /// Keeps this controller alive while [action] runs.
  Future<T> _whileAlive<T>(Future<T> Function() action) async {
    final link = ref.keepAlive();
    try {
      return await action();
    } finally {
      link.close();
    }
  }

  /// Exports calorie debug dump as TXT.
  Future<CalorieDebugDumpPrintResult> printDebugDump({
    required DateTime now,
    required String saveDialogTitle,
  }) => _whileAlive(
    () => _printDebugDump(now: now, saveDialogTitle: saveDialogTitle),
  );

  Future<CalorieDebugDumpPrintResult> _printDebugDump({
    required DateTime now,
    required String saveDialogTitle,
  }) async {
    final calorieLogRepository = ref.read(calorieLogRepositoryProvider);
    final healthWeightService = ref.read(healthWeightServiceProvider);
    final fileExporter = ref.read(calorieDebugFileExporterProvider);
    final manualWeightRepository = ref.read(
      manualHealthWeightRepositoryProvider,
    );
    final healthStatusFuture = ref.watch(
      healthConnectionControllerProvider.future,
    );
    final settingsFuture = ref.watch(calorieGoalControllerProvider.future);

    try {
      final result = await buildCalorieDebugDump(
        calorieLogRepository: calorieLogRepository,
        healthWeightService: healthWeightService,
        manualWeightRepository: manualWeightRepository,
        healthStatusFuture: healthStatusFuture,
        settingsFuture: settingsFuture,
        now: now,
      );
      final exportResult = await fileExporter.saveText(
        dialogTitle: saveDialogTitle,
        fileName: calorieDebugDumpFileName(now),
        text: calorieDebugDumpText(result: result, generatedAt: now),
      );
      return switch (exportResult) {
        CalorieDebugFileExportSaved(:final path) =>
          CalorieDebugDumpPrintSuccess(
            rowCount: result.rowCount,
            filePath: path,
          ),
        CalorieDebugFileExportCanceled() =>
          const CalorieDebugDumpPrintCanceled(),
      };
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to build or export calorie debug dump.',
        name: 'CalorieDebugDump',
        error: error,
        stackTrace: stackTrace,
      );
      return const CalorieDebugDumpPrintFailure();
    }
  }

  /// Prints calorie settings debug dump.
  Future<CalorieSettingsDebugDumpPrintResult> printSettingsDebugDump() =>
      _whileAlive(_printSettingsDebugDump);

  Future<CalorieSettingsDebugDumpPrintResult> _printSettingsDebugDump() async {
    try {
      final settings = await ref.watch(calorieGoalControllerProvider.future);
      final encoded = const JsonEncoder.withIndent('  ')
          .convert(jsonDebugValue(settings.toJson()));
      logCalorieSettingsDebugDump(
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
  printWeeklyCheckInDebugDump() => _whileAlive(_printWeeklyCheckInDebugDump);

  Future<CalorieWeeklyCheckInDebugDumpPrintResult>
  _printWeeklyCheckInDebugDump() async {
    final checkInDataFuture = ref.watch(
      calorieWeeklyCheckInDataProvider.future,
    );
    try {
      final checkInData = await checkInDataFuture;
      final encoded = const JsonEncoder.withIndent('  ').convert(
        weeklyCheckInDataDebugJson(checkInData, now: ref.read(clockProvider)()),
      );
      logDebugDump(
        name: 'CalorieWeeklyCheckInDebugDump',
        dump: 'calorieWeeklyCheckInData\n$encoded',
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
}
