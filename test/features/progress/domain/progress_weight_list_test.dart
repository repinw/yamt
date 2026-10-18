import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';

import '../../../helpers/progress_source_overrides.dart';

final _today = DateTime(2026, 9, 24);

/// A trend from 7 to 24 September that falls by 0.1 kg per day from 84 kg.
RecentWeightTrend _trend() {
  return RecentWeightTrend(
    days: [
      for (var day = 7; day <= 24; day++)
        RecentWeightDay(
          day: DateTime(2026, 9, day),
          trendWeightKg: 84 - (day - 7) * 0.1,
        ),
    ],
    latestWeighInKg: null,
    latestWeighInDay: null,
    trendWeightKg: 84 - 17 * 0.1,
    trendKgPerWeek: -0.7,
  );
}

ProgressWeightList _list({
  CalorieGoalSettings? settings,
  RecentWeightTrend? trend,
  List<ManualHealthWeightEntry> manualEntries = const [],
  List<HealthWeightSample> healthSamples = const [],
}) {
  return ProgressWeightList.fromSources(
    start: DateTime(2026, 9, 7),
    startsAtGoal: true,
    trend: trend ?? _trend(),
    goalStarts: const [],
    settings: settings ?? progressSettings(),
    manualEntries: manualEntries,
    healthSamples: healthSamples,
    today: _today,
  );
}

