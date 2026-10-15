import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/application/health_connection_actions.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

part 'health_weight_cloud_sync_provider.g.dart';

const _logName = 'HealthWeightCloudSync';

/// Copies the Health weights of this device to the cloud, so every device
/// of the user computes with the same weights.
///
/// The diary keeps it running once the diary has its data; it runs again on
/// resume, on a new day, and when the first goal moves. It copies the
/// weights from the start of the first goal on, also those this app wrote to
/// Health: with Health ready, a manual weight is stored only there. A failed
/// sync is logged and waits for the next run.
@riverpod
Future<void> healthWeightCloudSync(Ref ref) async {
  final today = ref.watch(diaryTodayProvider);
  if (ref.watch(userDataCipherProvider) == null) {
    // No data key yet: nothing can be stored encrypted.
    return;
  }
  final repository = ref.watch(healthWeightSampleRepositoryProvider);
  final healthWeightService = ref.watch(healthWeightServiceProvider);
  final firstGoalStartFuture = ref.watch(
    calorieGoalControllerProvider.selectAsync(
      (settings) => settings.firstGoalStartDay,
    ),
  );
  final statusFuture = ref.watch(healthConnectionStatusProvider.future);
  try {
    final status = await statusFuture;
    final firstGoalStart = await firstGoalStartFuture;
    if (status.accessState != HealthDataAccessState.ready ||
        firstGoalStart == null ||
        !ref.mounted) {
      return;
    }
    final samples = await healthWeightService.loadWeightSamples(
      // The first check-in takes its start weight from the day before the
      // first counting day.
      startInclusive: previousDiaryDay(firstGoalStart),
      endExclusive: nextDiaryDay(today),
    );
    if (!ref.mounted) {
      return;
    }
    await repository.addSamples(samples);
  } on Object catch (error, stackTrace) {
    log(
      'Failed to sync Health weights to the cloud.',
      name: _logName,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
