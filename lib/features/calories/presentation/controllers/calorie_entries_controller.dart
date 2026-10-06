import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_entry_mutations.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_mutation.dart';
import 'package:yamt/features/calories/presentation/controllers/calorie_day_controller.dart';
import 'package:yamt/features/calories/presentation/controllers/calorie_entries_mutation_steps.dart';

part 'calorie_entries_controller.g.dart';

const _entriesControllerLogName = 'CalorieEntriesController';

/// Defines calorie entries controller.
@riverpod
class CalorieEntriesController extends _$CalorieEntriesController {
  StreamSubscription<List<CalorieEntry>>? _entriesSubscription;
  late final _steps = CalorieEntriesMutationSteps(
    currentEntries: _currentEntries,
    setEntries: _setEntries,
  );

  @override
  FutureOr<List<CalorieEntry>> build() {
    ref
      ..watch(calorieLogRepositoryProvider)
      ..watch(calorieDayControllerProvider)
      ..onDispose(_disposeSubscription);
    final mutationsSub = ref
        .read(calorieEntryMutationsProvider)
        .events
        .listen(_onEntryMutation);
    ref.onDispose(mutationsSub.cancel);
    return _restartSubscription();
  }

  /// Refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_restartSubscription);
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// Save entry.
  Future<bool> saveEntry(CalorieEntry entry, {bool isNewEntry = false}) {
    final selectedDay = ref.read(calorieDayControllerProvider);
    final calorieLogRepository = ref.read(calorieLogRepositoryProvider);
    log(
      'Starting save for calorie entry ${entry.id} '
      '(selectedDay=$selectedDay).',
      name: _entriesControllerLogName,
    );
    return _runOptimisticMutation(
      buildNextEntries: (previousEntries) => applySavedCalorieEntry(
        previousEntries: previousEntries,
        entry: entry,
        selectedDay: selectedDay,
      ),
      persist: () => calorieLogRepository.saveEntry(entry),
      failureLogMessage: 'Failed to persist calorie entry ${entry.id}.',
      followUp: (previousEntries) {
        _recordMutation(
          CalorieEntryMutation(
            kind: isNewEntry
                ? CalorieEntryMutationKind.created
                : CalorieEntryMutationKind.updated,
            entryId: entry.id,
            entry: entry,
          ),
        );
        return runCalorieEntryFollowUps([
          () => ref
              .read(calorieGoalControllerProvider.notifier)
              .clearSkippedIntakeDay(entry.loggedAt),
          () => _invalidateSnapshotsFromDay(
            earliestCalorieDiaryDay(
              entry.loggedAt,
              previousEntries
                  .where((existing) => existing.id == entry.id)
                  .firstOrNull
                  ?.loggedAt,
            ),
          ),
        ]);
      },
    );
  }

  /// Delete entry.
  Future<bool> deleteEntry(String entryId) {
    return _runOptimisticMutation(
      buildNextEntries: (previousEntries) => previousEntries
          .where((entry) => entry.id != entryId)
          .toList(growable: false),
      persist: () =>
          ref.read(calorieLogRepositoryProvider).deleteEntry(entryId),
      failureLogMessage: 'Failed to delete calorie entry $entryId.',
      followUp: (previousEntries) async {
        _recordMutation(
          CalorieEntryMutation(
            kind: CalorieEntryMutationKind.deleted,
            entryId: entryId,
          ),
        );
        final deletedEntry = previousEntries
            .where((existingEntry) => existingEntry.id == entryId)
            .firstOrNull;
        if (deletedEntry != null) {
          await _invalidateSnapshotsFromDay(deletedEntry.loggedAt);
        }
      },
    );
  }

  /// Runs one optimistic mutation. The provider stays alive until its
  /// background follow-up work is done.
  Future<bool> _runOptimisticMutation({
    required List<CalorieEntry> Function(List<CalorieEntry> previousEntries)
    buildNextEntries,
    required Future<bool> Function() persist,
    required String failureLogMessage,
    required Future<void> Function(List<CalorieEntry> previousEntries) followUp,
  }) {
    final keepAliveLink = ref.keepAlive();
    final run = _steps.run(
      buildNextEntries: buildNextEntries,
      persist: persist,
      failureLogMessage: failureLogMessage,
      onPersisted: () {
        if (ref.mounted) {
          ref.read(calorieOverviewRevisionProvider.notifier).markChanged();
        }
      },
      followUp: followUp,
    );
    unawaited(run.done.whenComplete(keepAliveLink.close));
    return run.result;
  }

  void _recordMutation(CalorieEntryMutation mutation) {
    ref.read(calorieEntryMutationsProvider).record(mutation);
  }

  Future<void> _invalidateSnapshotsFromDay(DateTime day) async {
    await ref
        .read(calorieGoalControllerProvider.notifier)
        .invalidateWeeklyCheckInSnapshotsFromDay(day);
  }

  void _setEntries(List<CalorieEntry> entries) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(entries);
  }

  Future<List<CalorieEntry>> _restartSubscription() {
    final initialEntries = Completer<List<CalorieEntry>>();
    final repository = ref.read(calorieLogRepositoryProvider);
    final selectedDay = ref.read(calorieDayControllerProvider);
    _disposeSubscription();

    _entriesSubscription = repository
        .watchEntriesForDay(selectedDay)
        .listen(
          (entries) {
            if (!initialEntries.isCompleted) {
              initialEntries.complete(entries);
              return;
            }
            _setEntries(entries);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!initialEntries.isCompleted) {
              initialEntries.completeError(error, stackTrace);
              return;
            }
            _onRealtimeError(error, stackTrace);
          },
        );

    return initialEntries.future;
  }

  void _disposeSubscription() {
    unawaited(_entriesSubscription?.cancel());
    _entriesSubscription = null;
  }

  void _onEntryMutation(CalorieEntryMutation mutation) {
    final currentVal = state.value;
    if (currentVal == null) {
      return;
    }
    final nextEntries = applyCalorieEntryMutation(
      entries: currentVal,
      mutation: mutation,
      selectedDay: ref.read(calorieDayControllerProvider),
    );
    if (!listEquals(currentVal, nextEntries)) {
      _setEntries(nextEntries);
    }
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    log(
      'Calorie entries realtime error.',
      name: _entriesControllerLogName,
      error: error,
      stackTrace: stackTrace,
    );
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }

  Future<List<CalorieEntry>> _currentEntries() async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }

    final selectedDay = ref.read(calorieDayControllerProvider);
    try {
      return await ref
          .read(calorieLogRepositoryProvider)
          .readEntriesForDay(selectedDay);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read current calorie entries for mutation fallback.',
        name: _entriesControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <CalorieEntry>[];
    }
  }
}
