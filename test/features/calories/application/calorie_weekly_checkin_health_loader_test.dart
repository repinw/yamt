import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_health_loader.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

import '../support/fake_calories_repositories.dart';

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

void main() {
  test('loads health weights for weekly check-in', () async {
    final start = DateTime(2026, 4, 8);
    final secondDay = nextDiaryDay(start);
    final dates = _dates(start: start, secondDay: secondDay);
    final healthWeightService = FakeHealthWeightService([
      HealthWeightSample(recordedAt: addDiaryDays(start, -1), weightKg: 85),
      HealthWeightSample(
        recordedAt: start.add(const Duration(hours: 8)),
        weightKg: 80,
      ),
      HealthWeightSample(
        recordedAt: start.add(const Duration(hours: 20)),
        weightKg: 82,
      ),
    ]);

    final data = await loadCalorieWeeklyCheckInHealthData(
      healthStatusFuture: Future<HealthConnectionStatus>.value(_readyStatus),
      healthWeightService: healthWeightService,
      dates: dates,
      isMounted: () => true,
    );

    // Samples before the learning start are not loaded.
    expect(data.healthWeightSamples.map((sample) => sample.weightKg), [80, 82]);
  });

  test('returns empty health data when access is unavailable', () async {
    final start = DateTime(2026, 4, 8);
    final secondDay = nextDiaryDay(start);
    final data = await loadCalorieWeeklyCheckInHealthData(
      healthStatusFuture: Future<HealthConnectionStatus>.value(
        const HealthConnectionStatus.unsupported(),
      ),
      healthWeightService: FakeHealthWeightService(const []),
      dates: _dates(start: start, secondDay: secondDay),
      isMounted: () => true,
    );

    expect(data.healthWeightSamples, isEmpty);
  });

  test('throws before service reads when provider is disposed', () async {
    final start = DateTime(2026, 4, 8);
    final secondDay = nextDiaryDay(start);
    final healthWeightService = FakeHealthWeightService(const []);

    expect(
      () => loadCalorieWeeklyCheckInHealthData(
        healthStatusFuture: Future<HealthConnectionStatus>.value(_readyStatus),
        healthWeightService: healthWeightService,
        dates: _dates(start: start, secondDay: secondDay),
        isMounted: () => false,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

CalorieWeeklyCheckInWindowDates _dates({
  required DateTime start,
  required DateTime secondDay,
}) {
  final end = addDiaryDays(start, 6);
  return CalorieWeeklyCheckInWindowDates(
    pendingWeeklyCheckIn: PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: start,
      windowEndDate: end,
      dueDate: nextDiaryDay(end),
    ),
    anchorEntry: null,
    anchorWeightSourceDay: null,
    learningStartDate: start,
    learningDays: [start, secondDay],
    windowDays: [start, secondDay],
    learningPreviousBoundaryDay: previousDiaryDay(start),
    shouldUseLearningPreviousBoundary: false,
    isFirstWindow: true,
    previousBoundaryDay: null,
    nextBoundaryDay: nextDiaryDay(end),
  );
}
