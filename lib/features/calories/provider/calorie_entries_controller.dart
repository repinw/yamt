import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_entry_post_persist_hook.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';

part 'calorie_entries_controller.g.dart';

const _entriesControllerLogName = 'CalorieEntriesController';

/// Defines calorie day summary.
class CalorieDaySummary {
  /// The calorie day summary.
  const CalorieDaySummary({
    required this.entryCount,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  /// The entry count.
  final int entryCount;

  /// The total kcal.
  final double totalKcal;

  /// The total protein.
  final double totalProtein;

  /// The total carbs.
  final double totalCarbs;

  /// The total fat.
  final double totalFat;
}

/// Defines calorie meal section.
class CalorieMealSection {
  /// The calorie meal section.
  const CalorieMealSection({
    required this.mealType,
    required this.entries,
    required this.totalKcal,
  });

  /// The meal type.
  final MealType mealType;

  /// The entries.
  final List<CalorieEntry> entries;

  /// The total kcal.
  final double totalKcal;
}

/// Defines calorie day view data.
class CalorieDayViewData {
  /// The calorie day view data.
  const CalorieDayViewData({
    required this.selectedDay,
    required this.summary,
    required this.sections,
    required this.goalKcal,
    required this.remainingKcal,
    required this.progress,
  });

  /// The selected day.
  final DateTime selectedDay;

  /// The summary.
  final CalorieDaySummary summary;

  /// The sections.
  final List<CalorieMealSection> sections;

  /// The goal kcal.
  final double goalKcal;

  /// The remaining kcal.
  final double remainingKcal;

  /// The progress.
  final double progress;
}

/// Defines calorie entries controller.
@riverpod
class CalorieEntriesController extends _$CalorieEntriesController {
  // Subscription is cancelled by _disposeSubscription.
  // ignore: cancel_subscriptions
  StreamSubscription<List<CalorieEntry>>? _entriesSubscription;
  Future<void> _mutationQueue = Future<void>.value();

  @override
  FutureOr<List<CalorieEntry>> build() {
    ref
      ..watch(calorieLogRepositoryProvider)
      ..watch(calorieDayControllerProvider)
      ..onDispose(_disposeSubscription);
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
  Future<bool> saveEntry(
    CalorieEntry entry, {
    CalorieInventoryCreateContext? inventoryContext,
    CalorieScannedSourceRef? scannedSourceRef,
    Future<bool> Function(CalorieEntry entry)? persistEntry,
  }) {
    final keepAliveLink = ref.keepAlive();
    final selectedDay = ref.read(calorieDayControllerProvider);
    final calorieLogRepository = ref.read(calorieLogRepositoryProvider);
    log(
      'Starting save for calorie entry ${entry.id} '
      '(selectedDay=$selectedDay, '
      'customPersist=${persistEntry != null}, '
      'scannedSource=${scannedSourceRef != null}).',
      name: _entriesControllerLogName,
    );
    final postPersistCallbacks = <Future<void> Function()>[
      () => ref
          .read(calorieGoalControllerProvider.notifier)
          .clearSkippedIntakeDay(entry.loggedAt),
      if (scannedSourceRef != null)
        () => _saveUserProductOverride(
          entry: entry,
          scannedSourceRef: scannedSourceRef,
        ),
    ];
    return _runOptimisticMutation(
      buildNextEntries: (previousEntries) {
        return _applySavedEntry(
          previousEntries: previousEntries,
          entry: entry,
          selectedDay: selectedDay,
        );
      },
      persist: () async {
        if (persistEntry != null) {
          log(
            'Persisting calorie entry ${entry.id} via custom save flow.',
            name: _entriesControllerLogName,
          );
          final saved = await persistEntry(entry);
          log(
            'Custom save flow for calorie entry ${entry.id} returned $saved.',
            name: _entriesControllerLogName,
          );
          return saved;
        }

        log(
          'Persisting calorie entry ${entry.id} via calorie log repository.',
          name: _entriesControllerLogName,
        );
        final saved = await calorieLogRepository.saveEntry(entry);
        log(
          'Calorie log repository save for ${entry.id} returned $saved.',
          name: _entriesControllerLogName,
        );
        return saved;
      },
      failureLogMessage: 'Failed to persist calorie entry ${entry.id}.',
      onPersisted: (previousEntries, _) {
        return _runPostPersistCallbacks([
          ...postPersistCallbacks,
          () => _invalidateSnapshotsForSavedEntry(
            entry: entry,
            previousEntries: previousEntries,
          ),
          () => ref.read(calorieEntryPostPersistHookProvider)(
            entry: entry,
            inventoryContext: inventoryContext,
            scannedSourceRef: scannedSourceRef,
          ),
        ]);
      },
    ).whenComplete(keepAliveLink.close);
  }

  /// Delete entry.
  Future<bool> deleteEntry(String entryId) {
    final keepAliveLink = ref.keepAlive();
    return _runOptimisticMutation(
      buildNextEntries: (previousEntries) {
        return previousEntries
            .where((entry) => entry.id != entryId)
            .toList(growable: false);
      },
      persist: () =>
          ref.read(calorieLogRepositoryProvider).deleteEntry(entryId),
      failureLogMessage: 'Failed to delete calorie entry $entryId.',
      onPersisted: (previousEntries, _) {
        return _invalidateSnapshotsForDeletedEntry(
          entryId: entryId,
          previousEntries: previousEntries,
        );
      },
    ).whenComplete(keepAliveLink.close);
  }

  Future<bool> _runOptimisticMutation({
    required List<CalorieEntry> Function(List<CalorieEntry> previousEntries)
    buildNextEntries,
    required Future<bool> Function() persist,
    required String failureLogMessage,
    Future<void> Function(
      List<CalorieEntry> previousEntries,
      List<CalorieEntry> nextEntries,
    )?
    onPersisted,
  }) {
    return _runSerializedMutation(() async {
      final previousEntries = await _currentEntries();
      final nextEntries = buildNextEntries(previousEntries);

      if (!listEquals(previousEntries, nextEntries) && ref.mounted) {
        state = AsyncData(nextEntries);
      }

      try {
        final persisted = await persist();
        if (!persisted) {
          log(
            '$failureLogMessage Persist returned false without throwing.',
            name: _entriesControllerLogName,
          );
          _restoreEntries(previousEntries);
          return false;
        }
      } on Object catch (error, stackTrace) {
        log(
          failureLogMessage,
          name: _entriesControllerLogName,
          error: error,
          stackTrace: stackTrace,
        );
        _restoreEntries(previousEntries);
        return false;
      }

      if (ref.mounted) {
        ref.read(calorieOverviewRevisionProvider.notifier).markChanged();
      }

      if (onPersisted != null) {
        await _runAfterPersistCallback(
          () => onPersisted(previousEntries, nextEntries),
        );
      }

      return true;
    });
  }

  Future<void> _runAfterPersistCallback(
    Future<void> Function() callback,
  ) async {
    try {
      await callback();
    } on Object catch (error, stackTrace) {
      log(
        'Post-persist callback failed for calorie entry mutation.',
        name: _entriesControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _runPostPersistCallbacks(
    List<Future<void> Function()> callbacks,
  ) async {
    for (final callback in callbacks) {
      await _runAfterPersistCallback(callback);
    }
  }

  Future<void> _invalidateSnapshotsForSavedEntry({
    required CalorieEntry entry,
    required List<CalorieEntry> previousEntries,
  }) {
    final previousEntry = previousEntries
        .where((existingEntry) => existingEntry.id == entry.id)
        .firstOrNull;
    final invalidationDay = _earliestDiaryDay(
      entry.loggedAt,
      previousEntry?.loggedAt,
    );
    return ref
        .read(calorieGoalControllerProvider.notifier)
        .invalidateWeeklyCheckInSnapshotsFromDay(invalidationDay);
  }

  Future<void> _invalidateSnapshotsForDeletedEntry({
    required String entryId,
    required List<CalorieEntry> previousEntries,
  }) async {
    final deletedEntry = previousEntries
        .where((existingEntry) => existingEntry.id == entryId)
        .firstOrNull;
    if (deletedEntry == null) {
      return;
    }
    await ref
        .read(calorieGoalControllerProvider.notifier)
        .invalidateWeeklyCheckInSnapshotsFromDay(deletedEntry.loggedAt);
  }

  void _restoreEntries(List<CalorieEntry> entries) {
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
            _onRealtimeEntries(entries);
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
    final currentSubscription = _entriesSubscription;
    _entriesSubscription = null;
    if (currentSubscription != null) {
      unawaited(currentSubscription.cancel());
    }
  }

  void _onRealtimeEntries(List<CalorieEntry> entries) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(entries);
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
      final entries = await ref
          .read(calorieLogRepositoryProvider)
          .readEntriesForDay(selectedDay);
      return entries;
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

  List<CalorieEntry> _applySavedEntry({
    required List<CalorieEntry> previousEntries,
    required CalorieEntry entry,
    required DateTime selectedDay,
  }) {
    final entries = List<CalorieEntry>.from(previousEntries);
    final existingIndex = entries.indexWhere((item) => item.id == entry.id);
    final shouldBeVisible = _isSameLocalDay(entry.loggedAt, selectedDay);

    if (existingIndex >= 0 && !shouldBeVisible) {
      entries.removeAt(existingIndex);
      return _sortEntries(entries);
    }

    if (existingIndex >= 0) {
      entries[existingIndex] = entry;
      return _sortEntries(entries);
    }

    if (shouldBeVisible) {
      entries.add(entry);
    }

    return _sortEntries(entries);
  }

  List<CalorieEntry> _sortEntries(List<CalorieEntry> entries) {
    entries.sort((left, right) {
      final byDate = left.loggedAt.compareTo(right.loggedAt);
      if (byDate != 0) {
        return byDate;
      }
      return left.id.compareTo(right.id);
    });
    return List<CalorieEntry>.unmodifiable(entries);
  }

  bool _isSameLocalDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<bool> _runSerializedMutation(Future<bool> Function() mutation) {
    final result = Completer<bool>();

    _mutationQueue = _mutationQueue
        .catchError((Object error, StackTrace stackTrace) {
          log(
            'Recovering calorie mutation queue from previous failure.',
            name: _entriesControllerLogName,
            error: error,
            stackTrace: stackTrace,
          );
        })
        .then((_) async {
          try {
            final mutationResult = await mutation();
            result.complete(mutationResult);
          } on Object catch (error, stackTrace) {
            log(
              'Unexpected calorie mutation error.',
              name: _entriesControllerLogName,
              error: error,
              stackTrace: stackTrace,
            );
            result.complete(false);
          }
        });

    return result.future;
  }

  Future<void> _saveUserProductOverride({
    required CalorieEntry entry,
    required CalorieScannedSourceRef scannedSourceRef,
  }) async {
    final cacheRepository = ref.read(calorieProductCacheRepositoryProvider);
    final now = DateTime.now();
    final profile = CalorieProductProfile.fromEntry(
      entry: entry,
      barcode: scannedSourceRef.barcode,
      source: scannedSourceRef.source,
      offProductId: scannedSourceRef.offProductId,
      imageUrl: entry.imageUrl,
      now: now,
    );
    final saved = await cacheRepository.saveUserOverride(
      profile: profile,
      reason: 'user_edit_after_scan',
    );
    if (!saved) {
      log(
        'Failed to persist user calorie override '
        'for ${scannedSourceRef.barcode}.',
        name: _entriesControllerLogName,
      );
    }
  }
}

DateTime _earliestDiaryDay(DateTime day, DateTime? otherDay) {
  final normalizedDay = normalizeDiaryDay(day);
  final normalizedOtherDay = otherDay == null
      ? null
      : normalizeDiaryDay(otherDay);
  if (normalizedOtherDay == null ||
      normalizedDay.isBefore(normalizedOtherDay)) {
    return normalizedDay;
  }
  return normalizedOtherDay;
}

/// Calorie entry by id.
@riverpod
Future<CalorieEntry?> calorieEntryById(Ref ref, String entryId) async {
  return ref.read(calorieLogRepositoryProvider).getById(entryId);
}

/// Calorie day view data.
@riverpod
AsyncValue<CalorieDayViewData> calorieDayViewData(Ref ref) {
  final selectedDay = ref.watch(calorieDayControllerProvider);
  final entriesState = ref.watch(calorieEntriesControllerProvider);
  final resolvedGoalState = ref.watch(
    resolvedCalorieGoalForDayProvider(selectedDay),
  );
  final entries = entriesState.asData?.value;
  final resolvedGoal = resolvedGoalState.asData?.value;
  if (entries != null && resolvedGoal != null) {
    return AsyncData(
      _buildCalorieDayViewData(
        selectedDay: selectedDay,
        entries: entries,
        goalKcal: resolvedGoal.goalKcal,
      ),
    );
  }
  final entriesError = entriesState.asError;
  if (entriesError != null) {
    return AsyncError(entriesError.error, entriesError.stackTrace);
  }
  final goalError = resolvedGoalState.asError;
  if (goalError != null) {
    return AsyncError(goalError.error, goalError.stackTrace);
  }
  return const AsyncLoading();
}

CalorieDayViewData _buildCalorieDayViewData({
  required DateTime selectedDay,
  required List<CalorieEntry> entries,
  required double goalKcal,
}) {
  final aggregate = _aggregate(entries);
  final remaining = goalKcal <= 0
      ? 0.0
      : goalKcal - aggregate.summary.totalKcal;
  final progress = goalKcal <= 0
      ? 0.0
      : (aggregate.summary.totalKcal / goalKcal).clamp(0.0, 1.0);

  return CalorieDayViewData(
    selectedDay: selectedDay,
    summary: aggregate.summary,
    sections: aggregate.sections,
    goalKcal: goalKcal,
    remainingKcal: remaining,
    progress: progress,
  );
}

({CalorieDaySummary summary, List<CalorieMealSection> sections}) _aggregate(
  List<CalorieEntry> entries,
) {
  final sectionEntries = <MealType, List<CalorieEntry>>{
    for (final mealType in MealType.sectionOrder) mealType: <CalorieEntry>[],
  };
  final sectionKcal = <MealType, double>{
    for (final mealType in MealType.sectionOrder) mealType: 0,
  };

  var totalKcal = 0.0;
  var totalProtein = 0.0;
  var totalCarbs = 0.0;
  var totalFat = 0.0;

  for (final entry in entries) {
    totalKcal += entry.totalKcal;
    totalProtein += entry.totalProtein;
    totalCarbs += entry.totalCarbs;
    totalFat += entry.totalFat;

    sectionEntries[entry.mealType]?.add(entry);
    sectionKcal[entry.mealType] =
        (sectionKcal[entry.mealType] ?? 0) + entry.totalKcal;
  }

  final sections = MealType.sectionOrder
      .map((mealType) {
        final mealEntries = sectionEntries[mealType] ?? const <CalorieEntry>[];
        return CalorieMealSection(
          mealType: mealType,
          entries: List<CalorieEntry>.unmodifiable(mealEntries),
          totalKcal: sectionKcal[mealType] ?? 0,
        );
      })
      .toList(growable: false);

  return (
    summary: CalorieDaySummary(
      entryCount: entries.length,
      totalKcal: totalKcal,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
    ),
    sections: sections,
  );
}
