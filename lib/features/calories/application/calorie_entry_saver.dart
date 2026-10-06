import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_entry_mutations.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_mutation.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

part 'calorie_entry_saver.g.dart';

const _entrySaverLogName = 'CalorieEntrySaver';

/// Saves a calorie entry through the Calories application boundary.
typedef CalorieEntrySaver = Future<bool> Function(
  CalorieEntry entry, {
  bool isNewEntry,
  CalorieScannedSourceRef? scannedSourceRef,
  Future<bool> Function(CalorieEntry entry)? persistEntry,
});

/// Provides calorie-entry persistence without exposing the Calories controller.
@riverpod
CalorieEntrySaver calorieEntrySaver(Ref ref) {
  final repository = ref.watch(calorieLogRepositoryProvider);
  final mutations = ref.watch(calorieEntryMutationsProvider);
  final overviewRevision = ref.read(calorieOverviewRevisionProvider.notifier);
  final cacheRepository = ref.read(calorieProductCacheRepositoryProvider);
  final clock = ref.read(clockProvider);
  // Taken before the save: recording the mutation rebuilds this provider, so
  // its ref is no longer usable afterwards. Watched so the goal controller
  // stays alive for the follow-up writes.
  final goalController = ref.watch(calorieGoalControllerProvider.notifier);

  return (entry, {isNewEntry = false, scannedSourceRef, persistEntry}) async {
    final bool saved;
    if (persistEntry != null) {
      saved = await persistEntry(entry);
    } else {
      saved = await repository.saveEntry(entry);
    }
    if (!saved) {
      return false;
    }

    overviewRevision.markChanged();
    mutations.record(
      CalorieEntryMutation(
        kind: isNewEntry
            ? CalorieEntryMutationKind.created
            : CalorieEntryMutationKind.updated,
        entryId: entry.id,
        entry: entry,
      ),
    );

    // Follow-up writes run in the background so the caller returns at once.
    // Both rewrite the settings, so they run one after the other.
    _runInBackground(
      'Failed to update the settings for the entry day.',
      () async {
        await goalController.clearSkippedIntakeDay(entry.loggedAt);
        await goalController.invalidateWeeklyCheckInSnapshotsFromDay(
          entry.loggedAt,
        );
      },
    );

    if (scannedSourceRef != null) {
      _runInBackground('Failed to save user override.', () async {
        final saved = await cacheRepository.saveUserOverride(
          profile: CalorieProductProfile.fromEntry(
            entry: entry,
            barcode: scannedSourceRef.barcode,
            source: scannedSourceRef.source,
            offProductId: scannedSourceRef.offProductId,
            imageUrl: entry.imageUrl,
            now: clock(),
          ),
          reason: 'user_edit_after_scan',
        );
        if (!saved) {
          log(
            'Failed to save user override for ${scannedSourceRef.barcode}.',
            name: _entrySaverLogName,
          );
        }
      });
    }

    return true;
  };
}

void _runInBackground(String failureMessage, Future<void> Function() action) {
  // A try block, not catchError: [action] may return a Future<bool>, whose
  // catchError handler would have to return a bool.
  unawaited(() async {
    try {
      await action();
    } on Object catch (error, stackTrace) {
      log(
        failureMessage,
        name: _entrySaverLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }());
}
