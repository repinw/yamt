import 'dart:developer' show log;
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';

part 'calorie_balance_summary_provider.g.dart';

const _balanceSummaryLogName = 'CalorieBalanceSummaryProvider';

/// Defines calorie balance now typedef.
typedef CalorieBalanceNow = DateTime Function();

/// Defines calorie balance summary data.
class CalorieBalanceSummaryData {
  /// The calorie balance summary data.
  const CalorieBalanceSummaryData({
    required this.selectedDay,
    required this.referenceNow,
    required this.windowStartDate,
    required this.balanceStartDate,
    required this.paceWindowStart,
    required this.paceWindowEnd,
    required this.storedGoalKcal,
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
    this.activityComparisonKcal = 0,
  });

  /// The selected day.
  final DateTime selectedDay;

  /// The reference now.
  final DateTime referenceNow;

  /// The window start date.
  final DateTime windowStartDate;

  /// The balance start date.
  final DateTime balanceStartDate;

  /// The pace window start.
  final DateTime paceWindowStart;

  /// The pace window end.
  final DateTime paceWindowEnd;

  /// The stored goal before today's activity delta.
  final double storedGoalKcal;

  /// The base goal kcal.
  final double baseGoalKcal;

  /// The carryover kcal.
  final double carryoverKcal;

  /// The goal mode.
  final CalorieGoalMode goalMode;

  /// The flexible goal kcal.
  final double flexibleGoalKcal;

  /// The paced goal kcal.
  final double pacedGoalKcal;

  /// The consumed kcal.
  final double consumedKcal;

  /// The delta kcal.
  final double deltaKcal;

  /// The pace ratio.
  final double paceRatio;

  /// The dead zone kcal.
  final double deadZoneKcal;

  /// The range kcal.
  final double rangeKcal;

  /// The activity delta kcal.
  final double activityDeltaKcal;

  /// The signed activity comparison against the learned baseline.
  final double activityComparisonKcal;

  /// The used learned tdee.
  final bool usedLearnedTdee;

  /// Whether current day.
  bool get isCurrentDay => _isSameDay(selectedDay, referenceNow);

  /// The uncapped flexible goal kcal.
  double get uncappedFlexibleGoalKcal => baseGoalKcal + carryoverKcal;

  /// The recommends fasting today.
  bool get recommendsFastingToday =>
      isCurrentDay && uncappedFlexibleGoalKcal <= 0;

  /// The recommends fasting rest of day.
  bool get recommendsFastingRestOfDay =>
      isCurrentDay &&
      !recommendsFastingToday &&
      flexibleGoalKcal > 0 &&
      consumedKcal >= flexibleGoalKcal;

  /// Whether within dead zone.
  bool get isWithinDeadZone => deltaKcal.abs() <= deadZoneKcal;

  /// Whether under pace.
  bool get isUnderPace => deltaKcal < -deadZoneKcal;

  /// Whether over pace.
  bool get isOverPace => deltaKcal > deadZoneKcal;

  /// The bar progress.
  double get barProgress => (deltaKcal.abs() / rangeKcal).clamp(0.0, 1.0);
}

/// Calorie balance now.
@Riverpod(keepAlive: true)
CalorieBalanceNow calorieBalanceNow(Ref ref) {
  return DateTime.now;
}

