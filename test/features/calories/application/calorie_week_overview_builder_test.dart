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

  // Closed, today counts as finished: +600 from yesterday and +1200 from
  // today make +1800 over the five days from tomorrow on, 360 a day, which
  // the limit of 20 % of 2000 and at most 350 cuts to +350.
  test('K39: in "Mit Übertrag" a closed today counts for tomorrow', () {
    final open = _build(_tomorrow, mode: WeekBalanceMode.carryover);
    final closed = _build(
      _tomorrow,
      mode: WeekBalanceMode.carryover,
      closedDay: _today,
    );

    expect(open.carryoverBeforeTodayKcal, 100);
    expect(closed.carryoverBeforeTodayKcal, 350);
    expect(closed.todayFlexibleGoalKcal, 2350);
    expect(closed.weekBalance?.dayOf(_tomorrow)?.budgetKcal, 2350);
  });

  test('K39: in "Mit Übertrag" a closed today counts for every coming '
      'day, not only tomorrow', () {
    var reads = 0;
    final week = _build(
      _dayAfter,
      mode: WeekBalanceMode.carryover,
      closedDay: _today,
      onClosedDayRead: () {
        reads += 1;
      },
    );

    expect(reads, 1);
    // +1800 − 350 for tomorrow leaves +1450 over four days: 362.5, cut to 350.
    expect(week.carryoverBeforeTodayKcal, 350);
    expect(week.todayFlexibleGoalKcal, 2350);
    expect(week.isPreviousDayClosed, isFalse, reason: 'only tomorrow says so');
    expect(week.previousDayCarryoverKcal, isNull);
  });

  test('K9: in "Aus" and "Anzeigen" a stored closed today is never read '
      'and changes no budget', () {
    for (final mode in [WeekBalanceMode.off, WeekBalanceMode.show]) {
      for (final day in [_today, _tomorrow, _dayAfter]) {
        var reads = 0;
        final week = _build(
          day,
          mode: mode,
          closedDay: _today,
          onClosedDayRead: () {
            reads += 1;
          },
        );

        expect(reads, 0, reason: '${mode.name} $day');
        expect(week.carryoverBeforeTodayKcal, 0, reason: '${mode.name} $day');
        expect(week.todayFlexibleGoalKcal, 2000, reason: '${mode.name} $day');
        expect(week.isPreviousDayClosed, isFalse, reason: '${mode.name} $day');
        expect(
          week.previousDayCarryoverKcal,
          isNull,
          reason: '${mode.name} $day',
        );
      }
    }
  });

  test('K38: tomorrow reports today as closed once it is stored', () {
    final open = _build(_tomorrow, mode: WeekBalanceMode.carryover);
    final closed = _build(
      _tomorrow,
      mode: WeekBalanceMode.carryover,
      closedDay: _today,
    );

    expect(open.isPreviousDayClosed, isFalse);
    expect(open.previousDayCarryoverKcal, 100);
    expect(closed.isPreviousDayClosed, isTrue);
    expect(closed.previousDayCarryoverKcal, 350);
  });

  test('a closed day other than today does not count', () {
    final week = _build(
      _tomorrow,
      mode: WeekBalanceMode.carryover,
      closedDay: _runStart,
    );

    expect(week.isPreviousDayClosed, isFalse);
    expect(week.carryoverBeforeTodayKcal, 100);
  });
}
