import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/progress/domain/progress_day.dart';
import 'package:yamt/features/progress/domain/progress_intake.dart';

final _today = DateTime(2026, 9, 26);

ProgressDay _day(
  DateTime day, {
  double eaten = 2000,
  double goal = 2200,
  bool training = false,
  bool pause = false,
}) {
  return ProgressDay(
    day: day,
    eatenKcal: eaten,
    proteinGrams: eaten == 0 ? 0 : 150,
    carbsGrams: eaten == 0 ? 0 : 200,
    fatGrams: eaten == 0 ? 0 : 60,
    goalKcal: goal,
    proteinGoalGrams: 160,
    carbsGoalGrams: 220,
    fatGoalGrams: 70,
    isTrainingDay: training,
    isPauseDay: pause,
    hasEntries: eaten > 0,
    isFuture: day.isAfter(_today),
  );
}

void main() {
  // Run from Monday 21 Sep to Sunday 27 Sep; today is Saturday.
  final weekStart = DateTime(2026, 9, 21);
  final weekEnd = DateTime(2026, 9, 27);

  ProgressIntake intake(List<ProgressDay> days) => ProgressIntake.fromDays(
    days: days,
    weekStart: weekStart,
    weekEnd: weekEnd,
    comparisonStart: DateTime(2026, 8, 29),
    today: _today,
    runNumber: 3,
  );

  test('averages only logged past days of the run', () {
    final result = intake([
      _day(DateTime(2026, 9, 20), eaten: 5000),
      _day(weekStart, eaten: 1800),
      _day(DateTime(2026, 9, 22), eaten: 2200),
      _day(DateTime(2026, 9, 23), eaten: 0),
      _day(DateTime(2026, 9, 24), eaten: 3000, pause: true),
      _day(_today),
      _day(weekEnd, eaten: 0),
    ]);

    expect(result.weekDays, hasLength(6));
    expect(result.runNumber, 3);
    expect(result.week.dayCount, 3);
    expect(result.week.eatenKcal, 2000);
    expect(result.week.proteinGrams, 150);
  });

  test('adds up the week budget over all run days', () {
    final result = intake([
      for (var offset = 0; offset < 7; offset++)
        _day(addDiaryDays(weekStart, offset), eaten: offset < 6 ? 2000 : 0),
    ]);

    expect(result.weekGoalKcal, 7 * 2200);
    expect(result.weekEatenKcal, 6 * 2000);
    expect(result.weekDayNumber, 6);
    expect(result.weekProteinKcal, 6 * 150 * kcalPerGramProteinOrCarbs);
    expect(result.weekFatKcal, 6 * 60 * kcalPerGramFat);
  });

  test('compares training and rest days from period start to yesterday', () {
    final result = intake([
      _day(DateTime(2026, 8, 28), eaten: 9000, training: true),
      _day(DateTime(2026, 9), eaten: 2600, training: true),
      _day(DateTime(2026, 9, 2), eaten: 1800),
      _day(DateTime(2026, 9, 3), eaten: 2400, training: true),
      _day(_today, eaten: 4000, training: true),
    ]);

    expect(result.training.dayCount, 2);
    expect(result.training.eatenKcal, 2500);
    expect(result.rest.dayCount, 1);
    expect(result.rest.eatenKcal, 1800);
  });
}