void main() {
  test('groups weighings by the runs of the goal, newest first', () {
    final list = _list(
      manualEntries: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 8), weightKg: 84),
        ManualHealthWeightEntry(
          day: DateTime(2026, 9, 22),
          weightKg: 82.6,
          recordedAt: DateTime(2026, 9, 22, 7, 30),
        ),
      ],
      healthSamples: [
        HealthWeightSample(
          recordedAt: DateTime(2026, 9, 23, 6),
          weightKg: 82.4,
          sourcePackageName: 'scale.app',
        ),
        HealthWeightSample(
          recordedAt: DateTime(2026, 9, 22, 20),
          weightKg: 82.8,
          isFromThisApp: true,
        ),
      ],
    );

    expect(
      [for (final run in list.runs) run.start],
      [DateTime(2026, 9, 21), DateTime(2026, 9, 7)],
    );
    expect([for (final run in list.runs) run.number], [3, 1]);
    final current = list.runs.first;
    expect([for (final w in current.weighings) w.weightKg], [82.4, 82.8, 82.6]);
    expect(
      [for (final w in current.weighings) w.source],
      [
        ProgressWeighingSource.scale,
        ProgressWeighingSource.manual,
        ProgressWeighingSource.manual,
      ],
    );
    // The current run ends today, the first one on 13 September.
    expect(current.trendWeightKg, closeTo(82.3, 1e-9));
    expect(list.runs.last.trendWeightKg, closeTo(83.4, 1e-9));
    // Against the trend of 20 September, the day before the run.
    expect(current.changeKg, closeTo(-0.4, 1e-9));
    expect(list.runs.last.changeKg, isNull);
    expect(list.runs.last.weighings.single.at, isNull);
  });

  test('leaves out weighings before the start and after today', () {
    final list = _list(
      manualEntries: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 6), weightKg: 85),
        ManualHealthWeightEntry(day: DateTime(2026, 9, 25), weightKg: 81),
      ],
    );

    expect(list.runs, isEmpty);
  });

  test('without a goal, groups by 7-day blocks that end today', () {
    final list = _list(
      settings: const CalorieGoalSettings.empty(),
      manualEntries: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 18), weightKg: 83),
        ManualHealthWeightEntry(day: DateTime(2026, 9, 17), weightKg: 83),
      ],
    );

    expect(
      [for (final run in list.runs) run.start],
      [DateTime(2026, 9, 18), DateTime(2026, 9, 11)],
    );
    expect(list.runs.first.number, isNull);
  });

  test('changes since the start of the range and the way to the goal', () {
    final list = _list();

    expect(list.changeKg, closeTo(-1.7, 1e-9));
    expect(list.kgToTarget, closeTo(4.3, 1e-9));
    expect(list.targetWeightKg, 78);
  });

  test('a weighing before the goal stays apart from the run of that day', () {
    // The block of 4 to 10 September without a goal on the 4th, 5th, and
    // 6th, and the first goal run from the 7th.
    final list = _list(
      manualEntries: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 7), weightKg: 84),
      ],
    );
    final withEarlier = ProgressWeightList.fromSources(
      start: DateTime(2026, 8, 28),
      startsAtGoal: false,
      trend: _trend(),
      goalStarts: const [],
      settings: progressSettings(),
      manualEntries: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 6), weightKg: 85),
        ManualHealthWeightEntry(day: DateTime(2026, 9, 7), weightKg: 84),
      ],
      healthSamples: const [],
      today: _today,
    );

    expect(list.runs.single.number, 1);
    expect([for (final run in withEarlier.runs) run.number], [1, null]);
  });

  test('a reached goal weight leaves nothing to go', () {
    final list = _list(
      trend: RecentWeightTrend(
        days: [RecentWeightDay(day: _today, trendWeightKg: 77)],
        latestWeighInKg: 77,
        latestWeighInDay: _today,
        trendWeightKg: 77,
        trendKgPerWeek: -0.5,
      ),
    );

    expect(list.kgToTarget, isNull);
    expect(list.targetWeightKg, 78);
  });

  test('maintaining shows no goal weight', () {
    final list = _list(
      settings: CalorieGoalSettings.single(
        dailyKcalGoal: 2400,
        calculatorProfile: progressProfile.copyWith(
          goalMode: CalorieGoalMode.maintain,
        ),
        effectiveDate: DateTime(2026, 9, 7),
      ),
    );

    expect(list.targetWeightKg, isNull);
    expect(list.kgToTarget, isNull);
  });

  test('a run after the last weigh-in keeps the last trend', () {
    final list = _list(
      trend: RecentWeightTrend(
        days: [
          RecentWeightDay(day: DateTime(2026, 9, 20), trendWeightKg: 83),
          RecentWeightDay(day: DateTime(2026, 9, 21), trendWeightKg: 82.8),
          for (var day = 22; day <= 24; day++)
            RecentWeightDay(day: DateTime(2026, 9, day)),
        ],
        latestWeighInKg: 82.8,
        latestWeighInDay: DateTime(2026, 9, 21),
        trendWeightKg: 82.8,
        trendKgPerWeek: -0.5,
      ),
      manualEntries: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 21), weightKg: 82.8),
      ],
    );

    expect(list.runs.single.trendWeightKg, 82.8);
    expect(list.runs.single.changeKg, closeTo(-0.2, 1e-9));
  });

  test('practice days after a goal form blocks from their first day', () {
    // A new goal from 17 September that counts only from 1 October.
    final list = _list(
      settings: progressSettings().applyGoalChange(
        changedAt: DateTime(2026, 9, 17),
        dailyKcalGoal: 2300,
        calculatorProfile: progressProfile,
        countingStartDate: DateTime(2026, 10),
        source: CalorieGoalSource.calculator,
      ),
      manualEntries: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 15), weightKg: 83),
        ManualHealthWeightEntry(day: DateTime(2026, 9, 18), weightKg: 82.7),
        ManualHealthWeightEntry(day: DateTime(2026, 9, 24), weightKg: 82.3),
      ],
    );

    expect(
      [for (final run in list.runs) run.start],
      [DateTime(2026, 9, 24), DateTime(2026, 9, 17), DateTime(2026, 9, 14)],
    );
    expect([for (final run in list.runs) run.number], [null, null, 2]);
    // Run 2 ends with the goal on 16 September, the block on the 23rd.
    expect(list.runs[2].trendWeightKg, closeTo(83.1, 1e-9));
    expect(list.runs[1].trendWeightKg, closeTo(82.4, 1e-9));
  });

  test('a new goal ends the last run of the goal before', () {
    final list = _list(
      settings: progressSettings().applyGoalChange(
        changedAt: DateTime(2026, 9, 17),
        dailyKcalGoal: 2300,
        calculatorProfile: progressProfile,
        countingStartDate: DateTime(2026, 9, 17),
        source: CalorieGoalSource.calculator,
      ),
      manualEntries: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 15), weightKg: 83),
        ManualHealthWeightEntry(day: DateTime(2026, 9, 18), weightKg: 82.7),
      ],
    );

    expect(
      [for (final run in list.runs) run.start],
      [DateTime(2026, 9, 17), DateTime(2026, 9, 14)],
    );
    expect([for (final run in list.runs) run.number], [1, 2]);
    // Run 2 of the first goal ends on 16 September, before the new goal.
    expect(list.runs.last.trendWeightKg, closeTo(83.1, 1e-9));
    expect(list.runs.first.trendWeightKg, closeTo(82.4, 1e-9));
  });
}
