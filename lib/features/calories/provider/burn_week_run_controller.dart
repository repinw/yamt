import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'burn_week_run_controller.g.dart';

const int _maxWeekSyncAdvances = 1000;

/// Real Burn Week run controller.
@riverpod
class BurnWeekRunController extends _$BurnWeekRunController {
  int _saveGeneration = 0;

  BurnWeekRunStateRepository get _repository {
    return ref.read(burnWeekRunStateRepositoryProvider);
  }

  @override
  Future<BurnWeekRunState> build() {
    ref.keepAlive();
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
    final currentDayKey = diaryDayKey(normalizeDiaryDay(currentDay));
    final normalizedWeekStartDate = normalizeDiaryDay(weekStartDate);
    final weekStartDayKey = diaryDayKey(normalizedWeekStartDate);
    final currentWeekStartDayKey = _normalizeBurnWeekDayKey(
      current.currentWeekStartDayKey,
    );
    final currentWeekStartDate = _parseBurnWeekDayKey(currentWeekStartDayKey);
    final closedWeekCount = missedTrackingForClosedWeeks?.length ?? 0;
    var next = current;

    if (currentWeekStartDayKey == null) {
      if (closedWeekCount == 0) {
        next = current.copyWith(
          currentWeekStartDayKey: weekStartDayKey,
        );
      } else {
        next = current.copyWith(
          currentWeekStartDayKey: diaryDayKey(
            normalizedWeekStartDate.subtract(
              Duration(days: burnWeekDaysPerWeek * closedWeekCount),
            ),
          ),
        );
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
      next = current.copyWith(
        currentWeekStartDayKey: diaryDayKey(
          normalizedWeekStartDate.subtract(
            Duration(days: burnWeekDaysPerWeek * closedWeekCount),
          ),
        ),
      );
      next = _advanceToSyncedWeek(
        current: next,
        weekStartDayKey: weekStartDayKey,
        normalizedWeekStartDate: normalizedWeekStartDate,
        missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
      );
    } else if (currentWeekStartDate != null &&
        currentWeekStartDate.isAfter(normalizedWeekStartDate)) {
      next = current.copyWith(
        currentWeekStartDayKey: weekStartDayKey,
      );
    } else if (currentWeekStartDayKey != weekStartDayKey) {
      next = current;
      if (current.currentWeekStartDayKey != currentWeekStartDayKey) {
        next = next.copyWith(
          currentWeekStartDayKey: currentWeekStartDayKey,
        );
      }
      next = _advanceToSyncedWeek(
        current: next,
        weekStartDayKey: weekStartDayKey,
        normalizedWeekStartDate: normalizedWeekStartDate,
        missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
      );
    } else if (current.currentWeekStartDayKey != weekStartDayKey) {
      next = current.copyWith(
        currentWeekStartDayKey: weekStartDayKey,
      );
    }

    if (next.missedTrackingThisWeek != missedTrackingThisWeek) {
      next = next.copyWith(
        missedTrackingThisWeek: missedTrackingThisWeek,
      );
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
      final currentLoopWeekStartDate = _parseBurnWeekDayKey(
        _normalizeBurnWeekDayKey(next.currentWeekStartDayKey),
      );
      if (currentLoopWeekStartDate == null ||
          !currentLoopWeekStartDate.isBefore(normalizedWeekStartDate) ||
          advancedWeekCount >= _maxWeekSyncAdvances) {
        return next.copyWith(
          currentWeekStartDayKey: weekStartDayKey,
        );
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

  /// Resets whole Burn Week run back to fresh state.
  Future<void> resetRun() {
    final current = state.asData?.value;
    return _save(
      const BurnWeekRunState.initial().copyWith(
        heartDayKeys: current?.heartDayKeys,
        heartStarBreakDayKeys: current?.heartStarBreakDayKeys,
      ),
      previous: current,
    );
  }

  /// Restarts Burn Week run from given fresh day.
  Future<void> restartRunFrom({
    required DateTime weekStartDate,
    int? runWeekNumber,
  }) async {
    final current = await future;
    final resolvedRunWeekNumber =
        runWeekNumber ?? _resolveFreshRunWeekNumber(current);
    return _save(
      const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(weekStartDate),
        runWeekNumber: resolvedRunWeekNumber,
        heartDayKeys: current.heartDayKeys,
        heartStarBreakDayKeys: current.heartStarBreakDayKeys,
      ),
      previous: current,
    );
  }

  /// Bootstraps Burn Week run from given day with onboarding placement.
  Future<void> bootstrapRunFrom({
    required DateTime weekStartDate,
    required double heartCreditKcal,
    int runWeekNumber = burnWeekLearningRunWeekNumber,
  }) async {
    final current = await future;
    return _save(
      const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(weekStartDate),
        runWeekNumber: runWeekNumber,
        heartCreditKcal: heartCreditKcal,
        heartDayKeys: current.heartDayKeys,
        heartStarBreakDayKeys: current.heartStarBreakDayKeys,
      ),
      previous: current,
    );
  }

  /// Uses one heart to protect today as a heart day.
  Future<void> usePositiveHeart(double dailyGoalKcal) {
    return useHeartForDay(DateTime.now());
  }

  /// Uses one heart to protect [day] from Burn Week and learning math.
  Future<void> useHeartForDay(DateTime day) async {
    final current = await future;
    final normalizedDay = normalizeDiaryDay(day);
    if (!current.canUseHeartForDay(normalizedDay)) {
      return;
    }
    final dayKey = diaryDayKey(normalizedDay);
    final spendResult = resolveBurnWeekHeartSpend(
      starCount: current.starCount,
      heartCount: current.heartCount,
      heartCreditKcal: current.heartCreditKcal,
      kcalDelta: 0,
    );
    if (spendResult.heartCount == current.heartCount &&
        !spendResult.didBreakStar &&
        !spendResult.didResetRun &&
        spendResult.heartCreditKcal == current.heartCreditKcal) {
      return;
    }
    if (spendResult.didResetRun) {
      await restartRunFrom(weekStartDate: normalizeDiaryDay(DateTime.now()));
      return;
    }
    await _save(
      current.copyWith(
        starCount: spendResult.starCount,
        heartCount: spendResult.heartCount,
        heartCreditKcal: spendResult.heartCreditKcal,
        starBrokeThisWeek:
            current.starBrokeThisWeek || spendResult.didBreakStar,
        heartDayKeys: _addHeartDayKey(current.heartDayKeys, dayKey),
        heartStarBreakDayKeys: spendResult.didBreakStar
            ? _addHeartDayKey(current.heartStarBreakDayKeys, dayKey)
            : current.heartStarBreakDayKeys,
      ),
      previous: current,
    );
    if (ref.mounted) {
      await ref
          .read(calorieGoalControllerProvider.notifier)
          .invalidateWeeklyCheckInSnapshotsFromDay(normalizedDay);
    }
  }

  /// Removes heart-day protection and refunds one heart.
  Future<void> unmarkHeartDay(DateTime day) async {
    final current = await future;
    if (!current.canUnmarkHeartDay(day)) {
      return;
    }
    final dayKey = diaryDayKey(normalizeDiaryDay(day));
    final didBreakStar = current.heartStarBreakDayKeys.contains(dayKey);
    final nextStarBreakDayKeys = _removeHeartDayKey(
      current.heartStarBreakDayKeys,
      dayKey,
    );
    await _save(
      current.copyWith(
        starCount: current.starCount + (didBreakStar ? 1 : 0),
        heartCount: current.heartCount + 1,
        starBrokeThisWeek: didBreakStar
            ? current.runLimitWarningThisWeek || nextStarBreakDayKeys.isNotEmpty
            : current.starBrokeThisWeek,
        heartDayKeys: _removeHeartDayKey(current.heartDayKeys, dayKey),
        heartStarBreakDayKeys: nextStarBreakDayKeys,
      ),
      previous: current,
    );
    if (ref.mounted) {
      await ref
          .read(calorieGoalControllerProvider.notifier)
          .invalidateWeeklyCheckInSnapshotsFromDay(normalizeDiaryDay(day));
    }
  }

  /// Keeps current run alive after an unrecoverable limit warning.
  Future<void> continueRunAfterLimitWarning() async {
    final current = await future;
    if (current.starBrokeThisWeek) {
      return;
    }
    await _save(
      current.copyWith(
        starBrokeThisWeek: true,
        runLimitWarningThisWeek: true,
      ),
      previous: current,
    );
  }

  /// Refills hearts after the user completes a weekly check-in.
  Future<void> refillHeartsForWeeklyCheckIn() async {
    final current = await future;
    final minimumHearts = resolveBurnWeekMockDifficulty(
      current.starCount,
    ).minimumHearts;
    final nextHeartCount = math.max(current.heartCount, minimumHearts);
    if (nextHeartCount == current.heartCount) {
      return;
    }
    await _save(
      current.copyWith(heartCount: nextHeartCount),
      previous: current,
    );
  }

  int _resolveFreshRunWeekNumber(BurnWeekRunState current) {
    if (current.runWeekNumber > burnWeekLearningRunWeekNumber) {
      return burnWeekFirstGameRunWeekNumber;
    }
    return burnWeekLearningRunWeekNumber;
  }

  BurnWeekRunState _advanceToNextWeek({
    required BurnWeekRunState current,
    required String nextWeekStartDayKey,
  }) {
    final earnedStar = resolveBurnWeekEarnedStar(
      heartCount: current.heartCount,
      starBrokeThisWeek: current.starBrokeThisWeek,
      missedTrackingThisWeek: current.missedTrackingThisWeek,
    );
    final nextStarCount = current.starCount + (earnedStar ? 1 : 0);
    return current.copyWith(
      currentWeekStartDayKey: nextWeekStartDayKey,
      runWeekNumber: current.runWeekNumber + 1,
      starCount: nextStarCount,
      heartCount: current.heartCount,
      heartCreditKcal: 0,
      starBrokeThisWeek: false,
      missedTrackingThisWeek: false,
      heartDayKeys: current.heartDayKeys,
      heartStarBreakDayKeys: current.heartStarBreakDayKeys,
      runLimitWarningThisWeek: false,
    );
  }

  String _resolveNextWeekStartDayKey(String currentWeekStartDayKey) {
    final currentWeekStartDate = _parseBurnWeekDayKey(currentWeekStartDayKey);
    if (currentWeekStartDate == null) {
      return currentWeekStartDayKey;
    }
    return diaryDayKey(
      currentWeekStartDate.add(
        const Duration(days: burnWeekDaysPerWeek),
      ),
    );
  }

  Future<void> _save(
    BurnWeekRunState next, {
    BurnWeekRunState? previous,
  }) async {
    final previousState = previous ?? state.asData?.value;
    final saveGeneration = ++_saveGeneration;
    if (ref.mounted) {
      state = AsyncValue<BurnWeekRunState>.data(next);
    }
    final didSave = await _repository.saveState(next);
    if (!ref.mounted) {
      return;
    }
    if (!didSave &&
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
        left.heartCount == right.heartCount &&
        left.heartCreditKcal == right.heartCreditKcal &&
        left.starBrokeThisWeek == right.starBrokeThisWeek &&
        left.missedTrackingThisWeek == right.missedTrackingThisWeek &&
        left.runLimitWarningThisWeek == right.runLimitWarningThisWeek &&
        _sameStringList(left.heartDayKeys, right.heartDayKeys) &&
        _sameStringList(
          left.heartStarBreakDayKeys,
          right.heartStarBreakDayKeys,
        );
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
        current.heartCount == burnWeekInitialHeartCount &&
        current.heartCreditKcal == 0 &&
        !current.starBrokeThisWeek;
  }
}

String? _normalizeBurnWeekDayKey(String? dayKey) {
  final parsedDayKey = _parseBurnWeekDayKey(dayKey);
  if (parsedDayKey == null) {
    return null;
  }
  return diaryDayKey(parsedDayKey);
}

DateTime? _parseBurnWeekDayKey(String? dayKey) {
  final normalizedDayKey = dayKey?.trim();
  if (normalizedDayKey == null || normalizedDayKey.isEmpty) {
    return null;
  }
  final parts = normalizedDayKey.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return normalizeDiaryDay(DateTime(year, month, day));
}

List<String> _addHeartDayKey(List<String> current, String dayKey) {
  final next = <String>{...current, dayKey}.toList()..sort();
  return List<String>.unmodifiable(next);
}

List<String> _removeHeartDayKey(List<String> current, String dayKey) {
  final next = current.where((key) => key != dayKey).toList();
  return List<String>.unmodifiable(next);
}

bool _sameStringList(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
