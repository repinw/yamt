import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/debug/calorie_debug_action_controller.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  test('printDebugDump returns success result', () async {
    final harness = _createHarness();
    addTearDown(harness.dispose);

    final result = await harness.controller.printDebugDump(
      DateTime(2026, 2, 25, 12),
    );

    expect(
      result,
      isA<CalorieDebugDumpPrintSuccess>().having(
        (result) => result.rowCount,
        'rowCount',
        greaterThan(0),
      ),
    );
  });

  test('printDebugDump returns failure result after exception', () async {
    final harness = _createHarness(
      logRepository: FakeCalorieLogRepository()
        ..onReadEntriesInRange = (_, _) async {
          throw StateError('debug dump failed');
        },
    );
    addTearDown(harness.dispose);

    final result = await harness.controller.printDebugDump(
      DateTime(2026, 2, 25, 12),
    );

    expect(result, isA<CalorieDebugDumpPrintFailure>());
  });

  test('printSettingsDebugDump returns success result', () async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 2, 25),
      ),
    );
    final harness = _createHarness(settingsRepository: settingsRepository);
    addTearDown(harness.dispose);

    final result = await harness.controller.printSettingsDebugDump();

    expect(
      result,
      isA<CalorieSettingsDebugDumpPrintSuccess>().having(
        (result) => result.entryCount,
        'entryCount',
        1,
      ),
    );
  });

  test('printWeeklyCheckInDebugDump returns success result', () async {
    final harness = _createHarness(
      overrides: [
        calorieWeeklyCheckInDataProvider.overrideWith(
          (ref) => _weeklyCheckInData(),
        ),
      ],
    );
    addTearDown(harness.dispose);

    final result = await harness.controller.printWeeklyCheckInDebugDump();

    expect(result, isA<CalorieWeeklyCheckInDebugDumpPrintSuccess>());
  });

  test('printWeeklyCheckInDebugDump returns failure result', () async {
    final harness = _createHarness(
      overrides: [
        calorieWeeklyCheckInDataProvider.overrideWith((ref) {
          throw StateError('weekly check-in dump failed');
        }),
      ],
    );
    addTearDown(harness.dispose);

    final result = await harness.controller.printWeeklyCheckInDebugDump();

    expect(result, isA<CalorieWeeklyCheckInDebugDumpPrintFailure>());
  });
}

_CaloriePageActionHarness _createHarness({
  FakeCalorieLogRepository? logRepository,
  FakeCalorieSettingsRepository? settingsRepository,
  List<Override> overrides = const <Override>[],
}) {
  final resolvedLogRepository = logRepository ?? FakeCalorieLogRepository();
  final resolvedSettingsRepository =
      settingsRepository ?? FakeCalorieSettingsRepository();
  final container = ProviderContainer(
    overrides: [
      calorieLogRepositoryProvider.overrideWithValue(resolvedLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        resolvedSettingsRepository,
      ),
      diaryHealthServiceProvider.overrideWithValue(FakeDiaryHealthService({})),
      healthConnectionServiceProvider.overrideWithValue(
        FakeHealthConnectionService(
          const HealthConnectionStatus.unsupported(),
        ),
      ),
      healthWeightServiceProvider.overrideWithValue(
        FakeHealthWeightService([]),
      ),
      manualHealthWeightRepositoryProvider.overrideWithValue(
        FakeManualHealthWeightRepository([]),
      ),
      ...overrides,
    ],
  );
  return _CaloriePageActionHarness(
    container: container,
    logRepository: resolvedLogRepository,
    settingsRepository: resolvedSettingsRepository,
  );
}

class _CaloriePageActionHarness {
  _CaloriePageActionHarness({
    required this.container,
    required this.logRepository,
    required this.settingsRepository,
  });

  final ProviderContainer container;
  final FakeCalorieLogRepository logRepository;
  final FakeCalorieSettingsRepository settingsRepository;

  CalorieDebugActionController get controller {
    return container.read(calorieDebugActionControllerProvider.notifier);
  }

  Future<void> dispose() async {
    await logRepository.dispose();
    await settingsRepository.dispose();
    container.dispose();
  }
}

CalorieWeeklyCheckInData _weeklyCheckInData() {
  final windowStartDate = DateTime(2026, 2, 18);
  final windowEndDate = DateTime(2026, 2, 24);
  final dueDate = DateTime(2026, 2, 25);
  final pendingWeeklyCheckIn = PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: windowStartDate,
    windowEndDate: windowEndDate,
    dueDate: dueDate,
  );

  return CalorieWeeklyCheckInData(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    cacheWeeklyCheckIn: pendingWeeklyCheckIn.copyWith(
      dismissedAt: DateTime(2026, 2, 25, 8),
    ),
    shouldAutoOpen: true,
    days: [
      CalorieWeeklyCheckInWindowDay(
        day: windowStartDate,
        hasEntries: true,
        loggedIntakeKcal: 2100,
        resolvedIntakeKcal: 2100,
        isSkippedIntakeDay: false,
        isHeartDay: false,
        activeKcal: 320,
        weightKg: 80.2,
      ),
      CalorieWeeklyCheckInWindowDay(
        day: windowStartDate.add(const Duration(days: 1)),
        hasEntries: false,
        loggedIntakeKcal: 0,
        resolvedIntakeKcal: null,
        isSkippedIntakeDay: true,
        isHeartDay: true,
        activeKcal: 180,
        weightKg: null,
      ),
    ],
    calculation: const CalorieWeeklyCheckInCalculation(
      trendWeightChangePerDay: -0.05,
      averageIntakeKcal: 2150,
      measuredTrueTdeeKcal: 2500,
      calculatedTrueTdeeKcal: 2450,
      newGoalKcal: 2200,
      lastWeekAverageActiveKcal: 300,
      todayActiveKcal: 350,
      activityDeltaKcal: 25,
      dynamicGoalTodayKcal: 2225,
    ),
    blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
    missingIntakeDays: [windowStartDate.add(const Duration(days: 1))],
    missingWeightDays: [windowEndDate],
    freshness: CalorieLearnedTdeeFreshness.urgent,
    latestLearnedTdeeAt: DateTime(2026, 2, 1, 9),
    lowConfidence: true,
    inputHash: 'weekly-input-hash',
  );
}
