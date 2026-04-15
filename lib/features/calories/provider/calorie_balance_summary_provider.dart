import 'dart:developer' show log;
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';

part 'calorie_balance_summary_provider.g.dart';

const _balanceSummaryLogName = 'CalorieBalanceSummaryProvider';

typedef CalorieBalanceNow = DateTime Function();

class CalorieBalanceSummaryData {
  const CalorieBalanceSummaryData({
    required this.selectedDay,
    required this.referenceNow,
    required this.windowStartDate,
    required this.balanceStartDate,
    required this.paceWindowStart,
    required this.paceWindowEnd,
    required this.baseGoalKcal,
    required this.carryoverKcal,
    required this.goalMode,
    required this.flexibleGoalKcal,
    required this.pacedGoalKcal,
    required this.consumedKcal,
    required this.deltaKcal,
    required this.paceRatio,
    required this.deadZoneKcal,
    required this.rangeKcal,
    required this.activityDeltaKcal,
    required this.usedLearnedTdee,
  });

  final DateTime selectedDay;
  final DateTime referenceNow;
  final DateTime windowStartDate;
  final DateTime balanceStartDate;
  final DateTime paceWindowStart;
  final DateTime paceWindowEnd;
  final double baseGoalKcal;
  final double carryoverKcal;
  final CalorieGoalMode goalMode;
  final double flexibleGoalKcal;
  final double pacedGoalKcal;
  final double consumedKcal;
  final double deltaKcal;
  final double paceRatio;
  final double deadZoneKcal;
  final double rangeKcal;
  final double activityDeltaKcal;
  final bool usedLearnedTdee;

  bool get isCurrentDay => _isSameDay(selectedDay, referenceNow);

  double get uncappedFlexibleGoalKcal => baseGoalKcal + carryoverKcal;

  bool get recommendsFastingToday =>
      isCurrentDay && uncappedFlexibleGoalKcal <= 0;

  bool get recommendsFastingRestOfDay =>
      isCurrentDay &&
      !recommendsFastingToday &&
      flexibleGoalKcal > 0 &&
      consumedKcal >= flexibleGoalKcal;

  bool get isWithinDeadZone => deltaKcal.abs() <= deadZoneKcal;

  bool get isUnderPace => deltaKcal < -deadZoneKcal;

  bool get isOverPace => deltaKcal > deadZoneKcal;

  double get barProgress =>
      (deltaKcal.abs() / rangeKcal).clamp(0.0, 1.0).toDouble();
}

@Riverpod(keepAlive: true)
CalorieBalanceNow calorieBalanceNow(Ref ref) {
  return DateTime.now;
}