/// Calorie balance summary.
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
  final balanceStartDate = resolveCalorieBalanceCycleStartDate(
    settings: settings,
    day: selectedDay,
    fallbackStartDate: windowStartDate,
  );
  final historyEntries = await _readHistoryEntriesSafely(
    startInclusive: balanceStartDate,
    endExclusive: selectedDay,
    repository: repository,
  );
  final historyEntriesByDay = historyEntries.groupByDiaryDayKey();
  final carryoverDays = _resolveBaseCarryoverDays(
    settings: settings,
    startInclusive: balanceStartDate,
    endExclusive: selectedDay,
    entriesByDay: historyEntriesByDay,
  );

  final goalEntry = settings.goalEntryForDay(selectedDay);
  if (!ref.mounted) {
    throw StateError('Calorie balance summary disposed.');
  }
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
  final baseGoalKcal = dailyBaseGoalKcal;
  final goalMode =
      goalEntry?.calculatorProfile?.goalMode ??
      settings.calculatorProfile?.goalMode ??
      CalorieGoalMode.maintain;
  final carryoverKcal = CalorieBudgetCalculator.calculateCarryover(
    carryoverDays,
  );
  final flexibleGoalKcal = math.max<double>(0, baseGoalKcal + carryoverKcal);
  final defaultPaceWindowStart = settings.eatingWindowStartForDay(selectedDay);
  final defaultPaceWindowEnd = settings.eatingWindowEndForDay(selectedDay);
  final resolvedPaceWindowStart = _resolvePaceWindowStart(
    selectedDay: selectedDay,
    now: now,
    defaultPaceWindowStart: defaultPaceWindowStart,
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
  final referenceGoalKcal = math.max(baseGoalKcal, flexibleGoalKcal);
  final deadZoneKcal = math.max<double>(60, referenceGoalKcal * 0.04);
  final rangeKcal = math.max<double>(400, referenceGoalKcal * 0.4);

  return CalorieBalanceSummaryData(
    selectedDay: selectedDay,
    referenceNow: now,
    windowStartDate: windowStartDate,
    balanceStartDate: balanceStartDate,
    paceWindowStart: resolvedPaceWindowStart,
    paceWindowEnd: defaultPaceWindowEnd,
    storedGoalKcal: resolvedGoal.storedGoalKcal,
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
    activityComparisonKcal: resolvedGoal.activityComparisonKcal,
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
  } on Object catch (error, stackTrace) {
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
    return 1;
  }

  if (!paceWindowStart.isBefore(paceWindowEnd)) {
    return 0;
  }
  if (!now.isAfter(paceWindowStart)) {
    return 0;
  }
  if (!now.isBefore(paceWindowEnd)) {
    return 1;
  }

  final elapsedSeconds = now.difference(paceWindowStart).inSeconds;
  final paceWindowSeconds = paceWindowEnd.difference(paceWindowStart).inSeconds;
  return (elapsedSeconds / paceWindowSeconds).clamp(0.0, 1.0);
}

DateTime _resolvePaceWindowStart({
  required DateTime selectedDay,
  required DateTime now,
  required DateTime defaultPaceWindowStart,
}) {
  if (_isSameDay(selectedDay, now)) {
    return defaultPaceWindowStart;
  }
  return defaultPaceWindowStart;
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

bool _isSameDay(DateTime left, DateTime right) {
  final normalizedLeft = normalizeDiaryDay(left);
  final normalizedRight = normalizeDiaryDay(right);
  return normalizedLeft == normalizedRight;
}

/// Resolve calorie balance score.
double resolveCalorieBalanceScore(CalorieBalanceSummaryData data) {
  if (!data.isUnderPace && !data.isOverPace) {
    return 1;
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

/// Resolve calorie balance center score.
double resolveCalorieBalanceCenterScore(CalorieBalanceSummaryData data) {
  return switch (data.goalMode) {
    CalorieGoalMode.maintain => 1.0,
    CalorieGoalMode.lose || CalorieGoalMode.gain => 0.55,
  };
}

/// Resolve calorie balance recovery time.
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

List<CalorieCarryoverDay> _resolveBaseCarryoverDays({
  required CalorieGoalSettings settings,
  required DateTime startInclusive,
  required DateTime endExclusive,
  required Map<String, List<CalorieEntry>> entriesByDay,
}) {
  if (!startInclusive.isBefore(endExclusive)) {
    return const <CalorieCarryoverDay>[];
  }

  final carryoverDays = <CalorieCarryoverDay>[];
  for (
    var day = normalizeDiaryDay(startInclusive);
    day.isBefore(normalizeDiaryDay(endExclusive));
    day = nextDiaryDay(day)
  ) {
    final dayEntries = entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    final consumedKcal = dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    carryoverDays.add(
      CalorieCarryoverDay(
        goalKcal: settings.goalKcalForDay(day),
        consumedKcal: consumedKcal,
      ),
    );
  }
  return carryoverDays;
}
