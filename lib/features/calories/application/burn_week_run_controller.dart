import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/burn_week_live_window_logic.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

part 'burn_week_run_controller.g.dart';

const int _maxWeekSyncAdvances = 1000;

/// Real Burn Week run controller.
@Riverpod(keepAlive: true)
class BurnWeekRunController extends _$BurnWeekRunController {
  int _saveGeneration = 0;

  BurnWeekRunStateRepository get _repository {
    return ref.read(burnWeekRunStateRepositoryProvider);
  }

  @override
  Future<BurnWeekRunState> build() {
    final repository = ref.watch(burnWeekRunStateRepositoryProvider);
    return repository.readState();
  }

  /// Syncs persistent run state to current real week.
  Future<void> syncForWeek({
    required DateTime currentDay,
    required DateTime weekStartDate,
    required bool missedTrackingThisWeek,
    List<bool>? missedTrackingForClosedWeeks,
  }) async {
    final current = await future;
    final currentDayKey = localDayKey(normalizeLocalDay(currentDay));
    final normalizedWeekStartDate = normalizeLocalDay(weekStartDate);
    final weekStartDayKey = localDayKey(normalizedWeekStartDate);
    final currentWeekStartDayKey = _normalizeBurnWeekDayKey(
      current.currentWeekStartDayKey,
    );
    final currentWeekStartDate = tryParseBurnWeekDayKey(currentWeekStartDayKey);
    final closedWeekCount = missedTrackingForClosedWeeks?.length ?? 0;
    final firstClosedWeekKey = localDayKey(
      addLocalDays(
        normalizedWeekStartDate,
        -burnWeekDaysPerWeek * closedWeekCount,
      ),
    );
    var next = current;

    if (currentWeekStartDayKey == null) {
      if (closedWeekCount == 0) {
        next = current.copyWith(currentWeekStartDayKey: weekStartDayKey);
      } else {
        next = current.copyWith(currentWeekStartDayKey: firstClosedWeekKey);
        next = _advanceToSyncedWeek(
          current: next,
          weekStartDayKey: weekStartDayKey,
          normalizedWeekStartDate: normalizedWeekStartDate,
          missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
        );
      }
    } else if (_shouldReplayBackfilledClosedWeeks(
      current: current,
      currentWeekStartDayKey: currentWeekStartDayKey,
      weekStartDayKey: weekStartDayKey,
      closedWeekCount: closedWeekCount,
    )) {
      next = current.copyWith(currentWeekStartDayKey: firstClosedWeekKey);
      next = _advanceToSyncedWeek(
        current: next,
        weekStartDayKey: weekStartDayKey,
        normalizedWeekStartDate: normalizedWeekStartDate,
        missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
      );
    } else if (currentWeekStartDate != null &&
        currentWeekStartDate.isAfter(normalizedWeekStartDate)) {
      next = current.copyWith(currentWeekStartDayKey: weekStartDayKey);
    } else if (currentWeekStartDayKey != weekStartDayKey) {
      next = current;
      if (current.currentWeekStartDayKey != currentWeekStartDayKey) {
        next = next.copyWith(currentWeekStartDayKey: currentWeekStartDayKey);
      }
      next = _advanceToSyncedWeek(
        current: next,
        weekStartDayKey: weekStartDayKey,
        normalizedWeekStartDate: normalizedWeekStartDate,
        missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
      );
    } else if (current.currentWeekStartDayKey != weekStartDayKey) {
      next = current.copyWith(currentWeekStartDayKey: weekStartDayKey);
    }

    if (next.missedTrackingThisWeek != missedTrackingThisWeek) {
      next = next.copyWith(missedTrackingThisWeek: missedTrackingThisWeek);
    }
    if (next.lastActiveDayKey != currentDayKey) {
      next = next.copyWith(lastActiveDayKey: currentDayKey);
    }

    if (_isSameState(current, next)) {
      return;
    }
    await _save(next, previous: current);
  }

  BurnWeekRunState _advanceToSyncedWeek({
    required BurnWeekRunState current,
    required String weekStartDayKey,
    required DateTime normalizedWeekStartDate,
    required List<bool>? missedTrackingForClosedWeeks,
  }) {
    var next = current;
    var advancedWeekCount = 0;
    while (_normalizeBurnWeekDayKey(next.currentWeekStartDayKey) !=
        weekStartDayKey) {
      final currentLoopWeekStartDate = tryParseBurnWeekDayKey(
        _normalizeBurnWeekDayKey(next.currentWeekStartDayKey),
      );
      if (currentLoopWeekStartDate == null ||
          !currentLoopWeekStartDate.isBefore(normalizedWeekStartDate) ||
          advancedWeekCount >= _maxWeekSyncAdvances) {
        return next.copyWith(currentWeekStartDayKey: weekStartDayKey);
      }
      final closingWeekMissedTracking = switch (advancedWeekCount) {
        _
            when missedTrackingForClosedWeeks != null &&
                advancedWeekCount < missedTrackingForClosedWeeks.length =>
          missedTrackingForClosedWeeks[advancedWeekCount],
        _ => true,
      };
      final closingWeekState = next.copyWith(
        missedTrackingThisWeek: closingWeekMissedTracking,
      );
      next = _advanceToNextWeek(
        current: closingWeekState,
        nextWeekStartDayKey: _resolveNextWeekStartDayKey(
          _normalizeBurnWeekDayKey(next.currentWeekStartDayKey)!,
        ),
      );
      advancedWeekCount += 1;
    }
    return next;
  }

