import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';

import '../../../../helpers/profile_summary_source_overrides.dart';
import '../../../calories/support/fake_calories_repositories.dart';

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

CalorieGoalSettings _settingsWithGoal() {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 1800,
    calculatorProfile: _profile,
    effectiveDate: DateTime(2026, 9),
  );
}

ProviderContainer _createContainer({
  required FakeCalorieSettingsRepository repository,
  String? displayName,
  List<ManualHealthWeightEntry> weighIns = const [],
}) {
  final container = ProviderContainer(
    overrides: profileSummarySourceOverrides(
      settingsRepository: repository,
      now: _now,
      displayName: displayName,
      weighIns: weighIns,
    ),
  );
  addTearDown(container.dispose);
  return container;
}

Future<ProfileSummaryState> _settledSummary(ProviderContainer container) async {
  final subscription = container.listen(
    profileSummaryControllerProvider,
    (_, _) {},
  );
  addTearDown(subscription.close);
  await pumpEventQueue();
  final value = subscription.read();
  expect(value, isA<AsyncData<ProfileSummaryState>>());
  return value.requireValue;
}

void main() {
  test('combines account, body data, and weights', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal(),
    );
    addTearDown(repository.dispose);
    final container = _createContainer(
      repository: repository,
      displayName: 'Alex',
      weighIns: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 20), weightKg: 61.6),
        ManualHealthWeightEntry(day: DateTime(2026, 9, 22), weightKg: 61.2),
      ],
    );

    final summary = await _settledSummary(container);

    expect(summary.account, (name: 'Alex', email: null, isGuest: false));
    expect(summary.profile, same(_profile));
    expect(summary.ageYears, 35);
    expect(summary.weight?.latestWeighInKg, 61.2);
    expect(summary.weight?.latestWeighInDay, DateTime(2026, 9, 22));
    // 61.6 kg eases towards 61.2 kg by a tenth per day.
    expect(summary.weight?.trendWeightKg, closeTo(61.542, 0.0001));
    expect(summary.macroWeightKg, 60);
    expect(summary.macroWeightSince, DateTime(2026, 9));
    expect(summary.tdee, (
      kcal: CalorieGoalCalculator.calculate(_profile).tdeeKcal,
      isLearned: false,
    ));
  });

  test('has no weight without weigh-ins', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal(),
    );
    addTearDown(repository.dispose);
    final container = _createContainer(repository: repository);

    final summary = await _settledSummary(container);

    expect(summary.weight?.latestWeighInKg, isNull);
    expect(summary.weight?.trendWeightKg, isNull);
  });

  test('shows the macro weight of the latest weekly check-in', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal().copyWith(
        goalHistory: [
          ..._settingsWithGoal().goalHistory,
          CalorieGoalHistoryEntry(
            dailyKcalGoal: 1780,
            calculatorProfile: null,
            effectiveDate: DateTime(2026, 9, 22),
            changedAt: DateTime(2026, 9, 22),
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: DateTime(2026, 9, 15),
              windowEndDate: DateTime(2026, 9, 21),
              trendWeightChangePerDay: -0.05,
              lowConfidence: false,
              macroWeightKg: 58.9,
            ),
          ),
        ],
      ),
    );
    addTearDown(repository.dispose);
    final container = _createContainer(repository: repository);

    final summary = await _settledSummary(container);

    expect(summary.macroWeightKg, 58.9);
    expect(summary.macroWeightSince, DateTime(2026, 9, 22));
  });

  test('prefers the TDEE learned in the weekly check-in', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 1800,
        calculatorProfile: _profile,
        effectiveDate: DateTime(2026, 9, 21),
        source: CalorieGoalSource.weeklyCheckIn,
        weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
          windowStartDate: DateTime(2026, 9, 14),
          windowEndDate: DateTime(2026, 9, 20),
          trendWeightChangePerDay: -0.07,
          lowConfidence: false,
          calculatedTdeeKcal: 2310,
        ),
      ),
    );
    addTearDown(repository.dispose);
    final container = _createContainer(repository: repository);

    final summary = await _settledSummary(container);

    expect(summary.tdee, (kcal: 2310.0, isLearned: true));
  });

  test('has no body data and no goals before a goal is set', () async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final container = _createContainer(repository: repository);

    final summary = await _settledSummary(container);

    expect(summary.account.name, isNull);
    expect(summary.profile, isNull);
    expect(summary.ageYears, isNull);
    expect(summary.macroWeightKg, isNull);
    expect(summary.tdee, isNull);
  });

  test('follows a saved goal change', () async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final container = _createContainer(repository: repository);
    final states = <AsyncValue<ProfileSummaryState>>[];
    final subscription = container.listen(
      profileSummaryControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await pumpEventQueue();

    await repository.saveSettings(_settingsWithGoal());
    await pumpEventQueue();

    expect(states.first, isA<AsyncLoading<ProfileSummaryState>>());
    expect(states.last.requireValue.profile, same(_profile));
  });
}
