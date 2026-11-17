import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_builder.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';

final _today = DateTime(2026, 10, 8);
final DateTime _tomorrow = addLocalDays(_today, 1);
final DateTime _dayAfter = addLocalDays(_today, 2);
final DateTime _runStart = addLocalDays(_today, -1);

CalorieGoalSettings _settings(WeekBalanceMode mode) =>
    CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: _runStart,
    ).copyWith(weekBalanceMode: mode);

/// The overview of the window that ends on [day]: yesterday, the first day
/// of the run, 1400 kcal and today 800 kcal, under a 2000 kcal goal. The
/// balance of +600 spreads over the six days from today on: +100 each.
CalorieWeekOverview _build(
  DateTime day, {
  required WeekBalanceMode mode,
  DateTime? closedDay,
  void Function()? onClosedDayRead,
}) {
  final eaten = {localDayKey(_runStart): 1400.0, localDayKey(_today): 800.0};
  return buildCalorieWeekOverview(
    settings: _settings(mode),
    overviews: [
      for (final date in buildRollingLocalDays(anchorDay: day))
        CalorieWeekDayOverview(
          date: date,
          totalKcal: eaten[localDayKey(date)] ?? 0,
          goalKcal: date.isBefore(_runStart) ? 0 : 2000,
          entryCount: eaten.containsKey(localDayKey(date)) ? 1 : 0,
        ),
    ],
    realToday: _today,
    balanceStartDate: _runStart,
    carryoverStartDate: _runStart,
    historicalEntries: const [],
    laterEntries: const [],
    readClosedDay: () {
      onClosedDayRead?.call();
      return closedDay;
    },
  );
}

void main() {
  test('K10/K11: with the carryover, today gets the carryover of the days '
      'before it', () {
    final week = _build(_today, mode: WeekBalanceMode.carryover);

    expect(week.carryoverBeforeTodayKcal, 100);
    expect(week.todayFlexibleGoalKcal, 2100);
    expect(week.weekBalance?.dayOf(_today)?.budgetKcal, 2100);
  });

  test('K6: without the carryover, today keeps its plain goal', () {
    for (final mode in [WeekBalanceMode.off, WeekBalanceMode.show]) {
      final week = _build(_today, mode: mode);

      expect(week.carryoverBeforeTodayKcal, 0, reason: mode.name);
      expect(week.todayFlexibleGoalKcal, 2000, reason: mode.name);
    }
  });

  test('K26/K27: with the carryover, tomorrow and later days get the '
      'preview while today is open', () {
    // Today is under its budget, so it counts as hitting it: +100 a day.
    for (final day in [_tomorrow, _dayAfter]) {
      final week = _build(day, mode: WeekBalanceMode.carryover);

      expect(week.carryoverBeforeTodayKcal, 100, reason: '$day');
      expect(week.todayFlexibleGoalKcal, 2100, reason: '$day');
    }
  });

  test('K27: without the carryover, coming days keep the plain goal', () {
    for (final mode in [WeekBalanceMode.off, WeekBalanceMode.show]) {
      for (final day in [_tomorrow, _dayAfter]) {
        final week = _build(day, mode: mode);

        expect(week.carryoverBeforeTodayKcal, 0, reason: '${mode.name} $day');
        expect(week.todayFlexibleGoalKcal, 2000, reason: '${mode.name} $day');
      }
    }
  });

  test('K9: a stored closed day does not change the budget of tomorrow', () {
    final open = _build(_tomorrow, mode: WeekBalanceMode.carryover);
    final closed = _build(
      _tomorrow,
      mode: WeekBalanceMode.carryover,
      closedDay: _today,
    );

    expect(closed.carryoverBeforeTodayKcal, open.carryoverBeforeTodayKcal);
    expect(closed.todayFlexibleGoalKcal, open.todayFlexibleGoalKcal);
  });

  // The close-day plumbing is still in lib/ (K9 removed its button); these
  // two keep its flag honest until it is deleted.
  test('tomorrow reports today as closed once it is stored', () {
    final week = _build(
      _tomorrow,
      mode: WeekBalanceMode.show,
      closedDay: _today,
    );

    expect(week.isPreviousDayClosed, isTrue);
  });

  test('a closed day other than today does not count', () {
    final week = _build(
      _tomorrow,
      mode: WeekBalanceMode.show,
      closedDay: _runStart,
    );

    expect(week.isPreviousDayClosed, isFalse);
  });

  test('a later day never reads the closed day', () {
    var reads = 0;
    _build(
      _dayAfter,
      mode: WeekBalanceMode.carryover,
      closedDay: _today,
      onClosedDayRead: () {
        reads += 1;
      },
    );

    expect(reads, 0);
  });
}
