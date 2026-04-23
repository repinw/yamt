import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';

const int _maxWeekSyncAdvances = 1000;

/// Real Burn Week run controller.
class BurnWeekRunController extends AsyncNotifier<BurnWeekRunState> {
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
    final currentDayKey = diaryDayKey(normalizeDiaryDay(currentDay));
    final normalizedWeekStartDate = normalizeDiaryDay(weekStartDate);
    final weekStartDayKey = diaryDayKey(normalizedWeekStartDate);
    final currentWeekStartDayKey = _normalizeBurnWeekDayKey(
      current.currentWeekStartDayKey,
    );
    final currentWeekStartDate = _parseBurnWeekDayKey(currentWeekStartDayKey);
    var next = current;

    if (currentWeekStartDayKey == null) {
      next = current.copyWith(
        currentWeekStartDayKey: weekStartDayKey,
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
      var advancedWeekCount = 0;
      while (_normalizeBurnWeekDayKey(next.currentWeekStartDayKey) !=
          weekStartDayKey) {
        final currentLoopWeekStartDate = _parseBurnWeekDayKey(
          _normalizeBurnWeekDayKey(next.currentWeekStartDayKey),
        );
        if (currentLoopWeekStartDate == null ||
            !currentLoopWeekStartDate.isBefore(normalizedWeekStartDate) ||
            advancedWeekCount >= _maxWeekSyncAdvances) {
          next = next.copyWith(
            currentWeekStartDayKey: weekStartDayKey,
          );
          break;
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

  /// Resets whole Burn Week run back to fresh state.
  Future<void> resetRun() {
    return _save(
      const BurnWeekRunState.initial(),
      previous: state.asData?.value,
    );
  }

  /// Restarts Burn Week run from given fresh day.
  Future<void> restartRunFrom({required DateTime weekStartDate}) {
    return _save(
      const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(weekStartDate),
      ),
      previous: state.asData?.value,
    );
  }

  /// Bootstraps Burn Week run from given day with onboarding placement.
  Future<void> bootstrapRunFrom({
    required DateTime weekStartDate,
    required double heartCreditKcal,
  }) {
    return _save(
      const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(weekStartDate),
        heartCreditKcal: heartCreditKcal,
      ),
      previous: state.asData?.value,
    );
  }

  /// Uses one heart to add one daily-goal worth of kcal.
  Future<void> usePositiveHeart(double dailyGoalKcal) {
    return _consumeHeart(kcalDelta: dailyGoalKcal);
  }

  /// Uses one heart to remove one daily-goal worth of kcal.
  Future<void> useNegativeHeart(double dailyGoalKcal) {
    return _consumeHeart(kcalDelta: -dailyGoalKcal);
  }

  Future<void> _consumeHeart({required double kcalDelta}) async {
    final current = await future;
    final spendResult = resolveBurnWeekHeartSpend(
      starCount: current.starCount,
      heartCount: current.heartCount,
      heartCreditKcal: current.heartCreditKcal,
      kcalDelta: kcalDelta,
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
      ),
      previous: current,
    );
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
    final nextHeartCount = math.max(
      current.heartCount,
      resolveBurnWeekMockDifficulty(nextStarCount).minimumHearts,
    );
    return current.copyWith(
      currentWeekStartDayKey: nextWeekStartDayKey,
      runWeekNumber: current.runWeekNumber + 1,
      starCount: nextStarCount,
      heartCount: nextHeartCount,
      heartCreditKcal: 0,
      starBrokeThisWeek: false,
      missedTrackingThisWeek: false,
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
        left.missedTrackingThisWeek == right.missedTrackingThisWeek;
  }
}

/// Burn Week run controller provider.
final burnWeekRunControllerProvider =
    AsyncNotifierProvider<BurnWeekRunController, BurnWeekRunState>(
      BurnWeekRunController.new,
    );

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
