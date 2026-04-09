import 'dart:developer' show log;
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_balance_summary_provider.g.dart';

const _balanceSummaryLogName = 'CalorieBalanceSummaryProvider';

typedef CalorieBalanceNow = DateTime Function();

class CalorieBalanceSummaryData {
  const CalorieBalanceSummaryData({
    required this.selectedDay,
    required this.referenceNow,
    required this.windowStartDate,
    required this.balanceStartDate,
    required this.baseGoalKcal,
    required this.carryoverKcal,
    required this.flexibleGoalKcal,
    required this.pacedGoalKcal,
    required this.consumedKcal,
    required this.deltaKcal,
    required this.paceRatio,
    required this.deadZoneKcal,
    required this.rangeKcal,
  });

  final DateTime selectedDay;
  final DateTime referenceNow;
  final DateTime windowStartDate;
  final DateTime balanceStartDate;
  final double baseGoalKcal;
  final double carryoverKcal;
  final double flexibleGoalKcal;
  final double pacedGoalKcal;
  final double consumedKcal;
  final double deltaKcal;
  final double paceRatio;
  final double deadZoneKcal;
  final double rangeKcal;

  bool get isCurrentDay => _isSameDay(selectedDay, referenceNow);

  bool get isWithinDeadZone => deltaKcal.abs() <= deadZoneKcal;

  bool get isUnderPace => deltaKcal < -deadZoneKcal;

  bool get isOverPace => deltaKcal > deadZoneKcal;

  double get barProgress {
    if (rangeKcal <= 0) {
      return 0;
    }
    return (deltaKcal.abs() / rangeKcal).clamp(0.0, 1.0).toDouble();
  }
}

@Riverpod(keepAlive: true)
CalorieBalanceNow calorieBalanceNow(Ref ref) {
  return DateTime.now;
}

@riverpod
Future<CalorieBalanceSummaryData> calorieBalanceSummary(Ref ref) async {
  final now = ref.watch(calorieBalanceNowProvider)();
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

  final consumedKcal = selectedEntries.fold<double>(
    0,
    (sum, entry) => sum + entry.totalKcal,
  );
  final baseGoalKcal = settings.goalKcalForDay(selectedDay);
  final carryoverKcal = historyGoalKcal - historyConsumedKcal;
  final flexibleGoalKcal = math
      .max(0.0, baseGoalKcal + carryoverKcal)
      .toDouble();
  final paceRatio = _paceRatioForDay(selectedDay: selectedDay, now: now);
  final pacedGoalKcal = flexibleGoalKcal * paceRatio;
  final deltaKcal = consumedKcal - pacedGoalKcal;
  final referenceGoalKcal = math.max(baseGoalKcal, flexibleGoalKcal).toDouble();
  final deadZoneKcal = math.max(60.0, referenceGoalKcal * 0.04).toDouble();
  final rangeKcal = math.max(400.0, referenceGoalKcal * 0.4).toDouble();

  return CalorieBalanceSummaryData(
    selectedDay: selectedDay,
    referenceNow: now,
    windowStartDate: windowStartDate,
    balanceStartDate: balanceStartDate,
    baseGoalKcal: baseGoalKcal,
    carryoverKcal: carryoverKcal,
    flexibleGoalKcal: flexibleGoalKcal,
    pacedGoalKcal: pacedGoalKcal,
    consumedKcal: consumedKcal,
    deltaKcal: deltaKcal,
    paceRatio: paceRatio,
    deadZoneKcal: deadZoneKcal,
    rangeKcal: rangeKcal,
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
}) {
  if (!_isSameDay(selectedDay, now)) {
    return 1.0;
  }

  final startOfDay = normalizeDiaryDay(now);
  final elapsedSeconds = now.difference(startOfDay).inSeconds;
  final fullDaySeconds = const Duration(days: 1).inSeconds;
  return (elapsedSeconds / fullDaySeconds).clamp(0.0, 1.0).toDouble();
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
