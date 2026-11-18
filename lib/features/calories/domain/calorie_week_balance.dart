import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';

part 'calorie_week_balance.g.dart';

/// What one day of a goal run brings to the week balance: its goal, what was
/// eaten, and whether it was a pause day.
typedef WeekBalanceDayInput = ({
  DateTime date,
  double goalKcal,
  double eatenKcal,
  bool hasEntries,
  bool isPauseDay,
});

/// A finished day that is off its budget by less than this many kcal is no
/// miss and shows no number.
const weekBalanceNoticeKcal = 50.0;

/// One day of a goal run with the budget it is measured against.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class WeekBalanceDay {
  /// Creates a day of the week balance.
  const new({
    required this.date,
    required this.goalKcal,
    required this.eatenKcal,
    required this.hasEntries,
    required this.isPauseDay,
    required this.carryoverKcal,
  });

  /// Creates data from persisted JSON.
  factory fromJson(Map<String, dynamic> json) => _$WeekBalanceDayFromJson(json);

  /// Converts data to persisted JSON.
  Map<String, dynamic> toJson() => _$WeekBalanceDayToJson(this);

  /// The local day.
  final DateTime date;

  /// The day's own goal, the training day's higher one included.
  final double goalKcal;

  /// Kcal eaten on the day.
  final double eatenKcal;

  /// Whether the day has entries.
  final bool hasEntries;

  /// Whether the day is a pause day.
  final bool isPauseDay;

  /// What the week adds to the goal or takes from it; 0 unless the mode
  /// carries over. For a day after today it is the preview.
  final double carryoverKcal;

  /// What the day is measured against: the goal and the carryover.
  double get budgetKcal => goalKcal + carryoverKcal;

  /// Eaten minus the budget: positive when more was eaten.
  double get differenceKcal => eatenKcal - budgetKcal;

  /// Whether the day is off its budget by at least [weekBalanceNoticeKcal].
  bool get isOffBudget => differenceKcal.abs() >= weekBalanceNoticeKcal;

  @override
  bool operator ==(Object other) =>
      other is WeekBalanceDay &&
      other.date == date &&
      other.goalKcal == goalKcal &&
      other.eatenKcal == eatenKcal &&
      other.hasEntries == hasEntries &&
      other.isPauseDay == isPauseDay &&
      other.carryoverKcal == carryoverKcal;

  @override
  int get hashCode => Object.hash(
    date,
    goalKcal,
    eatenKcal,
    hasEntries,
    isPauseDay,
    carryoverKcal,
  );
}

/// The seven days of the goal run that holds a diary day, with the budget of
/// each (#911).
///
/// The balance of a day is the sum of goal minus eaten over the finished
/// days of the run before it; a pause day and a day without entries add
/// nothing. The carryover of the day spreads that balance over the days left
/// (see [CalorieBudgetCalculator.distributeCarryover]) and what is left at the
/// end of the run is dropped. For the days after today it assumes that today
/// and every day until then hit their budget; what today is already over its
/// budget counts at once. Once today is closed, it counts as a finished day.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class WeekBalance {
  /// Creates a week balance.
  const new({required this.mode, required this.weightGoal, required this.days});

  /// Resolves the budgets of the run [days], from its first day, with
  /// [today] the real today. With [isTodayClosed], today counts as finished
  /// for the days after it.
  factory resolve({
    required WeekBalanceMode mode,
    required CalorieGoalMode weightGoal,
    required DateTime today,
    required List<WeekBalanceDayInput> days,
    bool isTodayClosed = false,
  }) {
    var balance = 0.0;
    final normalizedToday = normalizeLocalDay(today);
    final resolved = <WeekBalanceDay>[];
    for (final (index, day) in days.indexed) {
      final carryover = mode.carriesOver && !day.isPauseDay
          ? CalorieBudgetCalculator.distributeCarryover(
              carryoverKcal: balance,
              remainingDays: days.length - index,
              baseGoalKcal: day.goalKcal,
            )
          : 0.0;
      final budget = day.goalKcal + carryover;
      balance += _balanceOf(
        day,
        budget: budget,
        today: normalizedToday,
        isTodayClosed: isTodayClosed,
      );
      resolved.add(
        WeekBalanceDay(
          date: day.date,
          goalKcal: day.goalKcal,
          eatenKcal: day.eatenKcal,
          hasEntries: day.hasEntries,
          isPauseDay: day.isPauseDay,
          carryoverKcal: carryover,
        ),
      );
    }
    return WeekBalance(
      mode: mode,
      weightGoal: weightGoal,
      days: List<WeekBalanceDay>.unmodifiable(resolved),
    );
  }

  /// Creates data from persisted JSON.
  factory fromJson(Map<String, dynamic> json) => _$WeekBalanceFromJson(json);

  /// Converts data to persisted JSON.
  Map<String, dynamic> toJson() => _$WeekBalanceToJson(this);

  /// The mode the budgets follow.
  final WeekBalanceMode mode;

  /// The weight goal of the run, which tells whether over or under the
  /// budget is the miss.
  final CalorieGoalMode weightGoal;

  /// The days of the run, from its first day: seven, or fewer for a run that
  /// a new goal cut short.
  final List<WeekBalanceDay> days;

  /// Whether going over the budget is the miss: for every weight goal but
  /// gaining.
  bool get overIsMiss => weightGoal != CalorieGoalMode.gain;

  /// Whether [day] is a miss: a day that counts, off its budget by at least
  /// [weekBalanceNoticeKcal] on the side that [overIsMiss] names.
  bool isMiss(WeekBalanceDay day) =>
      day.hasEntries &&
      !day.isPauseDay &&
      day.isOffBudget &&
      (day.differenceKcal > 0) == overIsMiss;

  /// The day of [day], or null when it is no day of the run.
  WeekBalanceDay? dayOf(DateTime day) {
    for (final candidate in days) {
      if (isSameLocalDay(candidate.date, day)) {
        return candidate;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is WeekBalance &&
      other.mode == mode &&
      other.weightGoal == weightGoal &&
      const ListEquality<WeekBalanceDay>().equals(other.days, days);

  @override
  int get hashCode => Object.hash(
    mode,
    weightGoal,
    const ListEquality<WeekBalanceDay>().hash(days),
  );
}

/// What [day] adds to the balance of the run: a finished day, and today once
/// it is [isTodayClosed], its goal minus what was eaten; an open today the
/// same unless it stays within its [budget]; a coming day what it frees or
/// takes by hitting its budget.
double _balanceOf(
  WeekBalanceDayInput day, {
  required double budget,
  required DateTime today,
  required bool isTodayClosed,
}) {
  if (day.isPauseDay) {
    return 0;
  }
  if (day.date.isBefore(today) ||
      (isTodayClosed && isSameLocalDay(day.date, today))) {
    return day.hasEntries ? day.goalKcal - day.eatenKcal : 0;
  }
  final counted = isSameLocalDay(day.date, today)
      ? math.max(day.eatenKcal, budget)
      : budget;
  return day.goalKcal - counted;
}
