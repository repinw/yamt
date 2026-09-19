import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_mutation.dart';
import 'package:yamt/features/calories/domain/calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/provider/calorie_entry_mutations.dart';
import 'package:yamt/features/calories/provider/calorie_entry_post_persist_hook.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_overview_revision_provider.dart';

part 'calorie_entry_saver.g.dart';

const _entrySaverLogName = 'CalorieEntrySaver';

/// Saves a calorie entry through the Calories application boundary.
typedef CalorieEntrySaver = Future<bool> Function(
  CalorieEntry entry, {
  bool isNewEntry,
  CalorieInventoryCreateContext? inventoryContext,
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
  final postPersistHook = ref.read(calorieEntryPostPersistHookProvider);

  return (
    entry, {
    isNewEntry = false,
    inventoryContext,
    scannedSourceRef,
    persistEntry,
  }) async {
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
    _runInBackground(
      'Failed to clear skipped intake day.',
      () => ref
          .read(calorieGoalControllerProvider.notifier)
          .clearSkippedIntakeDay(entry.loggedAt),
    );

    if (scannedSourceRef != null) {
      _runInBackground(
        'Failed to save user override.',
        () => cacheRepository.saveUserOverride(
          profile: CalorieProductProfile.fromEntry(
            entry: entry,
            barcode: scannedSourceRef.barcode,
            source: scannedSourceRef.source,
            offProductId: scannedSourceRef.offProductId,
            imageUrl: entry.imageUrl,
            now: DateTime.now(),
          ),
          reason: 'user_edit_after_scan',
        ),
      );
    }

    _runInBackground(
      'Post-persist hook failed.',
      () => postPersistHook(
        entry: entry,
        inventoryContext: inventoryContext,
        scannedSourceRef: scannedSourceRef,
      ),
    );

    return true;
  };
}

void _runInBackground(String failureMessage, Future<void> Function() action) {
  unawaited(
    Future<void>.sync(action).catchError((Object error, StackTrace stackTrace) {
      log(
        failureMessage,
        name: _entrySaverLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }),
  );
}
