import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/application/manual_health_weight_entries_controller.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

/// Seeds the calculator starting weight into health/manual weight storage if missing.
Future<void> seedCalculatorWeightIfMissing({
  required Ref ref,
  required DateTime day,
  required double weightKg,
  required Future<bool> Function(DateTime day) onSeedSaved,
}) async {
  final normalizedDay = normalizeDiaryDay(day);
  final manualEntries = await ref
      .read(manualHealthWeightRepositoryProvider)
      .readEntries();
  final List<HealthWeightSample> healthSamples;
  try {
    // From the server, so a fresh cache does not hide a scale weight.
    healthSamples = await ref
        .read(healthWeightSampleRepositoryProvider)
        .loadSamples();
  } on Object catch (error, stackTrace) {
    // Without the samples a seed could double a scale weight; the goal is
    // saved, so only the seed is skipped.
    log(
      'Skipped the start weight seed: Health weights unreadable.',
      name: 'CalorieGoalSeedWeightFlow',
      error: error,
      stackTrace: stackTrace,
    );
    return;
  }
  if (!ref.mounted ||
      manualEntries.any((entry) => isSameDiaryDay(entry.day, normalizedDay)) ||
      healthSamples.any(
        (sample) => isSameDiaryDay(sample.recordedAt, normalizedDay),
      )) {
    return;
  }
  // The cloud has no samples before the first goal, and none since the
  // last sync, so this device's Health store counts too.
  final connectionStatus = await ref
      .read(healthConnectionServiceProvider)
      .loadStatus();
  if (!ref.mounted) {
    return;
  }
  if (connectionStatus.accessState == HealthDataAccessState.ready) {
    final localSamples = await ref
        .read(healthWeightServiceProvider)
        .loadWeightSamples(
          startInclusive: normalizedDay,
          endExclusive: nextDiaryDay(normalizedDay),
        );
    if (!ref.mounted || localSamples.isNotEmpty) {
      return;
    }
  }

  final saved = await ref
      .read(manualHealthWeightEntriesControllerProvider.notifier)
      .saveEntry(day: normalizedDay, weightKg: weightKg);
  if (saved && ref.mounted) {
    await onSeedSaved(normalizedDay);
  }
}
