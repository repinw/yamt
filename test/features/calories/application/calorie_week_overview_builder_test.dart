import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_builder.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

final _today = DateTime(2026, 10, 8);
final DateTime _tomorrow = addDiaryDays(_today, 1);
final DateTime _dayAfter = addDiaryDays(_today, 2);
final DateTime _runStart = addDiaryDays(_today, -1);

final _settings = CalorieGoalSettings.single(
  dailyKcalGoal: 2000,
  calculatorProfile: null,
  effectiveDate: _runStart,
);

/// The overview of the window that ends on [day]: yesterday 1500 kcal,
/// today 800 kcal, under a 2000 kcal goal.
CalorieWeekOverview _build(
  DateTime day, {
  DateTime? closedDay,
  void Function()? onClosedDayRead,
}) {
  final eaten = {diaryDayKey(_runStart): 1500.0, diaryDayKey(_today): 800.0};
  return buildCalorieWeekOverview(
    settings: _settings,
    overviews: [
      for (final date in buildDiaryVisibleDays(anchorDay: day))
        CalorieWeekDayOverview(
          date: date,
          totalKcal: eaten[diaryDayKey(date)] ?? 0,
          goalKcal: date.isBefore(_runStart) ? 0 : 2000,
          entryCount: eaten.containsKey(diaryDayKey(date)) ? 1 : 0,
        ),
    ],
    realToday: _today,
    balanceStartDate: _runStart,
    carryoverStartDate: _runStart,
    historicalEntries: const [],
    readClosedDay: () {
      onClosedDayRead?.call();
      return closedDay;
    },
  );
}

void main() {
  test('today gets the carryover of the days before it', () {
    final week = _build(_today);

    expect(week.carryoverBeforeTodayKcal, greaterThan(0));
    expect(week.todayFlexibleGoalKcal, 2000 + week.carryoverBeforeTodayKcal);
    expect(week.previousDayCarryoverKcal, isNull);
    expect(week.isPreviousDayClosed, isFalse);
  });

  test('tomorrow offers the carryover but gets none while today is open', () {
    final week = _build(_tomorrow);

    expect(week.previousDayCarryoverKcal, greaterThan(0));
    expect(week.carryoverBeforeTodayKcal, 0);
    expect(week.todayFlexibleGoalKcal, 2000);
    expect(week.isPreviousDayClosed, isFalse);
  });

  test('tomorrow gets the carryover once today is closed', () {
    final week = _build(_tomorrow, closedDay: _today);

    expect(week.isPreviousDayClosed, isTrue);
    expect(week.carryoverBeforeTodayKcal, week.previousDayCarryoverKcal);
  });

  test('a later day gets no carryover and never reads the closed day', () {
    var reads = 0;
    final week = _build(
      _dayAfter,
      closedDay: _today,
      onClosedDayRead: () {
        reads += 1;
      },
    );

    expect(reads, 0);
    expect(week.carryoverBeforeTodayKcal, 0);
    expect(week.previousDayCarryoverKcal, isNull);
    expect(week.isPreviousDayClosed, isFalse);
  });

  test('a closed day other than today does not count', () {
    final week = _build(_tomorrow, closedDay: _runStart);

    expect(week.isPreviousDayClosed, isFalse);
    expect(week.carryoverBeforeTodayKcal, 0);
  });
}