@riverpod
Future<CalorieBalanceSummaryData> calorieBalanceSummary(Ref ref) async {
  final now = ref.watch(calorieBalanceNowProvider)().toLocal();
  final selectedDay = ref.watch(calorieDayControllerProvider);
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  final selectedEntries = await ref.watch(
    calorieEntriesControllerProvider.future,
  );
  final repository = ref.watch(calorieLogRepositoryProvider);

  final windowDays = buildDiaryVisibleDays(anchorDay: selectedDay);
  final windowStartDate = windowDays.first;
  final balanceStartDate = settings.balanceStartForWindow(windowDays);
  final relevantHistoryStart = _laterDay(windowStartDate, balanceStartDate);
  final historyEntries = await _readHistoryEntriesSafely(
    startInclusive: windowStartDate,
    endExclusive: selectedDay,
    repository: repository,
  );

  final historyConsumedKcal = historyEntries.fold<double>(0, (sum, entry) {
    final loggedDay = normalizeDiaryDay(entry.loggedAt);
    if (_isBeforeDay(loggedDay, relevantHistoryStart)) {
      return sum;
    }
    return sum + entry.totalKcal;
  });
  final historyGoalKcal = windowDays
      .where((day) {
        return !_isBeforeDay(day, relevantHistoryStart) &&
            _isBeforeDay(day, selectedDay);
      })
      .fold<double>(0, (sum, day) => sum + settings.goalKcalForDay(day));

  final goalEntry = settings.goalEntryForDay(selectedDay);
  final resolvedGoal = await ref.watch(
    resolvedCalorieGoalForDayProvider(selectedDay).future,
  );
  final dailyBaseGoalKcal = resolvedGoal.goalKcal;
  final hasFutureGoalStart =
      settings.nextGoalStartAfterDay(selectedDay) != null;
  final shouldIgnoreSelectedDayForBalance =
      goalEntry?.hasGoal != true &&
      (goalEntry != null || hasFutureGoalStart) &&
      dailyBaseGoalKcal <= 0;
  final consumedKcal = shouldIgnoreSelectedDayForBalance
      ? 0.0
      : selectedEntries.fold<double>(0, (sum, entry) => sum + entry.totalKcal);
  final initialGoalPacing = _resolveInitialGoalPacing(
    settings: settings,
    selectedDay: selectedDay,
    now: now,
    selectedEntries: selectedEntries,
    dailyBaseGoalKcal: dailyBaseGoalKcal,
  );
  final baseGoalKcal =
      initialGoalPacing?.adjustedBaseGoalKcal ?? dailyBaseGoalKcal;
  final goalMode =
      goalEntry?.calculatorProfile?.goalMode ??
      settings.calculatorProfile?.goalMode ??
      CalorieGoalMode.maintain;
  final carryoverKcal = historyGoalKcal - historyConsumedKcal;
  final flexibleGoalKcal = math
      .max(0.0, baseGoalKcal + carryoverKcal)
      .toDouble();
  final defaultPaceWindowStart = settings.eatingWindowStartForDay(selectedDay);
  final defaultPaceWindowEnd = settings.eatingWindowEndForDay(selectedDay);
  final resolvedPaceWindowStart = _resolvePaceWindowStart(
    selectedDay: selectedDay,
    now: now,
    defaultPaceWindowStart: defaultPaceWindowStart,
    customPaceWindowStart: initialGoalPacing?.paceWindowStart,
  );
  final paceRatio = _paceRatioForDay(
    selectedDay: selectedDay,
    now: now,
    paceWindowStart: resolvedPaceWindowStart,
    paceWindowEnd: defaultPaceWindowEnd,
  );
  final pacedGoalKcal = _resolvePacedGoalKcal(
    selectedDay: selectedDay,
    now: now,
    baseGoalKcal: baseGoalKcal,
    carryoverKcal: carryoverKcal,
    flexibleGoalKcal: flexibleGoalKcal,
    paceRatio: paceRatio,
  );
  final deltaKcal = consumedKcal - pacedGoalKcal;
  final referenceGoalKcal = math.max(baseGoalKcal, flexibleGoalKcal).toDouble();
  final deadZoneKcal = math.max(60.0, referenceGoalKcal * 0.04).toDouble();
  final rangeKcal = math.max(400.0, referenceGoalKcal * 0.4).toDouble();

  return CalorieBalanceSummaryData(
    selectedDay: selectedDay,
    referenceNow: now,
    windowStartDate: windowStartDate,
    balanceStartDate: balanceStartDate,
    paceWindowStart: resolvedPaceWindowStart,
    paceWindowEnd: defaultPaceWindowEnd,
    baseGoalKcal: baseGoalKcal,
    carryoverKcal: carryoverKcal,
    goalMode: goalMode,
    flexibleGoalKcal: flexibleGoalKcal,
    pacedGoalKcal: pacedGoalKcal,
    consumedKcal: consumedKcal,
    deltaKcal: deltaKcal,
    paceRatio: paceRatio,
    deadZoneKcal: deadZoneKcal,
    rangeKcal: rangeKcal,
    activityDeltaKcal: resolvedGoal.activityDeltaKcal,
    usedLearnedTdee: resolvedGoal.usedLearnedTdee,
  );
}

