import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/manual_health_weight_entries_controller.dart';

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
  if (!ref.mounted) {
    return;
  }
  final hasManualWeight = manualEntries.any(
    (entry) => isSameDiaryDay(entry.day, normalizedDay),
  );
  if (hasManualWeight) {
    return;
  }

  final connectionStatus = await ref
      .read(healthConnectionServiceProvider)
      .loadStatus();
  if (!ref.mounted) {
    return;
  }
  if (connectionStatus.accessState == HealthDataAccessState.ready) {
    final healthSamples = await ref
        .read(healthWeightServiceProvider)
        .loadWeightSamples(
          startInclusive: normalizedDay,
          endExclusive: nextDiaryDay(normalizedDay),
        );
    if (!ref.mounted) {
      return;
    }
    final hasHealthWeight = healthSamples.any(
      (sample) => isSameDiaryDay(sample.recordedAt, normalizedDay),
    );
    if (hasHealthWeight) {
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
