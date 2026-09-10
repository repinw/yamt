import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../../calories/support/fake_calories_repositories.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  test('combines Health and manual weights without activity data', () async {
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
        healthConnectionServiceProvider.overrideWith(
          (ref) => FakeHealthConnectionService(_readyHealthStatus),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService([
            HealthWeightSample(
              recordedAt: selectedDay.add(const Duration(hours: 7)),
              weightKg: 77.1,
              uuid: 'selected-health-weight',
              sourcePackageName: 'de.yamt.app',
              isFromThisApp: true,
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

    final data = await container.read(
      diaryActivityWeightDataProvider(selectedDay).future,
    );

    expect(data.profileWeightKg, 80);
    expect(data.selectedWeightKg, 76.8);
    expect(data.hasSelectedDayWeight, isTrue);
    expect(data.weightTrend[5], 77.4);
    expect(data.weightTrend.last, 76.8);
    expect(data.weightDays.last.canDeleteWeight, isTrue);
  });
}

class _FakeCalorieGoalController extends CalorieGoalController {
  _FakeCalorieGoalController(this.settings);

  final CalorieGoalSettings settings;

  @override
  CalorieGoalSettings build() => settings;
}

const _readyHealthStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);
