import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_weight_runs.dart';

/// Which days the weight list covers.
enum ProgressWeightRange {
  /// The current goal, from its start to today.
  goal,

  /// The last four weeks.
  fourWeeks,

  /// All goals, from the start of the first one to today.
  all,
}

/// Where a weighing comes from.
enum ProgressWeighingSource {
  /// Typed in by the user, in this app or saved by it to Health.
  manual,

  /// Written to Health by another app, such as a scale.
  scale,
}

/// One weighing of the list, from a manual [entry] or a Health [sample].
@immutable
class ProgressWeighing {
  /// Creates a weighing.
  const new({
    required this.day,
    required this.at,
    required this.weightKg,
    required this.source,
    this.entry,
    this.sample,
  });

  /// The local day it counts for.
  final DateTime day;

  /// When it was taken, or `null` for manual weights of 3.8.1 and older.
  final DateTime? at;

  /// The measured weight.
  final double weightKg;

  /// Where it comes from.
  final ProgressWeighingSource source;

  /// The manual entry it stands for, or `null` for a Health weighing.
  final ManualHealthWeightEntry? entry;

  /// The Health sample it stands for, or `null` for a manual entry.
  final HealthWeightSample? sample;

  /// Whether the user left it out of every count.
  bool get isIgnored => sample?.isIgnored ?? false;
}

/// The weighings of one 7-day run, newest first.
@immutable
class ProgressWeightRun {
  /// Creates a run.
  const new({
    required this.start,
    required this.number,
    required this.trendWeightKg,
    required this.changeKg,
    required this.weighings,
  });

  /// First day of the run.
  final DateTime start;

  /// Number of the run in its goal, or `null` without a goal.
  final int? number;

  /// The trend weight at the end of the run, or today in the current one.
  final double? trendWeightKg;

  /// The change of [trendWeightKg] since the day before the run, or `null`
  /// without a trend then.
  final double? changeKg;

  /// The weighings of the run, newest first.
  final List<ProgressWeighing> weighings;
}

/// Every weighing of a range, grouped by 7-day runs, with the trend and the
/// goal weight.
@immutable
class ProgressWeightList {
  /// Creates a weight list.
  const new({
    required this.start,
    required this.startsAtGoal,
    required this.trend,
    required this.goalStarts,
    required this.targetWeightKg,
    required this.kgToTarget,
    required this.changeKg,
    required this.runs,
  });

  /// Groups the weighings of [manualEntries] and [healthSamples] from
  /// [start] to [today] by the runs of [settings].
  ///
  /// The trend weights of the runs and the header come from [series], so a
  /// day before the chart's [trend] still has one.
  factory fromSources({
    required DateTime start,
    required bool startsAtGoal,
    required RecentWeightTrend trend,
    required DailyWeightSeries series,
    required List<ProgressGoalStart> goalStarts,
    required CalorieGoalSettings settings,
    required List<ManualHealthWeightEntry> manualEntries,
    required List<HealthWeightSample> healthSamples,
    required DateTime today,
  }) {
    final weighings =
        [
              for (final entry in manualEntries)
                ProgressWeighing(
                  day: entry.day,
                  at: entry.recordedAt,
                  weightKg: entry.weightKg,
                  source: ProgressWeighingSource.manual,
                  entry: entry,
                ),
              for (final sample in healthSamples)
                if (sample.recordedAt.toLocal() case final at)
                  ProgressWeighing(
                    day: normalizeDiaryDay(at),
                    at: at,
                    weightKg: sample.weightKg,
                    source: sample.isFromThisApp
                        ? ProgressWeighingSource.manual
                        : ProgressWeighingSource.scale,
                    sample: sample,
                  ),
            ]
            .where((w) => !w.day.isBefore(start) && !w.day.isAfter(today))
            .toList()
          ..sort(
            (left, right) =>
                (right.at ?? right.day).compareTo(left.at ?? left.day),
          );

    final runOfDay = progressWeightRunsByDay(settings, start, today);
    final byRun = groupBy(weighings, (w) => runOfDay[w.day]!);
    final keys = byRun.keys.sorted(
      (left, right) => left.start.compareTo(right.start),
    );
    final runs = <ProgressWeightRun>[];
    for (final key in keys) {
      final runTrend = series.trendOnOrBefore(key.end);
      final before = series.trendOnOrBefore(addDiaryDays(key.start, -1));
      runs.add(
        ProgressWeightRun(
          start: key.start,
          number: key.number,
          trendWeightKg: runTrend,
          changeKg: runTrend == null || before == null
              ? null
              : runTrend - before,
          weighings: List.unmodifiable(byRun[key]!),
        ),
      );
    }
    final profile = settings.calculatorProfile;
    final target = profile?.goalMode == CalorieGoalMode.maintain
        ? null
        : profile?.targetWeightKg;
    final current = trend.trendWeightKg;
    final left = target == null || current == null
        ? null
        : profile?.goalMode == CalorieGoalMode.gain
        ? target - current
        : current - target;
    // From the day before the range like the runs, so they add up to it.
    final first =
        series.trendOnOrBefore(addDiaryDays(start, -1)) ??
        trend.days
            .firstWhereOrNull(
              (day) => !day.day.isBefore(start) && day.trendWeightKg != null,
            )
            ?.trendWeightKg;
    return ProgressWeightList(
      start: start,
      startsAtGoal: startsAtGoal,
      trend: trend,
      goalStarts: goalStarts,
      targetWeightKg: target,
      kgToTarget: left != null && left > 0 ? left : null,
      changeKg: first == null || current == null ? null : current - first,
      runs: List.unmodifiable(runs.reversed),
    );
  }

  /// First day of the range.
  final DateTime start;

  /// Whether [start] is the start of the current goal.
  final bool startsAtGoal;

  /// Weigh-ins and trend weight per day of the chart, oldest first.
  final RecentWeightTrend trend;

  /// First day of each goal in the chart, oldest first.
  final List<ProgressGoalStart> goalStarts;

  /// The goal weight, or `null` without one or while maintaining.
  final double? targetWeightKg;

  /// Kilograms the trend still has to go to [targetWeightKg], or `null`
  /// without a goal weight or once the trend reached it.
  final double? kgToTarget;

  /// The change of the trend weight since the day before the range, or
  /// since its first trend day without a weigh-in before the range.
  final double? changeKg;

  /// The runs with weighings, newest first.
  final List<ProgressWeightRun> runs;

  /// The weighings that the user left out of every count.
  List<ProgressWeighing> get ignoredWeighings => [
    for (final run in runs)
      for (final weighing in run.weighings)
        if (weighing.isIgnored) weighing,
  ];
}
