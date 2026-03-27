import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_entries_controller.g.dart';

const _entriesControllerLogName = 'CalorieEntriesController';

class CalorieDaySummary {
  const CalorieDaySummary({
    required this.entryCount,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  final int entryCount;
  final double totalKcal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
}

class CalorieMealSection {
  const CalorieMealSection({
    required this.mealType,
    required this.entries,
    required this.totalKcal,
  });

  final MealType mealType;
  final List<CalorieEntry> entries;
  final double totalKcal;
}

class CalorieDayViewData {
  const CalorieDayViewData({
    required this.selectedDay,
    required this.summary,
    required this.sections,
    required this.goalKcal,
    required this.remainingKcal,
    required this.progress,
  });

  final DateTime selectedDay;
  final CalorieDaySummary summary;
  final List<CalorieMealSection> sections;
  final double goalKcal;
  final double remainingKcal;
  final double progress;
}

@riverpod
class CalorieEntriesController extends _$CalorieEntriesController {
  StreamSubscription<List<CalorieEntry>>? _entriesSubscription;
  Future<void> _mutationQueue = Future<void>.value();

  @override
  FutureOr<List<CalorieEntry>> build() {
    ref.watch(calorieLogRepositoryProvider);
    ref.watch(calorieDayControllerProvider);
    ref.onDispose(_disposeSubscription);
    final selectedDay = ref.read(calorieDayControllerProvider);
    log(
      'Building calorie entries controller day='
      '${_formatDebugDay(selectedDay)}.',
      name: _entriesControllerLogName,
    );
    return _restartSubscription();
  }

  Future<void> refresh() async {
    final selectedDay = ref.read(calorieDayControllerProvider);
    log(
      'Refreshing calorie entries day=${_formatDebugDay(selectedDay)}.',
      name: _entriesControllerLogName,
    );
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_restartSubscription);
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  Future<bool> saveEntry(
    CalorieEntry entry, {
    CalorieScannedSourceRef? scannedSourceRef,
  }) {
    final keepAliveLink = ref.keepAlive();
    final selectedDay = ref.read(calorieDayControllerProvider);
    return _runOptimisticMutation(
      buildNextEntries: (previousEntries) {
        return _applySavedEntry(
          previousEntries: previousEntries,
          entry: entry,
          selectedDay: selectedDay,
        );
      },
      persist: () => ref.read(calorieLogRepositoryProvider).saveEntry(entry),
      failureLogMessage: 'Failed to persist calorie entry ${entry.id}.',
      onPersisted: scannedSourceRef == null
          ? null
          : () => _saveUserProductOverride(
              entry: entry,
              scannedSourceRef: scannedSourceRef,
            ),
    ).whenComplete(keepAliveLink.close);
  }

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
    ).whenComplete(keepAliveLink.close);
  }

  Future<bool> _runOptimisticMutation({
    required List<CalorieEntry> Function(List<CalorieEntry> previousEntries)
    buildNextEntries,
    required Future<bool> Function() persist,
    required String failureLogMessage,
    Future<void> Function()? onPersisted,
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
          _restoreEntries(previousEntries);
          return false;
        }
      } catch (error, stackTrace) {
        log(
          failureLogMessage,
          name: _entriesControllerLogName,
          error: error,
          stackTrace: stackTrace,
        );
        _restoreEntries(previousEntries);
        return false;
      }

      if (onPersisted != null) {
        await _runAfterPersistCallback(onPersisted);
      }

      return true;
    });
  }

  Future<void> _runAfterPersistCallback(
    Future<void> Function() callback,
  ) async {
    try {
      await callback();
    } catch (error, stackTrace) {
      log(
        'Post-persist callback failed for calorie entry mutation.',
        name: _entriesControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
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
    log(
      'Restarting calorie entries subscription '
      'day=${_formatDebugDay(selectedDay)}.',
      name: _entriesControllerLogName,
    );

    _entriesSubscription = repository
        .watchEntriesForDay(selectedDay)
        .listen(
          (entries) {
            if (!initialEntries.isCompleted) {
              _logEntriesSnapshot(
                message: 'Received initial calorie entries snapshot.',
                day: selectedDay,
                entries: entries,
              );
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
    final selectedDay = ref.read(calorieDayControllerProvider);
    _logEntriesSnapshot(
      message: 'Received realtime calorie entries snapshot.',
      day: selectedDay,
      entries: entries,
    );
    state = AsyncData(entries);
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    final selectedDay = ref.read(calorieDayControllerProvider);
    log(
      'Calorie entries realtime error day=${_formatDebugDay(selectedDay)}.',
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
      log(
        'Falling back to repository read for current entries '
        'day=${_formatDebugDay(selectedDay)}.',
        name: _entriesControllerLogName,
      );
      final entries = await ref
          .read(calorieLogRepositoryProvider)
          .readEntriesForDay(selectedDay);
      _logEntriesSnapshot(
        message: 'Repository fallback read completed.',
        day: selectedDay,
        entries: entries,
      );
      return entries;
    } catch (error, stackTrace) {
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
          } catch (error, stackTrace) {
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

@riverpod
Future<CalorieEntry?> calorieEntryById(Ref ref, String entryId) async {
  return ref.read(calorieLogRepositoryProvider).getById(entryId);
}

@riverpod
AsyncValue<CalorieDayViewData> calorieDayViewData(Ref ref) {
  final selectedDay = ref.watch(calorieDayControllerProvider);
  final entriesState = ref.watch(calorieEntriesControllerProvider);
  final goalState = ref.watch(calorieGoalControllerProvider);

  return entriesState.whenData((entries) {
    final goalKcal =
        goalState.asData?.value.dailyKcalGoal ?? defaultDailyCalorieGoalKcal;
    final aggregate = _aggregate(entries);
    final remaining = goalKcal - aggregate.summary.totalKcal;
    final progress = goalKcal <= 0
        ? 0.0
        : (aggregate.summary.totalKcal / goalKcal).clamp(0.0, 1.0).toDouble();

    return CalorieDayViewData(
      selectedDay: selectedDay,
      summary: aggregate.summary,
      sections: aggregate.sections,
      goalKcal: goalKcal,
      remainingKcal: remaining,
      progress: progress,
    );
  });
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

void _logEntriesSnapshot({
  required String message,
  required DateTime day,
  required List<CalorieEntry> entries,
}) {
  log(
    '$message day=${_formatDebugDay(day)} '
    'entries=${entries.length} bundles=${_bundleCount(entries)}.',
    name: _entriesControllerLogName,
  );
}

int _bundleCount(List<CalorieEntry> entries) {
  return entries.where((entry) => entry.isBundle).length;
}

String _formatDebugDay(DateTime day) {
  final year = day.year.toString().padLeft(4, '0');
  final month = day.month.toString().padLeft(2, '0');
  final dayOfMonth = day.day.toString().padLeft(2, '0');
  return '$year-$month-$dayOfMonth';
}