Future<List<CalorieEntry>> _readHistoryEntriesSafely({
  required DateTime startInclusive,
  required DateTime endExclusive,
  required CalorieLogRepositoryContract repository,
}) async {
  if (!startInclusive.isBefore(endExclusive)) {
    return const <CalorieEntry>[];
  }

  try {
    return await repository.readEntriesInRange(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  } catch (error, stackTrace) {
    log(
      'Failed to load historical calorie entries for balance summary.',
      name: _balanceSummaryLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const <CalorieEntry>[];
  }
}

double _paceRatioForDay({
  required DateTime selectedDay,
  required DateTime now,
  required DateTime paceWindowStart,
  required DateTime paceWindowEnd,
}) {
  if (!_isSameDay(selectedDay, now)) {
    return 1.0;
  }

  if (!paceWindowStart.isBefore(paceWindowEnd)) {
    return 0.0;
  }
  if (!now.isAfter(paceWindowStart)) {
    return 0.0;
  }
  if (!now.isBefore(paceWindowEnd)) {
    return 1.0;
  }

  final elapsedSeconds = now.difference(paceWindowStart).inSeconds;
  final paceWindowSeconds = paceWindowEnd.difference(paceWindowStart).inSeconds;
  return (elapsedSeconds / paceWindowSeconds).clamp(0.0, 1.0).toDouble();
}

DateTime _resolvePaceWindowStart({
  required DateTime selectedDay,
  required DateTime now,
  required DateTime defaultPaceWindowStart,
  DateTime? customPaceWindowStart,
}) {
  if (_isSameDay(selectedDay, now)) {
    return customPaceWindowStart ?? defaultPaceWindowStart;
  }
  return defaultPaceWindowStart;
}

_InitialGoalPacing? _resolveInitialGoalPacing({
  required CalorieGoalSettings settings,
  required DateTime selectedDay,
  required DateTime now,
  required List<CalorieEntry> selectedEntries,
  required double dailyBaseGoalKcal,
}) {
  if (!_isSameDay(selectedDay, now)) {
    return null;
  }

  final goalEntry = settings.goalEntryForDay(selectedDay);
  final goalChangedAt = goalEntry?.effectiveChangedAt.toLocal();
  if (goalChangedAt == null || !_isSameDay(goalChangedAt, selectedDay)) {
    return null;
  }

  if (goalEntry?.hasGoal != true) {
    return null;
  }

  final hadGoalBeforeToday = settings.sortedGoalHistory.any((entry) {
    return entry.hasGoal && _isBeforeDay(entry.effectiveDate, selectedDay);
  });
  if (hadGoalBeforeToday) {
    return null;
  }

  final hadEntriesBeforeGoal = selectedEntries.any((entry) {
    return entry.loggedAt.toLocal().isBefore(goalChangedAt);
  });
  if (hadEntriesBeforeGoal) {
    return null;
  }

  final defaultPaceWindowStart = settings.eatingWindowStartForDay(selectedDay);
  final paceWindowStart = goalChangedAt.isAfter(defaultPaceWindowStart)
      ? goalChangedAt
      : defaultPaceWindowStart;
  final paceWindowEnd = settings.eatingWindowEndForDay(selectedDay);
  final defaultWindowSeconds = paceWindowEnd
      .difference(defaultPaceWindowStart)
      .inSeconds;
  if (defaultWindowSeconds <= 0) {
    return _InitialGoalPacing(
      paceWindowStart: paceWindowStart,
      adjustedBaseGoalKcal: dailyBaseGoalKcal,
    );
  }

  final remainingWindowSeconds = paceWindowEnd
      .difference(paceWindowStart)
      .inSeconds;
  final adjustedBaseGoalKcal = remainingWindowSeconds <= 0
      ? 0.0
      : dailyBaseGoalKcal * remainingWindowSeconds / defaultWindowSeconds;
  return _InitialGoalPacing(
    paceWindowStart: paceWindowStart,
    adjustedBaseGoalKcal: adjustedBaseGoalKcal,
  );
}

double _resolvePacedGoalKcal({
  required DateTime selectedDay,
  required DateTime now,
  required double baseGoalKcal,
  required double carryoverKcal,
  required double flexibleGoalKcal,
  required double paceRatio,
}) {
  if (!_isSameDay(selectedDay, now)) {
    return flexibleGoalKcal;
  }

  // For the current day, previous days are already complete and count in full.
  return carryoverKcal + (baseGoalKcal * paceRatio);
}

DateTime _laterDay(DateTime left, DateTime right) {
  return _isBeforeDay(left, right) ? right : left;
}

bool _isBeforeDay(DateTime left, DateTime right) {
  return normalizeDiaryDay(left).isBefore(normalizeDiaryDay(right));
}

bool _isSameDay(DateTime left, DateTime right) {
  final normalizedLeft = normalizeDiaryDay(left);
  final normalizedRight = normalizeDiaryDay(right);
  return normalizedLeft == normalizedRight;
}

double resolveCalorieBalanceScore(CalorieBalanceSummaryData data) {
  if (!data.isUnderPace && !data.isOverPace) {
    return 1.0;
  }

  return switch (data.goalMode) {
    CalorieGoalMode.lose =>
      data.isUnderPace
          ? _positiveScore(data.barProgress)
          : _negativeScore(data.barProgress),
    CalorieGoalMode.gain =>
      data.isOverPace
          ? _positiveScore(data.barProgress)
          : _negativeScore(data.barProgress),
    CalorieGoalMode.maintain => _maintainScore(data.barProgress),
  };
}

double resolveCalorieBalanceCenterScore(CalorieBalanceSummaryData data) {
  return switch (data.goalMode) {
    CalorieGoalMode.maintain => 1.0,
    CalorieGoalMode.lose || CalorieGoalMode.gain => 0.55,
  };
}

DateTime? resolveCalorieBalanceRecoveryTime(CalorieBalanceSummaryData data) {
  if (!data.isCurrentDay || !data.isOverPace || data.baseGoalKcal <= 0) {
    return null;
  }

  final paceWindowStart = data.paceWindowStart;
  final paceWindowEnd = data.paceWindowEnd;
  final requiredPacedGoalKcal = data.consumedKcal - data.deadZoneKcal;
  final requiredRatio =
      (requiredPacedGoalKcal - data.carryoverKcal) / data.baseGoalKcal;

  if (requiredRatio <= data.paceRatio) {
    return data.referenceNow;
  }
  if (requiredRatio > 1.0 || !data.referenceNow.isBefore(paceWindowEnd)) {
    return null;
  }

  final paceWindowDuration = paceWindowEnd.difference(paceWindowStart);
  final recoveryMilliseconds =
      (paceWindowDuration.inMilliseconds * requiredRatio).round();
  return paceWindowStart.add(Duration(milliseconds: recoveryMilliseconds));
}

double _positiveScore(double progress) {
  return (0.72 + (progress * 0.28)).clamp(0.0, 1.0);
}

double _negativeScore(double progress) {
  return (0.5 - (progress * 0.5)).clamp(0.0, 1.0);
}

double _maintainScore(double progress) {
  return (1.0 - progress).clamp(0.0, 1.0);
}

class _InitialGoalPacing {
  const _InitialGoalPacing({
    required this.paceWindowStart,
    required this.adjustedBaseGoalKcal,
  });

  final DateTime paceWindowStart;
  final double adjustedBaseGoalKcal;
}
