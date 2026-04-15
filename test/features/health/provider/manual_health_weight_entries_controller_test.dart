import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
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
  Future<HealthConnectionStatus> loadStatus() async => status;

  @override
  Future<HealthConnectionStatus> requestAuthorization() async => status;

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async => status;
}

class _FakeHealthWeightService implements HealthWeightService {
  bool shouldSaveFail;
  int saveCallCount = 0;
  DateTime? lastRecordedAt;
  double? lastWeightKg;

  _FakeHealthWeightService({this.shouldSaveFail = false});

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    return const <HealthWeightSample>[];
  }

  @override
  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    saveCallCount += 1;
    lastRecordedAt = recordedAt;
    lastWeightKg = weightKg;
    return !shouldSaveFail;
  }
}

class _FakeManualHealthWeightRepository
    implements ManualHealthWeightRepository {
  List<ManualHealthWeightEntry> entries;
  bool shouldSaveFail;
  bool shouldDeleteFail;
  int saveCallCount = 0;
  int deleteCallCount = 0;

  _FakeManualHealthWeightRepository({
    this.entries = const <ManualHealthWeightEntry>[],
    this.shouldSaveFail = false,
    this.shouldDeleteFail = false,
  });

  @override
  Future<bool> deleteEntryForDay(DateTime day) async {
    deleteCallCount += 1;
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
    return List<ManualHealthWeightEntry>.unmodifiable(entries);
  }

  @override
  Future<bool> saveEntry(ManualHealthWeightEntry entry) async {
    saveCallCount += 1;
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

void main() {
  ProviderContainer buildContainer({
    required _FakeManualHealthWeightRepository repository,
    HealthConnectionStatus status = _permissionRequiredStatus,
    _FakeHealthWeightService? healthWeightService,
  }) {
    return ProviderContainer(
      overrides: [
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
    expect(healthWeightService.lastRecordedAt?.hour, 23);
    expect(healthWeightService.lastRecordedAt?.minute, 59);
    expect(repository.saveCallCount, 0);
    expect(repository.deleteCallCount, 1);
    expect(repository.entries, isEmpty);
    final stateEntries = container
        .read(manualHealthWeightEntriesControllerProvider)
        .requireValue;
    expect(stateEntries, isEmpty);
  });

  test(
    'saveEntry falls back to repository when connection not ready',
    () async {
      final repository = _FakeManualHealthWeightRepository();
      final healthWeightService = _FakeHealthWeightService();
      final container = buildContainer(
        repository: repository,
        status: _permissionRequiredStatus,
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

  test('saveEntry reverts state when repository save fails', () async {
    final repository = _FakeManualHealthWeightRepository(
      entries: [
        ManualHealthWeightEntry(day: DateTime(2026, 3, 18), weightKg: 72.1),
      ],
      shouldSaveFail: true,
    );
    final container = buildContainer(
      repository: repository,
      status: _permissionRequiredStatus,
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
}
