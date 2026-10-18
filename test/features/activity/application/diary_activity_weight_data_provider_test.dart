import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../../calories/support/fake_calories_repositories.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  test('shows the weights of all devices without activity data', () async {
    final previousDay = selectedDay.subtract(const Duration(days: 1));
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        calorieGoalControllerProvider.overrideWith(
          () => _FakeCalorieGoalController(
            CalorieGoalSettings.single(
              dailyKcalGoal: 2200,
              calculatorProfile: const CalorieCalculatorProfile.defaults(),
              effectiveDate: selectedDay,
            ),
          ),
        ),
        healthWeightSamplesProvider.overrideWith(
          (ref) => Stream.value([
            HealthWeightSample(
              recordedAt: selectedDay.add(const Duration(hours: 7)),
              weightKg: 77.1,
            ),
          ]),
        ),
        manualHealthWeightRepositoryProvider.overrideWith(
          (ref) => FakeManualHealthWeightRepository([
            ManualHealthWeightEntry(day: selectedDay, weightKg: 76.8),
            ManualHealthWeightEntry(day: previousDay, weightKg: 77.4),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final data = await container
        .listen(diaryActivityWeightDataProvider(selectedDay).future, (_, _) {})
        .read();

    expect(data.profileWeightKg, 80);
    expect(data.hasSelectedDayWeight, isTrue);
    expect(data.weightTrend[5], 77.4);
    // The median of the manual weight and the cloud sample of that day.
    expect(data.weightTrend.last, closeTo(76.95, 1e-9));
  });
}

class _FakeCalorieGoalController extends CalorieGoalController {
  new(this.settings);

  final CalorieGoalSettings settings;

  @override
  CalorieGoalSettings build() => settings;
}
