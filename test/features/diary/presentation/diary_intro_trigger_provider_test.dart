import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/diary/application/diary_intro_trigger_provider.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart'
    show
        DiaryWeeklyCheckInData,
        diaryCalorieGoalSettingsProvider,
        diaryWeeklyCheckInDataProvider;
import 'package:yamt/features/diary/domain/diary_intro_preferences.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../../calories/support/fake_calories_repositories.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  test('emits intro trigger for unseen calculator goal', () async {
    final preferences = MemoryAppPreferences();
    final container = _createContainer(
      preferences: preferences,
      settings: _calculatorSettings(selectedDay),
      healthStatus: const HealthConnectionStatus(
        platform: HealthPlatform.ios,
        healthConnectAvailability: HealthConnectAvailability.notApplicable,
        permissionState: HealthPermissionState.granted,
        historyAccess: HealthHistoryAccess.notApplicable,
      ),
    );
    await _primeIntroDependencies(container);

    final trigger = container.read(
      diaryIntroTriggerProvider,
    );

    expect(trigger, isNotNull);
    expect(trigger?.preferences, same(preferences));
    expect(trigger?.introData.targetKcal, 1200);
    expect(trigger?.healthStatus?.accessState, HealthDataAccessState.ready);
  });

  test('returns null when intro was already completed', () async {
    final healthService = _CountingHealthConnectionService(
      const HealthConnectionStatus.unsupported(),
    );
    final container = _createContainer(
      preferences: MemoryAppPreferences(
        initialStrings: DiaryIntroPreferences.initialSeenStrings(),
      ),
      settings: _calculatorSettings(selectedDay),
      healthConnectionService: healthService,
    );
    await _primeIntroDependencies(container, primeHealth: false);

    expect(container.read(diaryIntroTriggerProvider), isNull);
    expect(healthService.loadStatusCallCount, 0);
  });

  test('returns null after TDEE was learned', () async {
    final healthService = _CountingHealthConnectionService(
      const HealthConnectionStatus.unsupported(),
    );
    final container = _createContainer(
      settings: _learnedTdeeGoalSettings(selectedDay),
      healthConnectionService: healthService,
    );
    await _primeIntroDependencies(container, primeHealth: false);

    expect(container.read(diaryIntroTriggerProvider), isNull);
    expect(healthService.loadStatusCallCount, 0);
  });

  test('returns null while weekly check-in auto-opens', () async {
    final healthService = _CountingHealthConnectionService(
      const HealthConnectionStatus.unsupported(),
    );
    final container = _createContainer(
      settings: _calculatorSettings(selectedDay),
      healthConnectionService: healthService,
      weeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: selectedDay.subtract(const Duration(days: 7)),
      ),
    );
    await _primeIntroDependencies(container, primeHealth: false);

    expect(container.read(diaryIntroTriggerProvider), isNull);
    expect(healthService.loadStatusCallCount, 0);
  });
}

ProviderContainer _createContainer({
  required CalorieGoalSettings settings,
  AppPreferences? preferences,
  HealthConnectionStatus healthStatus =
      const HealthConnectionStatus.unsupported(),
  FakeHealthConnectionService? healthConnectionService,
  DiaryWeeklyCheckInData? weeklyCheckIn,
}) {
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: settings,
  );
  final container = ProviderContainer(
    overrides: <Override>[
      appPreferencesProvider.overrideWithValue(
        preferences ?? MemoryAppPreferences(),
      ),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      healthConnectionServiceProvider.overrideWithValue(
        healthConnectionService ?? FakeHealthConnectionService(healthStatus),
      ),
      diaryWeeklyCheckInDataProvider.overrideWith(
        (ref) => weeklyCheckIn ?? _emptyWeeklyCheckInCheckInData(),
      ),
    ],
  );
  addTearDown(() async {
    await settingsRepository.dispose();
    container.dispose();
  });
  return container;
}

Future<void> _primeIntroDependencies(
  ProviderContainer container, {
  bool primeHealth = true,
}) async {
  await container.read(diaryCalorieGoalSettingsProvider.future);
  if (primeHealth) {
    await container.read(healthConnectionControllerProvider.future);
  }
  await container.read(diaryWeeklyCheckInDataProvider.future);
}

class _CountingHealthConnectionService extends FakeHealthConnectionService {
  _CountingHealthConnectionService(super.status);

  int loadStatusCallCount = 0;

  @override
  Future<HealthConnectionStatus> loadStatus() async {
    loadStatusCallCount += 1;
    return super.loadStatus();
  }
}

CalorieGoalSettings _calculatorSettings(DateTime effectiveDate) {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 1200,
    calculatorProfile: const CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 59,
      heightCm: 162,
      ageYears: 24,
      activityLevel: 1.2,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
    ),
    effectiveDate: effectiveDate,
  );
}

CalorieGoalSettings _learnedTdeeGoalSettings(DateTime effectiveDate) {
  const profile = CalorieCalculatorProfile.defaults();
  return CalorieGoalSettings.single(
    dailyKcalGoal: 1800,
    calculatorProfile: profile,
    effectiveDate: effectiveDate.subtract(const Duration(days: 8)),
    source: CalorieGoalSource.calculator,
  ).applyGoalChange(
    changedAt: effectiveDate.subtract(const Duration(days: 1)),
    dailyKcalGoal: 1800,
    calculatorProfile: profile,
    source: CalorieGoalSource.weeklyCheckIn,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: effectiveDate.subtract(const Duration(days: 8)),
      windowEndDate: effectiveDate.subtract(const Duration(days: 2)),
      trendWeightChangePerDay: -0.05,
      calculatedTrueTdeeKcal: 2100,
      averageActiveKcal: 120,
      lowConfidence: false,
    ),
  );
}

DiaryWeeklyCheckInData _emptyWeeklyCheckInCheckInData() {
  return const DiaryWeeklyCheckInData(
    pendingWeeklyCheckIn: null,
    shouldAutoOpen: false,
    days: <CalorieWeeklyCheckInWindowDay>[],
    calculation: null,
    blockedReason: null,
    missingIntakeDays: <DateTime>[],
    missingWeightDays: <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}

DiaryWeeklyCheckInData _weeklyCheckInCheckInData({
  required DateTime windowStartDate,
}) {
  return DiaryWeeklyCheckInData(
    pendingWeeklyCheckIn: PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: windowStartDate,
      windowEndDate: windowStartDate.add(const Duration(days: 6)),
      dueDate: windowStartDate.add(const Duration(days: 7)),
    ),
    shouldAutoOpen: true,
    days: const <CalorieWeeklyCheckInWindowDay>[],
    calculation: null,
    blockedReason: null,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: const <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}
