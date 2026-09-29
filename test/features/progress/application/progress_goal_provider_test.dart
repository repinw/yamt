import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/progress/application/progress_goal_provider.dart';
import 'package:yamt/features/progress/domain/progress_goal.dart';

import '../../../helpers/profile_summary_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

final _now = DateTime(2026, 9, 24, 10);

final _profile = CalorieCalculatorProfile(
  sex: CalorieCalculatorSex.female,
  weightKg: 60,
  heightCm: 165,
  ageYears: 30,
  birthDate: DateTime(1990, 10, 2),
  activityLevel: 1.4,
  goalMode: CalorieGoalMode.lose,
  goalSpeedKgPerWeek: 0.5,
  targetWeightKg: 55,
);

Future<ProgressGoal> _goal({
  CalorieGoalSettings? settings,
  List<ManualHealthWeightEntry> weighIns = const [],
}) async {
  final repository = FakeCalorieSettingsRepository(initialSettings: settings);
  addTearDown(repository.dispose);
  final container = ProviderContainer(
    overrides: profileSummarySourceOverrides(
      settingsRepository: repository,
      now: _now,
      weighIns: weighIns,
    ),
  );
  addTearDown(container.dispose);
  final subscription = container.listen(progressGoalProvider, (_, _) {});
  addTearDown(subscription.close);
  await pumpEventQueue();
  return subscription.read().requireValue;
}

void main() {
  test('combines the goal, the trend weight, and the macro targets', () async {
    final goal = await _goal(
      settings: CalorieGoalSettings.single(
        dailyKcalGoal: 1800,
        calculatorProfile: _profile,
        effectiveDate: DateTime(2026, 9),
      ),
      weighIns: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 20), weightKg: 61.6),
        ManualHealthWeightEntry(day: DateTime(2026, 9, 22), weightKg: 61.2),
      ],
    );

    expect(goal.profile, same(_profile));
    // 61.6 kg eases towards 61.2 kg by a tenth per day.
    expect(goal.currentWeightKg, closeTo(61.542, 0.0001));
    expect(goal.kgToTarget, closeTo(6.542, 0.0001));
    expect(goal.share, 0);
    expect(goal.kgPastStart, closeTo(1.542, 0.0001));
    expect(goal.dailyKcalGoal, 1800);
    // Female losing weight without training days: 1.6 g/kg (96 g) is below
    // 30 % of the 1800 kcal goal, so protein rises to 135 g.
    expect(goal.macroTarget?.proteinGrams, closeTo(1800 * 0.30 / 4, 0.001));
    // (1800 − 135 × 4 − 54 × 9) / 4 = 193.5 g carbs, capped at 40 % = 180 g.
    // Protein is above 2.0 g/kg, so the 54 kcal excess goes to fat.
    expect(goal.macroTarget?.fatGrams, closeTo(60, 0.001));
    expect(goal.macroTarget?.carbsGrams, closeTo(180, 0.001));
  });

  test('has no past-start value while the weight is on the way', () async {
    final goal = await _goal(
      settings: CalorieGoalSettings.single(
        dailyKcalGoal: 1800,
        calculatorProfile: _profile,
        effectiveDate: DateTime(2026, 9),
      ),
      weighIns: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 24), weightKg: 58),
      ],
    );

    expect(goal.share, closeTo(0.4, 0.0001));
    expect(goal.kgPastStart, isNull);
  });

  test('has no weight share without weigh-ins', () async {
    final goal = await _goal(
      settings: CalorieGoalSettings.single(
        dailyKcalGoal: 1800,
        calculatorProfile: _profile,
        effectiveDate: DateTime(2026, 9),
      ),
    );

    expect(goal.currentWeightKg, isNull);
    expect(goal.kgToTarget, isNull);
    expect(goal.share, isNull);
  });

  test('has no targets without a goal', () async {
    final goal = await _goal();

    expect(goal.profile, isNull);
    expect(goal.dailyKcalGoal, isNull);
    expect(goal.macroTarget, isNull);
  });
}
