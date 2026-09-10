import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_service.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);
  const service = DiaryActivityWeightService();

  test('combines seven days of Health and manual weights', () async {
    final previousDay = selectedDay.subtract(const Duration(days: 1));
    final data = await service.load(
      day: selectedDay,
      profile: const DiaryActivityWeightProfile(weightKg: 80),
      healthStatus: _readyStatus,
      manualEntries: [
        ManualHealthWeightEntry(day: previousDay, weightKg: 77.4),
      ],
      healthWeightService: _FakeHealthWeightService([
        HealthWeightSample(
          recordedAt: selectedDay.add(const Duration(hours: 7)),
          weightKg: 76.8,
          uuid: 'selected-health',
          sourcePackageName: 'de.yamt.app',
          isFromThisApp: true,
        ),
      ]),
    );

    expect(data.profileWeightKg, 80);
    expect(data.selectedWeightKg, 76.8);
    expect(data.hasSelectedDayWeight, isTrue);
    expect(data.weightTrend[5], 77.4);
    expect(data.weightTrend.last, 76.8);
    expect(data.weightDays.last.canDeleteWeight, isTrue);
  });

  test('manual weight overrides Health weight for the same day', () async {
    final data = await service.load(
      day: selectedDay,
      profile: const DiaryActivityWeightProfile(weightKg: 80),
      healthStatus: _readyStatus,
      manualEntries: [
        ManualHealthWeightEntry(day: selectedDay, weightKg: 76.8),
      ],
      healthWeightService: _FakeHealthWeightService([
        HealthWeightSample(
          recordedAt: selectedDay,
          weightKg: 77.1,
          uuid: 'health-weight',
          sourcePackageName: 'de.yamt.app',
          isFromThisApp: true,
        ),
      ]),
    );

    expect(data.selectedWeightKg, 76.8);
    expect(data.weightDays.last.hasManualWeight, isTrue);
    expect(data.weightDays.last.healthSample?.weightKg, 77.1);
  });

  test('falls back to profile weight without saved weight', () async {
    final data = await service.load(
      day: selectedDay,
      profile: const DiaryActivityWeightProfile(weightKg: 80),
      healthStatus: _readyStatus,
      manualEntries: const [],
      healthWeightService: _FakeHealthWeightService(const []),
    );

    expect(data.selectedWeightKg, 80);
    expect(data.hasSelectedDayWeight, isFalse);
    expect(data.weightTrend.last, isNull);
  });

  test('does not query Health weights without access', () async {
    final healthService = _FakeHealthWeightService(const []);
    await service.load(
      day: selectedDay,
      profile: null,
      healthStatus: _deniedStatus,
      manualEntries: const [],
      healthWeightService: healthService,
    );

    expect(healthService.loadCount, 0);
  });
}

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

const _deniedStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

class _FakeHealthWeightService implements HealthWeightService {
  _FakeHealthWeightService(this.samples);

  final List<HealthWeightSample> samples;
  int loadCount = 0;

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    loadCount += 1;
    return samples;
  }

  @override
  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  }) async => false;

  @override
  Future<bool> deleteWeightSample(HealthWeightSample sample) async => false;
}
