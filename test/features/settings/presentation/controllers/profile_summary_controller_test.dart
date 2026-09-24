import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';
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

ProviderContainer _createContainer({
  required FakeCalorieSettingsRepository repository,
  String? displayName,
}) {
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      calorieSettingsRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => _now),
      userProfileProvider.overrideWith(
        (ref) => Stream.value(UserProfile(uid: 'u1', displayName: displayName)),
      ),
    ],
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
  test('combines name, body data, and macro goals of the profile', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 1800,
        calculatorProfile: _profile,
        effectiveDate: DateTime(2026, 9),
      ),
    );
    addTearDown(repository.dispose);
    final container = _createContainer(
      repository: repository,
      displayName: 'Alex',
    );

    final summary = await _settledSummary(container);

    expect(summary.name, 'Alex');
    expect(summary.profile, same(_profile));
    expect(summary.ageYears, 35);
    expect(summary.dailyKcalGoal, 1800);
    // Female without training days: 1.2 g protein and 0.9 g fat per kg.
    expect(summary.macroTarget?.proteinGrams, closeTo(72, 0.001));
    expect(summary.macroTarget?.fatGrams, closeTo(54, 0.001));
    expect(summary.macroTarget?.carbsGrams, closeTo(256.5, 0.001));
  });

  test('has no body data and no goals before a goal is set', () async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final container = _createContainer(repository: repository);

    final summary = await _settledSummary(container);

    expect(summary.name, isNull);
    expect(summary.profile, isNull);
    expect(summary.ageYears, isNull);
    expect(summary.dailyKcalGoal, isNull);
    expect(summary.macroTarget, isNull);
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

    await repository.saveSettings(
      CalorieGoalSettings.single(
        dailyKcalGoal: 1800,
        calculatorProfile: _profile,
        effectiveDate: DateTime(2026, 9),
      ),
    );
    await pumpEventQueue();

    expect(states.first, isA<AsyncLoading<ProfileSummaryState>>());
    expect(states.last.requireValue.dailyKcalGoal, 1800);
    expect(
      states.last.requireValue.macroTarget?.proteinGrams,
      closeTo(72, 0.001),
    );
  });
}
