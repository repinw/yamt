import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_weight_state_refresh.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/application/health_app_weight_service.dart';
import 'package:yamt/features/health/application/manual_health_weight_entries_controller.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';

part 'progress_weighing_controller.g.dart';

const _logName = 'ProgressWeighingController';

/// Changes, deletes, and ignores one weighing of the weight list. Each
/// action returns whether it worked and refreshes what depends on the
/// weight.
@riverpod
class ProgressWeighingController extends _$ProgressWeighingController {
  @override
  FutureOr<void> build() {
    // Kept alive with this controller, so its refresh finishes.
    ref.watch(calorieWeightStateRefreshProvider);
  }

  /// Whether this device can change [weighing]: a manual entry, or a Health
  /// weighing that this app wrote to the Health store of this device.
  /// `null` when the Health store of this device could not be read.
  Future<bool?> canChange(ProgressWeighing weighing) async {
    final sample = weighing.sample;
    if (sample == null) return true;
    if (!sample.isFromThisApp) return false;
    final link = ref.keepAlive();
    try {
      return await ref
          .read(healthAppWeightServiceProvider)
          .isOnThisDevice(sample);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read the Health weight of this device.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      link.close();
    }
  }

  /// Stores [weighing] as [weightKg] at [at].
  Future<bool> save(
    ProgressWeighing weighing, {
    required DateTime at,
    required double weightKg,
  }) {
    final entries = ref.read(
      manualHealthWeightEntriesControllerProvider.notifier,
    );
    return _run([weighing.day, at], () {
      return switch (weighing.entry) {
        final entry? => entries.updateEntry(
          entry,
          recordedAt: at,
          weightKg: weightKg,
        ),
        null => entries.updateAppWeight(
          weighing.sample!,
          recordedAt: at,
          weightKg: weightKg,
        ),
      };
    });
  }

  /// Deletes [weighing].
  Future<bool> delete(ProgressWeighing weighing) {
    final entries = ref.read(
      manualHealthWeightEntriesControllerProvider.notifier,
    );
    return _run([weighing.day], () {
      return switch (weighing.entry) {
        final entry? => entries.deleteEntry(entry),
        null => entries.deleteAppWeight(weighing.sample!),
      };
    });
  }

  /// Leaves the Health weighing [sample] out of every count, or counts it
  /// again, on all devices.
  Future<bool> setIgnored(HealthWeightSample sample, {required bool ignored}) {
    final repository = ref.read(healthWeightSampleRepositoryProvider);
    return _run([sample.recordedAt], () async {
      await repository.setIgnored(sample, ignored: ignored);
      return true;
    });
  }

  /// Opens the Health app.
  Future<bool> openHealth() async {
    try {
      await ref.read(healthConnectionServiceProvider).openHealthApp();
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to open the Health app.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Runs [action] and, once it worked, refreshes the weight state from the
  /// earliest of [days] on.
  Future<bool> _run(List<DateTime> days, Future<bool> Function() action) async {
    final link = ref.keepAlive();
    try {
      final done = await action();
      if (done && ref.mounted) {
        await ref.read(calorieWeightStateRefreshProvider)(
          day: normalizeDiaryDay(
            days.reduce((left, right) => left.isBefore(right) ? left : right),
          ),
        );
      }
      return done;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to change a weighing.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      link.close();
    }
  }
}