  /// Moves the current week to start on [weekStartDate], without closing it.
  Future<bool> moveWeekStartTo(DateTime weekStartDate) async {
    final current = await future;
    final weekStartDayKey = localDayKey(normalizeLocalDay(weekStartDate));
    final next = current.copyWith(currentWeekStartDayKey: weekStartDayKey);
    return await _save(next, previous: current);
  }

  /// Resets whole Burn Week run back to fresh state.
  Future<void> resetRun() {
    final current = state.asData?.value;
    return _save(const BurnWeekRunState.initial(), previous: current);
  }

  /// Restarts the run from [weekStartDate]; returns whether it was stored.
  Future<bool> restartRunFrom({
    required DateTime weekStartDate,
    int? runWeekNumber,
  }) async {
    final current = await future;
    return await _save(
      const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: localDayKey(weekStartDate),
        runWeekNumber: runWeekNumber ?? burnWeekLearningRunWeekNumber,
      ),
      previous: current,
    );
  }

  /// Like [restartRunFrom], but logs a throwing save and returns `false`.
  Future<bool> tryRestartRunFrom({
    required DateTime weekStartDate,
    int? runWeekNumber,
  }) async {
    try {
      return await restartRunFrom(
        weekStartDate: weekStartDate,
        runWeekNumber: runWeekNumber,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Could not restart the Burn Week run.',
        name: 'BurnWeekRunController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Bootstraps Burn Week run from given day with onboarding placement.
  Future<void> bootstrapRunFrom({
    required DateTime weekStartDate,
    int runWeekNumber = burnWeekLearningRunWeekNumber,
  }) async {
    final current = await future;
    await _save(
      const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: localDayKey(weekStartDate),
        runWeekNumber: runWeekNumber,
      ),
      previous: current,
    );
  }

  BurnWeekRunState _advanceToNextWeek({
    required BurnWeekRunState current,
    required String nextWeekStartDayKey,
  }) {
    // A week earns a star when no star broke and no day went untracked.
    final earnedStar =
        !current.starBrokeThisWeek && !current.missedTrackingThisWeek;
    final nextStarCount = current.starCount + (earnedStar ? 1 : 0);
    return current.copyWith(
      currentWeekStartDayKey: nextWeekStartDayKey,
      runWeekNumber: current.runWeekNumber + 1,
      starCount: nextStarCount,
      starBrokeThisWeek: false,
      missedTrackingThisWeek: false,
      runLimitWarningThisWeek: false,
    );
  }

  String _resolveNextWeekStartDayKey(String currentWeekStartDayKey) {
    final currentWeekStartDate = tryParseBurnWeekDayKey(currentWeekStartDayKey);
    if (currentWeekStartDate == null) {
      return currentWeekStartDayKey;
    }
    return localDayKey(addLocalDays(currentWeekStartDate, burnWeekDaysPerWeek));
  }

  /// Shows and stores [next]; a failed or throwing save restores the run.
  Future<bool> _save(
    BurnWeekRunState next, {
    BurnWeekRunState? previous,
  }) async {
    final previousState = previous ?? state.asData?.value;
    final saveGeneration = ++_saveGeneration;
    if (ref.mounted) {
      state = AsyncValue<BurnWeekRunState>.data(next);
    }
    try {
      if (await _repository.saveState(next)) {
        return true;
      }
    } on Object {
      _restore(previousState, saveGeneration);
      rethrow;
    }
    _restore(previousState, saveGeneration);
    return false;
  }

  /// Puts [previousState] back unless a later save replaced the state.
  void _restore(BurnWeekRunState? previousState, int saveGeneration) {
    if (ref.mounted &&
        saveGeneration == _saveGeneration &&
        previousState != null) {
      state = AsyncValue<BurnWeekRunState>.data(previousState);
    }
  }

  bool _isSameState(BurnWeekRunState left, BurnWeekRunState right) {
    return left.currentWeekStartDayKey == right.currentWeekStartDayKey &&
        left.lastActiveDayKey == right.lastActiveDayKey &&
        left.runWeekNumber == right.runWeekNumber &&
        left.starCount == right.starCount &&
        left.starBrokeThisWeek == right.starBrokeThisWeek &&
        left.missedTrackingThisWeek == right.missedTrackingThisWeek &&
        left.runLimitWarningThisWeek == right.runLimitWarningThisWeek;
  }

  bool _shouldReplayBackfilledClosedWeeks({
    required BurnWeekRunState current,
    required String? currentWeekStartDayKey,
    required String weekStartDayKey,
    required int closedWeekCount,
  }) {
    return closedWeekCount > 0 &&
        currentWeekStartDayKey == weekStartDayKey &&
        current.runWeekNumber == burnWeekLearningRunWeekNumber &&
        current.starCount == 0 &&
        !current.starBrokeThisWeek;
  }
}

String? _normalizeBurnWeekDayKey(String? dayKey) {
  final parsedDayKey = tryParseBurnWeekDayKey(dayKey);
  if (parsedDayKey == null) {
    return null;
  }
  return localDayKey(parsedDayKey);
}
