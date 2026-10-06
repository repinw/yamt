import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_mutation.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

const _logName = 'CalorieEntriesController';

/// A started optimistic mutation: `result` completes when the entry list is
/// persisted, `done` when its follow-up work has finished too.
typedef CalorieEntriesMutationRun = ({Future<bool> result, Future<void> done});

/// Runs the optimistic save and delete steps of `CalorieEntriesController`
/// one after another.
class CalorieEntriesMutationSteps {
  /// Creates the steps. `currentEntries` reads the entries of the selected
  /// day, `setEntries` shows a list in the controller state.
  new({required this._currentEntries, required this._setEntries});

  final Future<List<CalorieEntry>> Function() _currentEntries;
  final void Function(List<CalorieEntry> entries) _setEntries;
  Future<void> _queue = Future<void>.value();

  /// Applies `buildNextEntries` to the state at once and persists it.
  ///
  /// The result completes as soon as `persist` reports success. A failure
  /// restores the previous entries. `onPersisted` runs right after a
  /// successful persist; `followUp` runs in the background, so follow-up
  /// writes never block the caller.
  CalorieEntriesMutationRun run({
    required List<CalorieEntry> Function(List<CalorieEntry> previousEntries)
    buildNextEntries,
    required Future<bool> Function() persist,
    required String failureLogMessage,
    required void Function() onPersisted,
    Future<void> Function(List<CalorieEntry> previousEntries)? followUp,
  }) {
    var background = Future<void>.value();
    final result = _serialized(() async {
      final previousEntries = await _currentEntries();
      final nextEntries = buildNextEntries(previousEntries);
      if (!listEquals(previousEntries, nextEntries)) {
        _setEntries(nextEntries);
      }
      try {
        if (!await persist()) {
          log(
            '$failureLogMessage Persist returned false without throwing.',
            name: _logName,
          );
          _setEntries(previousEntries);
          return false;
        }
      } on Object catch (error, stackTrace) {
        log(
          failureLogMessage,
          name: _logName,
          error: error,
          stackTrace: stackTrace,
        );
        _setEntries(previousEntries);
        return false;
      }
      onPersisted();
      if (followUp != null) {
        background = runCalorieEntryFollowUps([
          () => followUp(previousEntries),
        ]);
      }
      return true;
    });
    return (result: result, done: result.then((_) => background));
  }

  Future<bool> _serialized(Future<bool> Function() mutation) {
    final result = Completer<bool>();
    _queue = _queue
        .catchError((Object error, StackTrace stackTrace) {
          log(
            'Recovering calorie mutation queue from previous failure.',
            name: _logName,
            error: error,
            stackTrace: stackTrace,
          );
        })
        .then((_) async {
          try {
            result.complete(await mutation());
          } on Object catch (error, stackTrace) {
            log(
              'Unexpected calorie mutation error.',
              name: _logName,
              error: error,
              stackTrace: stackTrace,
            );
            result.complete(false);
          }
        });
    return result.future;
  }
}

/// Runs [callbacks] one after another and logs a failed one.
Future<void> runCalorieEntryFollowUps(
  List<Future<void> Function()> callbacks,
) async {
  for (final callback in callbacks) {
    try {
      await callback();
    } on Object catch (error, stackTrace) {
      log(
        'Post-persist callback failed for calorie entry mutation.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Returns [entries] after [mutation], limited to [selectedDay].
List<CalorieEntry> applyCalorieEntryMutation({
  required List<CalorieEntry> entries,
  required CalorieEntryMutation mutation,
  required DateTime selectedDay,
}) {
  return switch (mutation.kind) {
    CalorieEntryMutationKind.created ||
    CalorieEntryMutationKind.updated => switch (mutation.entry) {
      final entry? => applySavedCalorieEntry(
        previousEntries: entries,
        entry: entry,
        selectedDay: selectedDay,
      ),
      null => entries,
    },
    CalorieEntryMutationKind.deleted =>
      entries
          .where((entry) => entry.id != mutation.entryId)
          .toList(growable: false),
  };
}

/// Returns [previousEntries] with [entry] added, replaced, or removed when it
/// no longer belongs to [selectedDay], sorted by time.
List<CalorieEntry> applySavedCalorieEntry({
  required List<CalorieEntry> previousEntries,
  required CalorieEntry entry,
  required DateTime selectedDay,
}) {
  final entries = List<CalorieEntry>.from(previousEntries);
  final existingIndex = entries.indexWhere((item) => item.id == entry.id);
  final shouldBeVisible = isSameDiaryDay(entry.loggedAt, selectedDay);
  if (existingIndex >= 0 && !shouldBeVisible) {
    entries.removeAt(existingIndex);
  } else if (existingIndex >= 0) {
    entries[existingIndex] = entry;
  } else if (shouldBeVisible) {
    entries.add(entry);
  }
  entries.sort((left, right) {
    final byDate = left.loggedAt.compareTo(right.loggedAt);
    return byDate != 0 ? byDate : left.id.compareTo(right.id);
  });
  return List<CalorieEntry>.unmodifiable(entries);
}

/// The earlier diary day of [day] and [otherDay].
DateTime earliestCalorieDiaryDay(DateTime day, DateTime? otherDay) {
  final normalizedDay = normalizeDiaryDay(day);
  if (otherDay == null) {
    return normalizedDay;
  }
  final normalizedOtherDay = normalizeDiaryDay(otherDay);
  return normalizedDay.isBefore(normalizedOtherDay)
      ? normalizedDay
      : normalizedOtherDay;
}
