import 'dart:developer' as developer;

import 'package:flutter/material.dart';
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
import 'package:yamt/l10n/app_localizations.dart';

/// Prints the calorie debug dump and reports the result with a snackbar.
Future<void> printCalorieDebugDumpFromPage({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime now,
}) async {
  final l10n = AppLocalizations.of(context)!;
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
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.caloriesDebugDumpPrinted(result.rowCount)),
        ),
      );
  } on Object catch (error, stackTrace) {
    developer.log(
      'Failed to build calorie debug dump.',
      name: 'CalorieDebugDump',
      error: error,
      stackTrace: stackTrace,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.caloriesDebugDumpFailed)),
      );
  }
}

/// Toggles skipped-intake state for a calorie day.
Future<void> toggleSkippedCalorieIntakeDay({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime selectedDay,
  required bool isSkipped,
}) async {
  final controller = ref.read(calorieWeeklyCheckInControllerProvider.notifier);
  final saved = await controller.setSkippedIntakeDay(
    day: selectedDay,
    isSkipped: isSkipped,
  );
  if (!context.mounted || saved) {
    return;
  }
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(l10n.caloriesGoalSaveFailed)));
}
