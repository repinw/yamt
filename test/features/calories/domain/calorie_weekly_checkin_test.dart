import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';

void main() {
  test('calculates weekly check-in metrics from full 7-day data', () {
    final result = CalorieWeeklyCheckInCalculator.calculate(
      previousGoalKcal: 2427,
      previousLearnedTdeeKcal: 2427,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
      intakeKcalByDay: const <double>[2753, 2975, 906, 2745, 2040, 1811, 3200],
      weightPoints: const <CalorieWeeklyCheckInWeightPoint>[
        CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 84.05),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 1, weightKg: 84.14),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 2, weightKg: 83.55),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 3, weightKg: 81.70),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 4, weightKg: 83.65),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 5, weightKg: 83),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 6, weightKg: 83.75),
      ],
    );

    // Theil-Sen ignores the 81.70 kg outlier on day 3.
    expect(result.trendWeightChangePerDay, closeTo(-0.1, 0.00001));
    expect(result.averageIntakeKcal, closeTo(2347.14, 0.01));
    expect(result.measuredTotalTdeeKcal, closeTo(3117.14, 0.01));
    expect(result.measuredBaseTdeeKcal, closeTo(3117.14, 0.01));
    // A 7-day window enters with 0.5 × 7 / 28 = 0.125.
    expect(result.calculatedBaseTdeeKcal, closeTo(2513.27, 0.01));
    expect(result.newBaseGoalKcal, closeTo(2513.27, 0.01));
    expect(result.dynamicGoalTodayKcal, closeTo(2513.27, 0.01));
  });

  test('caps weekly goal movement to keep one check-in stable', () {
    final result = CalorieWeeklyCheckInCalculator.calculate(
      previousGoalKcal: 2200,
      previousLearnedTdeeKcal: 2200,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
      intakeKcalByDay: const <double>[2000, 2000, 2000, 2000, 2000, 2000, 2000],
      weightPoints: const <CalorieWeeklyCheckInWeightPoint>[
        CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 90),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 1, weightKg: 89.5),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 2, weightKg: 89),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 3, weightKg: 88.5),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 4, weightKg: 88),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 5, weightKg: 87.5),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 6, weightKg: 87),
      ],
    );

    expect(result.measuredTrueTdeeKcal, closeTo(5850, 0.01));
    expect(result.calculatedTrueTdeeKcal, closeTo(2656.25, 0.01));
    expect(result.newGoalKcal, 2400);
  });

  test('calculates first starter run from 6 normal tracked days', () {
    final result = CalorieWeeklyCheckInCalculator.calculate(
      previousGoalKcal: 2200,
      previousLearnedTdeeKcal: 2200,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
      intakeKcalByDay: const <double>[2000, 2000, 2000, 2000, 2000, 2000],
      weightPoints: const <CalorieWeeklyCheckInWeightPoint>[
        CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 80),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 5, weightKg: 79.5),
      ],
    );

    expect(result.trendWeightChangePerDay, closeTo(-0.1, 0.00001));
    expect(result.averageIntakeKcal, 2000);
    expect(result.measuredTrueTdeeKcal, closeTo(2770, 0.01));
    expect(result.measuredBaseTdeeKcal, closeTo(2770, 0.01));
    // A 6-day window enters with 0.5 × 6 / 28.
    expect(result.calculatedBaseTdeeKcal, closeTo(2261.07, 0.01));
    expect(result.newBaseGoalKcal, closeTo(2261.07, 0.01));
    expect(result.dynamicGoalTodayKcal, closeTo(2261.07, 0.01));
  });

  test('stable weight keeps learned Base-TDEE at intake', () {
    final result = CalorieWeeklyCheckInCalculator.calculate(
      previousGoalKcal: 1600,
      previousLearnedTdeeKcal: 1600,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
      intakeKcalByDay: const <double>[1600, 1600, 1600, 1600, 1600, 1600, 1600],
      weightPoints: const <CalorieWeeklyCheckInWeightPoint>[
        CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 80),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 6, weightKg: 80),
      ],
    );

    expect(result.measuredBaseTdeeKcal, closeTo(1600, 0.01));
    expect(result.dynamicGoalTodayKcal, closeTo(1600, 0.01));
  });

  test(
    'clamps dynamic today goal to minimum floor when stored goal is lower',
    () {
      final result = CalorieWeeklyCheckInCalculator.calculate(
        previousGoalKcal: 1100,
        previousLearnedTdeeKcal: 1100,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
        intakeKcalByDay: const <double>[
          1100,
          1100,
          1100,
          1100,
          1100,
          1100,
          1100,
        ],
        weightPoints: const <CalorieWeeklyCheckInWeightPoint>[
          CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 80),
          CalorieWeeklyCheckInWeightPoint(dayIndex: 6, weightKg: 80),
        ],
      );

      expect(result.dynamicGoalTodayKcal, minimumResolvedDailyCalorieGoalKcal);
    },
  );

  test('keeps target mode separate from learned maintenance tdee', () {
    final result = CalorieWeeklyCheckInCalculator.calculate(
      previousGoalKcal: 2000,
      previousLearnedTdeeKcal: 2500,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
      intakeKcalByDay: const <double>[2500, 2500, 2500, 2500, 2500, 2500, 2500],
      weightPoints: const <CalorieWeeklyCheckInWeightPoint>[
        CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 80),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 6, weightKg: 80),
      ],
    );

    expect(result.measuredTrueTdeeKcal, 2500);
    expect(result.calculatedTrueTdeeKcal, 2500);
    expect(result.newGoalKcal, 1950);
  });

  test('calculates manual rerun goal from learned TDEE', () {
    expect(
      CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
        learnedTdeeKcal: 2500,
        goalSpeedKgPerWeek: 0.5,
        isLosing: true,
        isGaining: false,
      ),
      closeTo(1950, 0.01),
    );
    expect(
      CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
        learnedTdeeKcal: 2500,
        goalSpeedKgPerWeek: 0.25,
        isLosing: false,
        isGaining: true,
      ),
      closeTo(2775, 0.01),
    );
    expect(
      CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
        learnedTdeeKcal: 2500,
        goalSpeedKgPerWeek: 0,
        isLosing: false,
        isGaining: false,
      ),
      2500,
    );
  });
}
