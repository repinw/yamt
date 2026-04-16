import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';

void main() {
  test('calculates weekly check-in metrics from full 7-day data', () {
    final result = CalorieWeeklyCheckInCalculator.calculate(
      previousGoalKcal: 2427,
      intakeKcalByDay: const <double>[2753, 2975, 906, 2745, 2040, 1811, 3200],
      lastWeekActiveKcalByDay: const <int>[0, 16, 21, 569, 495, 455, 492],
      todayActiveKcal: 150,
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

    expect(result.trendWeightChangePerDay, closeTo(-0.08036, 0.00001));
    expect(result.averageIntakeKcal, closeTo(2347.14, 0.01));
    expect(result.calculatedTrueTdeeKcal, closeTo(2909.64, 0.01));
    expect(result.newGoalKcal, closeTo(2571.79, 0.01));
    expect(result.lastWeekAverageActiveKcal, closeTo(292.57, 0.01));
    expect(result.activityDeltaKcal, 0);
    expect(result.dynamicGoalTodayKcal, closeTo(2571.79, 0.01));
  });

  test('caps weekly goal movement to keep one check-in stable', () {
    final result = CalorieWeeklyCheckInCalculator.calculate(
      previousGoalKcal: 2200,
      intakeKcalByDay: const <double>[2000, 2000, 2000, 2000, 2000, 2000, 2000],
      lastWeekActiveKcalByDay: const <int>[0, 0, 0, 0, 0, 0, 0],
      todayActiveKcal: 0,
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

    expect(result.calculatedTrueTdeeKcal, closeTo(5500, 0.01));
    expect(result.newGoalKcal, 2400);
  });

  test('does not lower dynamic today goal when activity is below baseline', () {
    final result = CalorieWeeklyCheckInCalculator.calculate(
      previousGoalKcal: 1600,
      intakeKcalByDay: const <double>[1600, 1600, 1600, 1600, 1600, 1600, 1600],
      lastWeekActiveKcalByDay: const <int>[800, 800, 800, 800, 800, 800, 800],
      todayActiveKcal: 0,
      weightPoints: const <CalorieWeeklyCheckInWeightPoint>[
        CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 80),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 6, weightKg: 80),
      ],
    );

    expect(result.activityDeltaKcal, 0);
    expect(result.dynamicGoalTodayKcal, 1600);
  });

  test(
    'clamps dynamic today goal to minimum floor when stored goal is lower',
    () {
      final result = CalorieWeeklyCheckInCalculator.calculate(
        previousGoalKcal: 1400,
        intakeKcalByDay: const <double>[
          1400,
          1400,
          1400,
          1400,
          1400,
          1400,
          1400,
        ],
        lastWeekActiveKcalByDay: const <int>[0, 0, 0, 0, 0, 0, 0],
        todayActiveKcal: 0,
        weightPoints: const <CalorieWeeklyCheckInWeightPoint>[
          CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 80),
          CalorieWeeklyCheckInWeightPoint(dayIndex: 6, weightKg: 80),
        ],
      );

      expect(result.activityDeltaKcal, 0);
      expect(result.dynamicGoalTodayKcal, minimumResolvedDailyCalorieGoalKcal);
    },
  );

  test('calculates manual rerun goal from learned TDEE', () {
    expect(
      CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
        learnedTdeeKcal: 2500,
        goalSpeedKgPerWeek: 0.5,
        isLosing: true,
        isGaining: false,
      ),
      closeTo(2000, 0.01),
    );
    expect(
      CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
        learnedTdeeKcal: 2500,
        goalSpeedKgPerWeek: 0.25,
        isLosing: false,
        isGaining: true,
      ),
      closeTo(2750, 0.01),
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
