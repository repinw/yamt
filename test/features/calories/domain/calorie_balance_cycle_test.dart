import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';

void main() {
  group('resolveCalorieBalanceCycleStartDate', () {
    test(
      'returns the active cycle anchor date when an active goal exists',
      () {
        final settings =
            CalorieGoalSettings.single(
              dailyKcalGoal: 2100,
              calculatorProfile: null,
              effectiveDate: DateTime(2026, 4, 1, 8),
            ).applyGoalChange(
              changedAt: DateTime(2026, 4, 8, 9),
              dailyKcalGoal: 2200,
              calculatorProfile: null,
              source: CalorieGoalSource.weeklyCheckIn,
            );

        final startDate = resolveCalorieBalanceCycleStartDate(
          settings: settings,
          day: DateTime(2026, 4, 10, 14),
          fallbackStartDate: DateTime(2026, 4, 4, 12),
        );

        expect(startDate, DateTime(2026, 4));
      },
    );

    test(
      'falls back to the normalized fallback start date when no goal exists',
      () {
        final startDate = resolveCalorieBalanceCycleStartDate(
          settings: const CalorieGoalSettings.empty(),
          day: DateTime(2026, 4, 10, 14),
          fallbackStartDate: DateTime(2026, 4, 4, 18, 30),
        );

        expect(startDate, DateTime(2026, 4, 4));
      },
    );

    test(
      'uses the next goal start when the current day has no active goal yet',
      () {
        final settings = CalorieGoalSettings.single(
          dailyKcalGoal: 2300,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 4, 12, 18),
        );

        final startDate = resolveCalorieBalanceCycleStartDate(
          settings: settings,
          day: DateTime(2026, 4, 10, 14),
          fallbackStartDate: DateTime(2026, 4, 4, 12),
        );

        expect(startDate, DateTime(2026, 4, 12));
      },
    );
  });

  group('resolveCalorieBalanceCycleDayAdjustment', () {
    test('prorates the goal when the cycle starts partway through the day', () {
      final settings = CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 10, 18),
      );

      final adjustment = resolveCalorieBalanceCycleDayAdjustment(
        settings: settings,
        cycleStartDate: DateTime(2026, 4, 10),
        day: DateTime(2026, 4, 10, 21),
        dayEntries: const <CalorieEntry>[],
        dailyGoalKcal: 2000,
      );

      expect(adjustment, isNotNull);
      expect(adjustment!.paceWindowStart, DateTime(2026, 4, 10, 18));
      expect(adjustment.adjustedGoalKcal, closeTo(500, 0.000001));
    });

    test('returns null when the provided day is not the cycle start day', () {
      final settings = CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 10, 18),
      );

      final adjustment = resolveCalorieBalanceCycleDayAdjustment(
        settings: settings,
        cycleStartDate: DateTime(2026, 4, 10),
        day: DateTime(2026, 4, 11, 9),
        dayEntries: const <CalorieEntry>[],
        dailyGoalKcal: 2000,
      );

      expect(adjustment, isNull);
    });

    test('returns null when entries already exist before the goal change', () {
      final settings = CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 10, 18),
      );

      final adjustment = resolveCalorieBalanceCycleDayAdjustment(
        settings: settings,
        cycleStartDate: DateTime(2026, 4, 10),
        day: DateTime(2026, 4, 10, 20),
        dayEntries: <CalorieEntry>[_entryAt(DateTime(2026, 4, 10, 17, 30))],
        dailyGoalKcal: 2000,
      );

      expect(adjustment, isNull);
    });

    test(
      'returns null when the effective eating window length is non-positive',
      () {
        final goalEntry = CalorieGoalHistoryEntry(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 4, 10),
          changedAt: DateTime(2026, 4, 10, 18, 30),
        );
        final settings = _FixedWindowCalorieGoalSettings(
          goalHistory: <CalorieGoalHistoryEntry>[goalEntry],
          windowStart: DateTime(2026, 4, 10, 18),
          windowEnd: DateTime(2026, 4, 10, 18),
        );

        final adjustment = resolveCalorieBalanceCycleDayAdjustment(
          settings: settings,
          cycleStartDate: DateTime(2026, 4, 10),
          day: DateTime(2026, 4, 10, 20),
          dayEntries: const <CalorieEntry>[],
          dailyGoalKcal: 2000,
        );

        expect(adjustment, isNull);
      },
    );

    test(
      'returns a zero goal when the remaining eating window is already over',
      () {
        final settings = CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 4, 10, 23),
        );

        final adjustment = resolveCalorieBalanceCycleDayAdjustment(
          settings: settings,
          cycleStartDate: DateTime(2026, 4, 10),
          day: DateTime(2026, 4, 10, 23, 15),
          dayEntries: const <CalorieEntry>[],
          dailyGoalKcal: 2000,
        );

        expect(adjustment, isNotNull);
        expect(adjustment!.paceWindowStart, DateTime(2026, 4, 10, 23));
        expect(adjustment.adjustedGoalKcal, 0);
      },
    );
  });
}

CalorieEntry _entryAt(DateTime loggedAt) {
  return CalorieEntry.create(
    id: 'entry-${loggedAt.toIso8601String()}',
    userId: 'user-1',
    name: 'Meal',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 200,
    per100Protein: 10,
    per100Carbs: 20,
    per100Fat: 5,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

class _FixedWindowCalorieGoalSettings extends CalorieGoalSettings {
  _FixedWindowCalorieGoalSettings({
    required List<CalorieGoalHistoryEntry> goalHistory,
    required this.windowStart,
    required this.windowEnd,
  }) : assert(
         goalHistory.isNotEmpty,
         'goalHistory must contain at least one goal entry.',
       ),
       super(
         dailyKcalGoal: goalHistory.last.dailyKcalGoal,
         calculatorProfile: goalHistory.last.calculatorProfile,
         updatedAt: goalHistory.last.effectiveChangedAt,
         goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(goalHistory),
         eatingWindowStartMinuteOfDay: 0,
         eatingWindowEndMinuteOfDay: 1,
         pendingWeeklyCheckIn: null,
         skippedIntakeDayKeys: const <String>[],
       );

  final DateTime windowStart;
  final DateTime windowEnd;

  @override
  DateTime eatingWindowStartForDay(DateTime day) => windowStart;

  @override
  DateTime eatingWindowEndForDay(DateTime day) => windowEnd;
}
