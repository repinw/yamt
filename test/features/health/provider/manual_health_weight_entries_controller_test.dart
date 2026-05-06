import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_repository_provider.dart';

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

const _permissionRequiredStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

class _FakeHealthConnectionService implements HealthConnectionService {
  _FakeHealthConnectionService(this.status);

  final HealthConnectionStatus status;

  @override
  Future<HealthDisconnectResult> disconnect() async {
    return HealthDisconnectResult.disconnected;
  }

  @override
  Future<void> installHealthConnect() async {}

  @override
  Future<void> openAppPermissionSettings() async {}

  @override
  Future<void> openHealthPermissionSettings() async {}

  @override
  Future<HealthConnectionStatus> loadStatus() async => status;

  @override
  Future<HealthConnectionStatus> requestAuthorization() async => status;

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async => status;
}

class _FakeHealthWeightService implements HealthWeightService {
  _FakeHealthWeightService({
    this.shouldSaveFail = false,
    this.shouldThrowOnSave = false,
  });
  bool shouldSaveFail;
  bool shouldThrowOnSave;
  int saveCallCount = 0;
  DateTime? lastRecordedAt;
  double? lastWeightKg;

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    return const <HealthWeightSample>[];
  }

  @override
  Future<bool> deleteWeightSample(HealthWeightSample sample) async {
    return true;
  }

  @override
  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    saveCallCount += 1;
    lastRecordedAt = recordedAt;
    lastWeightKg = weightKg;
    if (shouldThrowOnSave) {
      throw Exception('saveWeightSample failed');
    }
    return !shouldSaveFail;
  }
}

class _FakeManualHealthWeightRepository
    implements ManualHealthWeightRepository {
  _FakeManualHealthWeightRepository({
    this.entries = const <ManualHealthWeightEntry>[],
    this.readEntriesCompleter,
    this.shouldSaveFail = false,
    this.shouldDeleteFail = false,
    this.shouldSaveThrow = false,
    this.shouldDeleteThrow = false,
  });
  List<ManualHealthWeightEntry> entries;
  Completer<List<ManualHealthWeightEntry>>? readEntriesCompleter;
  bool shouldSaveFail;
  bool shouldDeleteFail;
  bool shouldSaveThrow;
  bool shouldDeleteThrow;
  int saveCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<bool> deleteEntryForDay(DateTime day) async {
    deleteCallCount += 1;
    if (shouldDeleteThrow) {
      throw Exception('deleteEntryForDay failed');
    }
    if (shouldDeleteFail) {
      return false;
    }
    entries = entries
        .where((entry) => entry.day != DateTime(day.year, day.month, day.day))
        .toList(growable: false);
    return true;
  }

  @override
  Future<List<ManualHealthWeightEntry>> readEntries() async {
    final pendingRead = readEntriesCompleter;
    if (pendingRead != null) {
      return pendingRead.future;
    }
    return List<ManualHealthWeightEntry>.unmodifiable(entries);
  }

  @override
  Future<bool> saveEntry(ManualHealthWeightEntry entry) async {
    saveCallCount += 1;
    if (shouldSaveThrow) {
      throw Exception('saveEntry failed');
    }
    if (shouldSaveFail) {
      return false;
    }
    entries = [
      for (final existingEntry in entries)
        if (existingEntry.day != entry.day) existingEntry,
      entry,
    ]..sort((left, right) => left.day.compareTo(right.day));
    return true;
  }
}

class _FakeCalorieSettingsRepository implements CalorieSettingsRepository {
  _FakeCalorieSettingsRepository({
    CalorieGoalSettings settings = const CalorieGoalSettings.empty(),
  }) : settings = settings;

  CalorieGoalSettings settings;
  int saveCallCount = 0;

  @override
  Future<bool> clearDailyGoal() async => false;

  @override
  Future<CalorieGoalSettings> readSettings() async => settings;

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async {
    saveCallCount += 1;
    this.settings = settings;
    return true;
  }

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) async => false;

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    return Stream<CalorieGoalSettings>.value(settings);
  }
}

