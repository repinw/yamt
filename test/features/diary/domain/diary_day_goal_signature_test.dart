import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/diary/domain/diary_day_goal_signature.dart';

final DateTime _monday = DateTime(2026, 11, 16);
final DateTime _thursday = addLocalDays(_monday, 3);

final _settings = CalorieGoalSettings.single(
  dailyKcalGoal: 2200,
  calculatorProfile: null,
  effectiveDate: _monday,
);

bool _same(CalorieGoalSettings left, CalorieGoalSettings right) =>
    const ListEquality<Object?>().equals(
      diaryDashboardGoalSignatures(left, _thursday),
      diaryDashboardGoalSignatures(right, _thursday),
    );

void main() {
  test('no settings, no signatures', () {
    expect(diaryDashboardGoalSignatures(null, _thursday), isNull);
  });

  test('the same settings give the same signatures', () {
    expect(_same(_settings, _settings.copyWith()), isTrue);
  });

  test('K30: a switch of the mode reloads the day', () {
    for (final mode in WeekBalanceMode.values) {
      if (mode == _settings.weekBalanceMode) continue;
      expect(
        _same(_settings, _settings.copyWith(weekBalanceMode: mode)),
        isFalse,
        reason: mode.name,
      );
    }
  });

  test('a pause day before the day reloads it (K11, K18)', () {
    expect(
      _same(_settings, _settings.setPauseDay(day: _monday, isPause: true)),
      isFalse,
    );
  });

  test('a later day of the run that changes reloads the day (K26)', () {
    final sunday = addLocalDays(_monday, 6);

    expect(
      _same(_settings, _settings.setPauseDay(day: sunday, isPause: true)),
      isFalse,
    );
    expect(_same(_settings, _settings.toggleTrainingDay(sunday)), isFalse);
  });
}
