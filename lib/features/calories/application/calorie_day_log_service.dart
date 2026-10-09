import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/last_planned_day_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';

part 'calorie_day_log_service.g.dart';

/// The calorie day log service.
@riverpod
CalorieDayLogService calorieDayLogService(Ref ref) {
  return CalorieDayLogService(
    plans: ref.watch(plannedEntryRepositoryProvider),
    overviewRevision: ref.watch(calorieOverviewRevisionProvider.notifier),
    lastPlannedDay: ref.watch(lastPlannedDayProvider.notifier),
    clock: ref.watch(clockProvider),
  );
}

/// Logs food on a diary day: decides whether it becomes a plan, saves plans,
/// and tells the diary dashboards and overviews about every change.
class CalorieDayLogService {
  /// Creates the service.
  const new({
    required this._plans,
    required this._overviewRevision,
    required this._lastPlannedDay,
    required this._clock,
  });

  final PlannedEntryRepository _plans;
  final CalorieOverviewRevision _overviewRevision;
  final LastPlannedDay _lastPlannedDay;
  final DateTime Function() _clock;

  /// Whether food logged at [loggedAt] becomes a plan: its day lies after
  /// today.
  bool plansOn(DateTime loggedAt) =>
      DiaryDayStatus.of(day: loggedAt, today: _clock()).isFuture;

  /// Saves the new [plan] and lets the diary open its day.
  Future<void> plan(CalorieEntry plan) async {
    await savePlans([plan]);
    _lastPlannedDay.planned(plan.loggedAt);
  }

  /// Saves [plans] together, for example again after their delete. When one
  /// fails, the ones saved before it are deleted again and the error is
  /// rethrown.
  Future<void> savePlans(List<CalorieEntry> plans) async {
    final written = <CalorieEntry>[];
    try {
      for (final plan in plans) {
        await _plans.savePlannedEntry(plan);
        written.add(plan);
      }
    } on Object {
      // Plans saved before the failure would stay hidden without undo.
      for (final plan in written) {
        await _plans.deletePlannedEntry(plan.id);
      }
      rethrow;
    }
    _overviewRevision.markChanged();
  }

  /// Deletes [plans] one after another.
  Future<void> deletePlans(List<CalorieEntry> plans) async {
    for (final plan in plans) {
      await _plans.deletePlannedEntry(plan.id);
    }
    _overviewRevision.markChanged();
  }
}
