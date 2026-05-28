import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_health_loader.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
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
  test(
    'loads health weights and aggregate activity for weekly check-in',
    () async {
      final start = DateTime(2026, 4, 8);
      final secondDay = nextDiaryDay(start);
      final today = DateTime(2026, 4, 15);
      final dates = _dates(start: start, secondDay: secondDay);
      final diaryHealthService = FakeTrendDiaryHealthService(
        const {},
        trendDays: [
          DiaryHealthActivityTrendDay(
            day: start,
            totalSteps: 0,
            activeEnergyKcal: 200,
          ),
          DiaryHealthActivityTrendDay(
            day: secondDay,
            totalSteps: 1000,
            activeEnergyKcal: 0,
          ),
          DiaryHealthActivityTrendDay(
            day: today,
            totalSteps: 0,
            activeEnergyKcal: 300,
          ),
        ],
      );
      final healthWeightService = FakeHealthWeightService([
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
        diaryHealthService: diaryHealthService,
        settings: _settings(start),
        dates: dates,
        today: today,
        isMounted: () => true,
      );

      expect(data.usesHealthActivity, isTrue);
      expect(data.activeKcalByDay[diaryDayKey(start)], 200);
      expect(data.activeKcalByDay[diaryDayKey(secondDay)], 40);
      expect(data.todayActiveKcal, 300);
      expect(data.representativeWeightByDay[diaryDayKey(start)], 81);
      expect(diaryHealthService.loadDayDataCallCount, 0);
      expect(diaryHealthService.trendRequests, [
        (
          startInclusive: start,
          endExclusive: nextDiaryDay(today),
        ),
      ]);
    },
  );

  test('returns empty health data when access is unavailable', () async {
    final start = DateTime(2026, 4, 8);
    final secondDay = nextDiaryDay(start);
    final data = await loadCalorieWeeklyCheckInHealthData(
      healthStatusFuture: Future<HealthConnectionStatus>.value(
        const HealthConnectionStatus.unsupported(),
      ),
      healthWeightService: FakeHealthWeightService(const []),
      diaryHealthService: FakeDiaryHealthService(const {}),
      settings: _settings(start),
      dates: _dates(start: start, secondDay: secondDay),
      today: DateTime(2026, 4, 15),
      isMounted: () => true,
    );

    expect(data.usesHealthActivity, isFalse);
    expect(data.activeKcalByDay, {
      diaryDayKey(start): 0,
      diaryDayKey(secondDay): 0,
    });
    expect(data.todayActiveKcal, 0);
    expect(data.representativeWeightByDay, isEmpty);
  });

  test('throws before service reads when provider is disposed', () async {
    final start = DateTime(2026, 4, 8);
    final secondDay = nextDiaryDay(start);
    final healthWeightService = FakeHealthWeightService(const []);

    expect(
      () => loadCalorieWeeklyCheckInHealthData(
        healthStatusFuture: Future<HealthConnectionStatus>.value(_readyStatus),
        healthWeightService: healthWeightService,
        diaryHealthService: FakeDiaryHealthService(const {}),
        settings: _settings(start),
        dates: _dates(start: start, secondDay: secondDay),
        today: DateTime(2026, 4, 15),
        isMounted: () => false,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

CalorieGoalSettings _settings(DateTime start) {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2000,
    calculatorProfile: null,
    effectiveDate: start,
  );
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