void main() {
  ProviderContainer buildContainer({
    required _FakeManualHealthWeightRepository repository,
    HealthConnectionStatus status = _permissionRequiredStatus,
    _FakeHealthWeightService? healthWeightService,
    _FakeCalorieSettingsRepository? calorieSettingsRepository,
    DateTime Function()? now,
  }) {
    return ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(
          calorieSettingsRepository ?? _FakeCalorieSettingsRepository(),
        ),
        manualHealthWeightNowProvider.overrideWithValue(
          now ?? () => DateTime(2026, 4, 1, 12),
        ),
        manualHealthWeightRepositoryProvider.overrideWith((ref) => repository),
        healthConnectionServiceProvider.overrideWith(
          (ref) => _FakeHealthConnectionService(status),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => healthWeightService ?? _FakeHealthWeightService(),
        ),
      ],
    );
  }

  CalorieGoalSettings settingsWithTrustedSnapshot() {
    return const CalorieGoalSettings.empty().applyGoalChange(
      changedAt: DateTime(2026, 3, 21),
      dailyKcalGoal: 2300,
      calculatorProfile: null,
      source: CalorieGoalSource.weeklyCheckIn,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 3, 14),
        windowEndDate: DateTime(2026, 3, 20),
        trendWeightChangePerDay: 0,
        calculatedTrueTdeeKcal: 2300,
        averageActiveKcal: 0,
        lowConfidence: false,
        inputHash: 'v1:trusted',
      ),
    );
  }

  test('saveEntry writes to health when connection is ready', () async {
    final repository = _FakeManualHealthWeightRepository(
      entries: [
        ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 72.1),
      ],
    );
    final healthWeightService = _FakeHealthWeightService();
    final container = buildContainer(
      repository: repository,
      status: _readyStatus,
      healthWeightService: healthWeightService,
    );
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final saved = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: DateTime(2026, 3, 20, 18), weightKg: 71.2);

    expect(saved, isTrue);
    expect(healthWeightService.saveCallCount, 1);
    expect(healthWeightService.lastWeightKg, 71.2);
    expect(healthWeightService.lastRecordedAt?.year, 2026);
    expect(healthWeightService.lastRecordedAt?.month, 3);
    expect(healthWeightService.lastRecordedAt?.day, 20);
    expect(healthWeightService.lastRecordedAt?.hour, 12);
    expect(healthWeightService.lastRecordedAt?.minute, 0);
    expect(healthWeightService.lastRecordedAt?.second, 0);
    expect(healthWeightService.lastRecordedAt?.millisecond, 0);
    expect(healthWeightService.lastRecordedAt?.microsecond, 0);
    expect(repository.saveCallCount, 0);
    expect(repository.deleteCallCount, 1);
    expect(repository.entries, isEmpty);
    final stateEntries = container
        .read(manualHealthWeightEntriesControllerProvider)
        .requireValue;
    expect(stateEntries, isEmpty);
  });

  test(
    'saveEntry avoids future health timestamp for today before noon',
    () async {
      final todayMorning = DateTime(2026, 4, 30, 8, 30);
      final repository = _FakeManualHealthWeightRepository();
      final healthWeightService = _FakeHealthWeightService();
      final container = buildContainer(
        repository: repository,
        status: _readyStatus,
        healthWeightService: healthWeightService,
        now: () => todayMorning,
      );
      addTearDown(container.dispose);

      await container.read(manualHealthWeightEntriesControllerProvider.future);
      final saved = await container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .saveEntry(day: todayMorning, weightKg: 71.2);

      expect(saved, isTrue);
      expect(
        healthWeightService.lastRecordedAt,
        DateTime(2026, 4, 30, 8, 29, 59),
      );
    },
  );

  test(
    'saveEntry falls back to repository when connection not ready',
    () async {
      final repository = _FakeManualHealthWeightRepository();
      final healthWeightService = _FakeHealthWeightService();
      final container = buildContainer(
        repository: repository,
        healthWeightService: healthWeightService,
      );
      addTearDown(container.dispose);

      await container.read(manualHealthWeightEntriesControllerProvider.future);
      final saved = await container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .saveEntry(day: DateTime(2026, 3, 20, 18), weightKg: 71.2);

      expect(saved, isTrue);
      expect(healthWeightService.saveCallCount, 0);
      expect(repository.saveCallCount, 1);
      expect(repository.entries.single.day, DateTime(2026, 3, 20));
      expect(repository.entries.single.weightKg, 71.2);
      final stateEntries = container
          .read(manualHealthWeightEntriesControllerProvider)
          .requireValue;
      expect(stateEntries, hasLength(1));
      expect(stateEntries.single.day, DateTime(2026, 3, 20));
      expect(stateEntries.single.weightKg, 71.2);
    },
  );

  test('saveEntry dirties weekly snapshots that include weight day', () async {
    final repository = _FakeManualHealthWeightRepository();
    final calorieSettingsRepository = _FakeCalorieSettingsRepository(
      settings: settingsWithTrustedSnapshot(),
    );
    final container = buildContainer(
      repository: repository,
      calorieSettingsRepository: calorieSettingsRepository,
    );
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final saved = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: DateTime(2026, 3, 20, 18), weightKg: 71.2);

    expect(saved, isTrue);
    expect(calorieSettingsRepository.saveCallCount, 1);
    final snapshot = calorieSettingsRepository
        .settings
        .goalHistory
        .single
        .weeklyCheckInSnapshot!;
    expect(snapshot.inputHash, isNull);
    expect(snapshot.invalidatedAt, isNotNull);
  });

  test('saveEntry falls back to repository when health save fails', () async {
    final repository = _FakeManualHealthWeightRepository();
    final healthWeightService = _FakeHealthWeightService(shouldSaveFail: true);
    final container = buildContainer(
      repository: repository,
      status: _readyStatus,
      healthWeightService: healthWeightService,
    );
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final saved = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: DateTime(2026, 3, 20), weightKg: 71.2);

    expect(saved, isTrue);
    expect(healthWeightService.saveCallCount, 1);
    expect(repository.saveCallCount, 1);
    expect(repository.entries.single.day, DateTime(2026, 3, 20));
    expect(repository.entries.single.weightKg, 71.2);
  });

  test('saveEntry falls back to repository when health save throws', () async {
    final repository = _FakeManualHealthWeightRepository();
    final healthWeightService = _FakeHealthWeightService(
      shouldThrowOnSave: true,
    );
    final container = buildContainer(
      repository: repository,
      status: _readyStatus,
      healthWeightService: healthWeightService,
    );
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final saved = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: DateTime(2026, 3, 20), weightKg: 71.2);

    expect(saved, isTrue);
    expect(healthWeightService.saveCallCount, 1);
    expect(repository.saveCallCount, 1);
    expect(repository.entries.single.day, DateTime(2026, 3, 20));
    expect(repository.entries.single.weightKg, 71.2);
  });

  test(
    'saveEntry keeps success when health save works and fallback cleanup fails',
    () async {
      final repository = _FakeManualHealthWeightRepository(
        entries: [
          ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 72.1),
        ],
        shouldDeleteFail: true,
      );
      final healthWeightService = _FakeHealthWeightService();
      final container = buildContainer(
        repository: repository,
        status: _readyStatus,
        healthWeightService: healthWeightService,
      );
      addTearDown(container.dispose);

      await container.read(manualHealthWeightEntriesControllerProvider.future);
      final saved = await container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .saveEntry(day: DateTime(2026, 3, 20, 18), weightKg: 71.2);

      expect(saved, isTrue);
      expect(healthWeightService.saveCallCount, 1);
      expect(repository.deleteCallCount, 1);
      final stateEntries = container
          .read(manualHealthWeightEntriesControllerProvider)
          .requireValue;
      expect(stateEntries, isEmpty);
    },
  );

  test('saveEntry reverts state when repository save fails', () async {
    final repository = _FakeManualHealthWeightRepository(
      entries: [
        ManualHealthWeightEntry(day: DateTime(2026, 3, 18), weightKg: 72.1),
      ],
      shouldSaveFail: true,
    );
    final container = buildContainer(
      repository: repository,
    );
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final saved = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: DateTime(2026, 3, 20), weightKg: 71.2);

    expect(saved, isFalse);
    final stateEntries = container
        .read(manualHealthWeightEntriesControllerProvider)
        .requireValue;
    expect(stateEntries, hasLength(1));
    expect(stateEntries.single.day, DateTime(2026, 3, 18));
    expect(stateEntries.single.weightKg, 72.1);
    expect(repository.entries, hasLength(1));
  });

  test('saveEntry reverts state when repository save throws', () async {
    final repository = _FakeManualHealthWeightRepository(
      entries: [
        ManualHealthWeightEntry(day: DateTime(2026, 3, 18), weightKg: 72.1),
      ],
      shouldSaveThrow: true,
    );
    final container = buildContainer(repository: repository);
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final saved = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: DateTime(2026, 3, 20), weightKg: 71.2);

    expect(saved, isFalse);
    final stateEntries = container
        .read(manualHealthWeightEntriesControllerProvider)
        .requireValue;
    expect(stateEntries, hasLength(1));
    expect(stateEntries.single.day, DateTime(2026, 3, 18));
    expect(stateEntries.single.weightKg, 72.1);
    expect(repository.entries, hasLength(1));
  });

  test('deleteEntryForDay removes entry from state and repository', () async {
    final repository = _FakeManualHealthWeightRepository(
      entries: [
        ManualHealthWeightEntry(day: DateTime(2026, 3, 18), weightKg: 72.1),
        ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 71.2),
      ],
    );
    final container = buildContainer(repository: repository);
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final deleted = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .deleteEntryForDay(DateTime(2026, 3, 20, 18));

    expect(deleted, isTrue);
    expect(repository.entries, hasLength(1));
    expect(repository.entries.single.day, DateTime(2026, 3, 18));
    final stateEntries = container
        .read(manualHealthWeightEntriesControllerProvider)
        .requireValue;
    expect(stateEntries, hasLength(1));
    expect(stateEntries.single.day, DateTime(2026, 3, 18));
    expect(stateEntries.single.weightKg, 72.1);
  });

  test('deleteEntryForDay dirties weekly snapshots that include day', () async {
    final repository = _FakeManualHealthWeightRepository(
      entries: [
        ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 71.2),
      ],
    );
    final calorieSettingsRepository = _FakeCalorieSettingsRepository(
      settings: settingsWithTrustedSnapshot(),
    );
    final container = buildContainer(
      repository: repository,
      calorieSettingsRepository: calorieSettingsRepository,
    );
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final deleted = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .deleteEntryForDay(DateTime(2026, 3, 20, 18));

    expect(deleted, isTrue);
    expect(calorieSettingsRepository.saveCallCount, 1);
    final snapshot = calorieSettingsRepository
        .settings
        .goalHistory
        .single
        .weeklyCheckInSnapshot!;
    expect(snapshot.inputHash, isNull);
    expect(snapshot.invalidatedAt, isNotNull);
  });

  test(
    'deleteEntryForDay reverts state when repository delete fails',
    () async {
      final repository = _FakeManualHealthWeightRepository(
        entries: [
          ManualHealthWeightEntry(day: DateTime(2026, 3, 18), weightKg: 72.1),
        ],
        shouldDeleteFail: true,
      );
      final container = buildContainer(repository: repository);
      addTearDown(container.dispose);

      await container.read(manualHealthWeightEntriesControllerProvider.future);
      final deleted = await container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .deleteEntryForDay(DateTime(2026, 3, 18));

      expect(deleted, isFalse);
      final stateEntries = container
          .read(manualHealthWeightEntriesControllerProvider)
          .requireValue;
      expect(stateEntries, hasLength(1));
      expect(stateEntries.single.day, DateTime(2026, 3, 18));
      expect(stateEntries.single.weightKg, 72.1);
    },
  );

  test(
    'deleteEntryForDay reverts state when repository delete throws',
    () async {
      final repository = _FakeManualHealthWeightRepository(
        entries: [
          ManualHealthWeightEntry(day: DateTime(2026, 3, 18), weightKg: 72.1),
        ],
        shouldDeleteThrow: true,
      );
      final container = buildContainer(repository: repository);
      addTearDown(container.dispose);

      await container.read(manualHealthWeightEntriesControllerProvider.future);
      final deleted = await container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .deleteEntryForDay(DateTime(2026, 3, 18));

      expect(deleted, isFalse);
      final stateEntries = container
          .read(manualHealthWeightEntriesControllerProvider)
          .requireValue;
      expect(stateEntries, hasLength(1));
      expect(stateEntries.single.day, DateTime(2026, 3, 18));
      expect(stateEntries.single.weightKg, 72.1);
    },
  );

  test(
    'saveEntry still persists when controller is disposed mid-flight',
    () async {
      final readEntriesCompleter = Completer<List<ManualHealthWeightEntry>>();
      final repository = _FakeManualHealthWeightRepository(
        readEntriesCompleter: readEntriesCompleter,
      );
      final container = buildContainer(repository: repository);

      await container.read(healthConnectionControllerProvider.future);
      final saveFuture = container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .saveEntry(day: DateTime(2026, 3, 20, 18), weightKg: 71.2);

      container.dispose();
      readEntriesCompleter.complete(const <ManualHealthWeightEntry>[]);

      await expectLater(saveFuture, completion(isTrue));
      expect(repository.entries, hasLength(1));
      expect(repository.entries.single.day, DateTime(2026, 3, 20));
      expect(repository.entries.single.weightKg, 71.2);
    },
  );
}
