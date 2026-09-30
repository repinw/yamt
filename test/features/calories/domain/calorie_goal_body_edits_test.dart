import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_body_edit.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_body_edits.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_learned_transitions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';

final _goalStart = DateTime(2026, 9);
final _now = DateTime(2026, 9, 10, 9);

final CalorieCalculatorProfile _profile =
    const CalorieCalculatorProfile.defaults().copyWith(
      weightKg: 85,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
      targetWeightKg: 75,
    );

double _kcalOf(CalorieCalculatorProfile profile) {
  return CalorieGoalCalculator.calculate(profile).finalGoalKcal;
}

CalorieGoalSettings _calculatedGoal() {
  return CalorieGoalSettings.single(
    dailyKcalGoal: _kcalOf(_profile),
    calculatorProfile: _profile,
    effectiveDate: _goalStart,
    source: CalorieGoalSource.calculator,
  );
}

CalorieGoalSettings _withCheckIn(
  CalorieGoalSettings settings, {
  required double dailyKcalGoal,
  required bool isRejected,
}) {
  return settings.applyWeeklyCheckInGoal(
    completedAt: DateTime(2026, 9, 8),
    dailyKcalGoal: dailyKcalGoal,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: _goalStart,
      windowEndDate: DateTime(2026, 9, 7),
      trendWeightChangePerDay: -0.05,
      lowConfidence: false,
      calculatedTdeeKcal: 2600,
      inputHash: 'hash',
      isRejected: isRejected,
      measuredTdeeKcal: 0,
      baseGoalKcal: 0,
    ),
  );
}

void main() {
  group('without a learned TDEE', () {
    test('a height edit corrects the calculated goal from its start', () {
      final oldKcal = _kcalOf(_profile);
      final settings = _withCheckIn(
        _calculatedGoal(),
        dailyKcalGoal: oldKcal,
        isRejected: true,
      );
      final newKcal = _kcalOf(_profile.copyWith(heightCm: 190));

      expect(settings.bodyEditReach(_now), CalorieBodyEditReach.goalCorrection);
      expect(settings.bodyCorrectionStart(_now), _goalStart);

      final next = settings.applyBodyEdit(
        const CalorieHeightEdit(190),
        now: _now,
      );

      final history = next.sortedGoalHistory;
      expect(history.first.calculatorProfile?.heightCm, 190);
      expect(history.first.dailyKcalGoal, newKcal);
      expect(history.last.isWeeklyCheckIn, isTrue);
      expect(history.last.dailyKcalGoal, newKcal);
      expect(next.dailyKcalGoal, newKcal);
      expect(next.calculatorProfile?.heightCm, 190);
      expect(next.baseGoalKcalForDay(_now), newKcal);
      expect(newKcal, isNot(oldKcal));
    });

    test('a birthday edit takes the age at the goal start', () {
      final next = _calculatedGoal().applyBodyEdit(
        CalorieBirthDateEdit(DateTime(1996, 9, 5)),
        now: _now,
      );

      expect(next.goalHistory.single.calculatorProfile?.ageYears, 29);
      expect(next.calculatorProfile?.ageYears, 30);
      expect(next.calculatorProfile?.birthDate, DateTime(1996, 9, 5));
    });

    test('the start weight may change', () {
      final settings = _calculatedGoal();

      expect(settings.canEditStartWeight, isTrue);
      final next = settings.applyBodyEdit(
        const CalorieStartWeightEdit(83),
        now: _now,
      );
      expect(next.goalHistory.single.calculatorProfile?.weightKg, 83);
      expect(next.macroWeightKgForDay(_now), 83);
    });
  });

  group('with a learned TDEE', () {
    test('a sex edit keeps the calorie goal and the history', () {
      final settings = _withCheckIn(
        _calculatedGoal(),
        dailyKcalGoal: 2200,
        isRejected: false,
      );

      expect(settings.bodyEditReach(_now), CalorieBodyEditReach.learnedTdee);
      expect(settings.bodyCorrectionStart(_now), isNull);

      final next = settings.applyBodyEdit(
        const CalorieSexEdit(CalorieCalculatorSex.female),
        now: _now,
      );

      expect(next.calculatorProfile?.sex, CalorieCalculatorSex.female);
      expect(identical(next.goalHistory, settings.goalHistory), isTrue);
      expect(next.dailyKcalGoal, settings.dailyKcalGoal);
      expect(next.baseGoalKcalForDay(_now), 2200);
    });

    test('the start weight stays', () {
      final settings = _withCheckIn(
        _calculatedGoal(),
        dailyKcalGoal: 2200,
        isRejected: false,
      );

      expect(settings.canEditStartWeight, isFalse);
      expect(
        () =>
            settings.applyBodyEdit(const CalorieStartWeightEdit(83), now: _now),
        throwsStateError,
      );
    });
  });

  test('a goal set by hand only takes the edit in the profile', () {
    final settings = CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: _goalStart,
    ).copyWith(calculatorProfile: _profile);

    expect(settings.bodyEditReach(_now), CalorieBodyEditReach.manualGoal);
    final next = settings.applyBodyEdit(
      const CalorieHeightEdit(170),
      now: _now,
    );
    expect(next.calculatorProfile?.heightCm, 170);
    expect(next.baseGoalKcalForDay(_now), 2000);
  });

  test('without a goal the edit only reaches the profile', () {
    final settings = const CalorieGoalSettings.empty().copyWith(
      calculatorProfile: _profile,
    );

    expect(settings.bodyEditReach(_now), CalorieBodyEditReach.noGoal);
    final next = settings.applyBodyEdit(
      const CalorieHeightEdit(170),
      now: _now,
    );
    expect(next.calculatorProfile?.heightCm, 170);
    expect(next.hasGoal, isFalse);
  });
}
