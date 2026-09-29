import 'package:meta/meta.dart';
import 'package:yamt/features/progress/domain/progress_average.dart';
import 'package:yamt/features/progress/domain/progress_day.dart';

/// Intake of the current 7-day run and, by day type, of a longer period.
@immutable
class ProgressIntake {
  /// Creates the intake.
  const new({
    required this.weekDays,
    required this.runNumber,
    required this.week,
    required this.training,
    required this.rest,
  });

  /// Splits [days] into the run from [weekStart] to [weekEnd] and the
  /// comparison of the days from [comparisonStart] to the day before [today].
  factory fromDays({
    required List<ProgressDay> days,
    required DateTime weekStart,
    required DateTime weekEnd,
    required DateTime comparisonStart,
    required DateTime today,
    required int? runNumber,
  }) {
    final weekDays = days
        .where(
          (day) => !day.day.isBefore(weekStart) && !day.day.isAfter(weekEnd),
        )
        .toList(growable: false);
    final comparisonDays = days.where(
      (day) => !day.day.isBefore(comparisonStart) && day.day.isBefore(today),
    );
    return ProgressIntake(
      weekDays: weekDays,
      runNumber: runNumber,
      week: ProgressAverage.of(weekDays),
      training: ProgressAverage.of(
        comparisonDays.where((day) => day.isTrainingDay),
      ),
      rest: ProgressAverage.of(
        comparisonDays.where((day) => !day.isTrainingDay),
      ),
    );
  }

  /// The days of the current 7-day run, oldest first.
  final List<ProgressDay> weekDays;

  /// Number of the current run within the goal, or `null` without a goal.
  final int? runNumber;

  /// Averages of the current run.
  final ProgressAverage week;

  /// Averages of the training days of the comparison period.
  final ProgressAverage training;

  /// Averages of the rest days of the comparison period.
  final ProgressAverage rest;

  Iterable<ProgressDay> get _pastWeekDays =>
      weekDays.where((day) => !day.isFuture);

  double _sumPast(double Function(ProgressDay day) value) =>
      _pastWeekDays.fold<double>(0, (sum, day) => sum + value(day));

  /// Calorie goal of the whole run: the week budget.
  double get weekGoalKcal =>
      weekDays.fold<double>(0, (sum, day) => sum + day.goalKcal);

  /// Kilocalories eaten in the run so far.
  double get weekEatenKcal => _sumPast((day) => day.eatenKcal);

  /// Kilocalories from protein eaten in the run so far.
  double get weekProteinKcal => _sumPast((day) => day.proteinKcal);

  /// Kilocalories from carbohydrates eaten in the run so far.
  double get weekCarbsKcal => _sumPast((day) => day.carbsKcal);

  /// Kilocalories from fat eaten in the run so far.
  double get weekFatKcal => _sumPast((day) => day.fatKcal);

  /// Number of run days up to and including today.
  int get weekDayNumber => _pastWeekDays.length;
}
