import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/health/application/health_connection_controller.dart';
import 'package:yamt/features/health/application/manual_health_weight_entries_controller.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

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
  new(this.status);

  final HealthConnectionStatus status;

  @override
  Future<HealthDisconnectResult> disconnect() async {
    return HealthDisconnectResult.disconnected;
  }

  @override
  Future<void> installHealthConnect() async {}

  @override
  Future<void> openHealthApp() async {}

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
  new({
    this.shouldSaveFail = false,
    this.shouldThrowOnSave = false,
    this.localSamples = const <HealthWeightSample>[],
    this.deleteSucceeds = true,
  });
  final List<HealthWeightSample> localSamples;
  final bool deleteSucceeds;
  final deletedSamples = <HealthWeightSample>[];
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
    return localSamples;
  }

  @override
  Future<bool> deleteWeightSample(HealthWeightSample sample) async {
    deletedSamples.add(sample);
    return deleteSucceeds;
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
  new({
    this.entries = const <ManualHealthWeightEntry>[],
    this.readEntriesCompleter,
    this.shouldSaveFail = false,
    this.shouldSaveThrow = false,
    this.shouldDeleteThrow = false,
  });
  List<ManualHealthWeightEntry> entries;
  Completer<List<ManualHealthWeightEntry>>? readEntriesCompleter;
  bool shouldSaveFail;
  bool shouldSaveThrow;
  bool shouldDeleteThrow;
  int saveCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<void> deleteEntry(ManualHealthWeightEntry entry) async {
    deleteCallCount += 1;
    if (shouldDeleteThrow) {
      throw Exception('deleteEntry failed');
    }
    entries = [
      for (final existing in entries)
        if (existing.storageId != entry.storageId) existing,
    ];
  }

  @override
  Future<ManualHealthWeightEntry> updateEntry(
    ManualHealthWeightEntry previous,
    ManualHealthWeightEntry next,
  ) async {
    entries = [
      for (final existing in entries)
        if (existing.storageId != previous.storageId) existing,
    ];
    await saveEntry(next);
    return next;
  }

  @override
  Future<List<ManualHealthWeightEntry>> readEntries() async {
    final pendingRead = readEntriesCompleter;
    if (pendingRead != null) {
      return await pendingRead.future;
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
        if (existingEntry.storageId != entry.storageId) existingEntry,
      entry,
    ]..sort((left, right) => left.at.compareTo(right.at));
    return true;
  }
}

/// Stands in for the repository provider switching to a new repository when
/// the user data key becomes ready.
class _SelectedRepository extends Notifier<_FakeManualHealthWeightRepository> {
  new(this._locked, this._unlocked);

  final _FakeManualHealthWeightRepository _locked;
  final _FakeManualHealthWeightRepository _unlocked;

  @override
  _FakeManualHealthWeightRepository build() => _locked;

  /// Switches to the repository of the unlocked data key.
  void unlock() {
    state = _unlocked;
  }
}

class _RecordingSampleRepository extends Fake
    implements HealthWeightSampleRepository {
  final saved = <HealthWeightSample>[];

  @override
  Future<void> saveAppWeight({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    saved.add(HealthWeightSample(recordedAt: recordedAt, weightKg: weightKg));
  }

  final deleted = <HealthWeightSample>[];

  @override
  Future<void> deleteSample(HealthWeightSample sample) async {
    deleted.add(sample);
  }

  final ignored = <(HealthWeightSample, bool)>[];
  bool failIgnore = false;

  @override
  Future<void> setIgnored(
    HealthWeightSample sample, {
    required bool ignored,
  }) async {
    if (failIgnore) throw StateError('ignore failed');
    this.ignored.add((sample, ignored));
  }
}

void main() {
  ProviderContainer buildContainer({
    required _FakeManualHealthWeightRepository repository,
    HealthConnectionStatus status = _permissionRequiredStatus,
    _FakeHealthWeightService? healthWeightService,
    _RecordingSampleRepository? sampleRepository,
    DateTime Function()? now,
  }) {
    return ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(now ?? () => DateTime(2026, 4, 1, 12)),
        manualHealthWeightRepositoryProvider.overrideWith((ref) => repository),
        healthConnectionServiceProvider.overrideWith(
          (ref) => _FakeHealthConnectionService(status),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => healthWeightService ?? _FakeHealthWeightService(),
        ),
        healthWeightSampleRepositoryProvider.overrideWith(
          (ref) => sampleRepository ?? _RecordingSampleRepository(),
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
    final sampleRepository = _RecordingSampleRepository();
    final container = buildContainer(
      repository: repository,
      status: _readyStatus,
      healthWeightService: healthWeightService,
      sampleRepository: sampleRepository,
    );
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final saved = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: DateTime(2026, 3, 20, 18), weightKg: 71.2);

    expect(saved, isTrue);
    // The cloud gets the weight at once, so readers count it before the
    // next sync.
    expect(sampleRepository.saved.single.recordedAt, DateTime(2026, 3, 20, 12));
    expect(sampleRepository.saved.single.weightKg, 71.2);
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
    // The manual weighing of the day is another weighing and stays.
    expect(repository.saveCallCount, 0);
    expect(repository.deleteCallCount, 0);
    expect(repository.entries, hasLength(1));
    final stateEntries = container
        .read(manualHealthWeightEntriesControllerProvider)
        .requireValue;
    expect(stateEntries, hasLength(1));
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

  test('saveEntry adds a weighing with an id of its own', () async {
    final repository = _FakeManualHealthWeightRepository(
      entries: [
        ManualHealthWeightEntry(
          day: DateTime(2026, 4, 2),
          weightKg: 72.1,
          id: '2026-04-02',
        ),
        ManualHealthWeightEntry(
          day: DateTime(2026, 4, 2, 8),
          weightKg: 72.4,
          recordedAt: DateTime(2026, 4, 2, 8),
          id: 'morning',
        ),
      ],
    );
    final container = buildContainer(
      repository: repository,
      now: () => DateTime(2026, 4, 2, 9, 30),
    );
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: DateTime(2026, 4, 2), weightKg: 71.8);

    final saved = repository.entries.last;
    expect(repository.entries, hasLength(3));
    expect(saved.id, isNot(anyOf('2026-04-02', 'morning')));
    expect(saved.recordedAt, DateTime(2026, 4, 2, 9, 29, 59));
    expect(saved.weightKg, 71.8);
  });

  test('updateEntry keeps the id of the entry', () async {
    final morning = ManualHealthWeightEntry(
      day: DateTime(2026, 4, 2, 8),
      weightKg: 72.4,
      recordedAt: DateTime(2026, 4, 2, 8),
      id: 'morning',
    );
    final repository = _FakeManualHealthWeightRepository(entries: [morning]);
    final container = buildContainer(repository: repository);
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final updated = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .updateEntry(
          morning,
          recordedAt: DateTime(2026, 4, 1, 7, 15),
          weightKg: 72,
        );

    expect(updated, isTrue);
    expect(repository.entries.single.id, 'morning');
    expect(repository.entries.single.day, DateTime(2026, 4));
    expect(repository.entries.single.weightKg, 72);
  });

  test('deleteEntry deletes only that entry', () async {
    final morning = ManualHealthWeightEntry(
      day: DateTime(2026, 4, 2, 8),
      weightKg: 72.4,
      recordedAt: DateTime(2026, 4, 2, 8),
      id: 'morning',
    );
    final evening = ManualHealthWeightEntry(
      day: DateTime(2026, 4, 2, 20),
      weightKg: 73,
      recordedAt: DateTime(2026, 4, 2, 20),
      id: 'evening',
    );
    final repository = _FakeManualHealthWeightRepository(
      entries: [morning, evening],
    );
    final container = buildContainer(repository: repository);
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final deleted = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .deleteEntry(morning);

    expect(deleted, isTrue);
    expect(repository.entries.single.id, 'evening');
    expect(
      container
          .read(manualHealthWeightEntriesControllerProvider)
          .requireValue
          .single
          .id,
      'evening',
    );
  });

  test('deleteEntry restores the entries when the delete throws', () async {
    final morning = ManualHealthWeightEntry(
      day: DateTime(2026, 4, 2, 8),
      weightKg: 72.4,
      recordedAt: DateTime(2026, 4, 2, 8),
      id: 'morning',
    );
    final repository = _FakeManualHealthWeightRepository(
      entries: [morning],
      shouldDeleteThrow: true,
    );
    final container = buildContainer(repository: repository);
    addTearDown(container.dispose);

    await container.read(manualHealthWeightEntriesControllerProvider.future);
    final deleted = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .deleteEntry(morning);

    expect(deleted, isFalse);
    expect(
      container
          .read(manualHealthWeightEntriesControllerProvider)
          .requireValue
          .single
          .id,
      'morning',
    );
  });

  group('Health weighings of this app', () {
    final at = DateTime(2026, 4, 1, 7, 30, 15);
    final own = HealthWeightSample(
      recordedAt: at,
      weightKg: 80.4,
      isFromThisApp: true,
    );
    final onDevice = HealthWeightSample(
      recordedAt: at,
      weightKg: 80.4,
      isFromThisApp: true,
      uuid: 'health-1',
    );

    test('deleteAppWeight deletes the Health record and the copy', () async {
      final health = _FakeHealthWeightService(localSamples: [onDevice]);
      final cloud = _RecordingSampleRepository();
      final container = buildContainer(
        repository: _FakeManualHealthWeightRepository(),
        healthWeightService: health,
        sampleRepository: cloud,
      );
      addTearDown(container.dispose);

      final deleted = await container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .deleteAppWeight(own);

      expect(deleted, isTrue);
      expect(health.deletedSamples.single.uuid, 'health-1');
      expect(cloud.deleted, [own]);
    });

    test('setIgnored flags the cloud copy, and clears the flag', () async {
      final cloud = _RecordingSampleRepository();
      final container = buildContainer(
        repository: _FakeManualHealthWeightRepository(),
        sampleRepository: cloud,
      );
      addTearDown(container.dispose);
      final controller = container.read(
        manualHealthWeightEntriesControllerProvider.notifier,
      );

      expect(await controller.setIgnored(own, ignored: true), isTrue);
      expect(await controller.setIgnored(own, ignored: false), isTrue);
      expect(cloud.ignored, [(own, true), (own, false)]);
    });

    test('setIgnored is false when the cloud copy fails', () async {
      final cloud = _RecordingSampleRepository()..failIgnore = true;
      final container = buildContainer(
        repository: _FakeManualHealthWeightRepository(),
        sampleRepository: cloud,
      );
      addTearDown(container.dispose);

      final done = await container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .setIgnored(own, ignored: true);

      expect(done, isFalse);
    });

    test('deleteAppWeight is false when Health refuses or lacks it', () async {
      for (final health in [
        _FakeHealthWeightService(
          localSamples: [onDevice],
          deleteSucceeds: false,
        ),
        _FakeHealthWeightService(),
      ]) {
        final cloud = _RecordingSampleRepository();
        final container = buildContainer(
          repository: _FakeManualHealthWeightRepository(),
          healthWeightService: health,
          sampleRepository: cloud,
        );
        addTearDown(container.dispose);

        final deleted = await container
            .read(manualHealthWeightEntriesControllerProvider.notifier)
            .deleteAppWeight(own);

        expect(deleted, isFalse);
        expect(cloud.deleted, isEmpty);
      }
    });

    test('updateAppWeight replaces the weighing in Health', () async {
      final health = _FakeHealthWeightService(localSamples: [onDevice]);
      final cloud = _RecordingSampleRepository();
      final container = buildContainer(
        repository: _FakeManualHealthWeightRepository(),
        status: _readyStatus,
        healthWeightService: health,
        sampleRepository: cloud,
      );
      addTearDown(container.dispose);

      final updated = await container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .updateAppWeight(
            own,
            recordedAt: DateTime(2026, 3, 31, 8),
            weightKg: 79.9,
          );

      expect(updated, isTrue);
      expect(cloud.deleted, [own]);
      expect(health.lastRecordedAt, DateTime(2026, 3, 31, 8));
      expect(health.lastWeightKg, 79.9);
      expect(cloud.saved.single.weightKg, 79.9);
    });

    test('updateAppWeight keeps the old weighing when the add fails', () async {
      final health = _FakeHealthWeightService(
        localSamples: [onDevice],
        shouldSaveFail: true,
      );
      final cloud = _RecordingSampleRepository();
      final container = buildContainer(
        repository: _FakeManualHealthWeightRepository(shouldSaveFail: true),
        status: _readyStatus,
        healthWeightService: health,
        sampleRepository: cloud,
      );
      addTearDown(container.dispose);

      final updated = await container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .updateAppWeight(own, recordedAt: at, weightKg: 79.9);

      expect(updated, isFalse);
      expect(health.deletedSamples, isEmpty);
      expect(cloud.deleted, isEmpty);
    });

    test('updateAppWeight keeps both when the old one fails to go', () async {
      final health = _FakeHealthWeightService();
      final container = buildContainer(
        repository: _FakeManualHealthWeightRepository(),
        status: _readyStatus,
        healthWeightService: health,
      );
      addTearDown(container.dispose);

      final updated = await container
          .read(manualHealthWeightEntriesControllerProvider.notifier)
          .updateAppWeight(own, recordedAt: at, weightKg: 79.9);

      expect(updated, isTrue);
      expect(health.saveCallCount, 1);
    });

    test(
      'updateAppWeight does nothing for the same minute and weight',
      () async {
        final health = _FakeHealthWeightService(localSamples: [onDevice]);
        final cloud = _RecordingSampleRepository();
        final container = buildContainer(
          repository: _FakeManualHealthWeightRepository(),
          status: _readyStatus,
          healthWeightService: health,
          sampleRepository: cloud,
        );
        addTearDown(container.dispose);

        final updated = await container
            .read(manualHealthWeightEntriesControllerProvider.notifier)
            .updateAppWeight(
              own,
              recordedAt: DateTime(2026, 4, 1, 7, 30),
              weightKg: 80.4,
            );

        expect(updated, isTrue);
        expect(health.saveCallCount, 0);
        expect(cloud.deleted, isEmpty);
      },
    );
  });

  test('saveEntry reverts state when repository save fails', () async {
    final repository = _FakeManualHealthWeightRepository(
      entries: [
        ManualHealthWeightEntry(day: DateTime(2026, 3, 18), weightKg: 72.1),
      ],
      shouldSaveFail: true,
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

  test('build reloads entries when the repository changes', () async {
    final lockedRepository = _FakeManualHealthWeightRepository();
    final unlockedRepository = _FakeManualHealthWeightRepository(
      entries: [
        ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 72.1),
      ],
    );
    final selectedRepositoryProvider =
        NotifierProvider<
          _SelectedRepository,
          _FakeManualHealthWeightRepository
        >(() => _SelectedRepository(lockedRepository, unlockedRepository));
    final container = ProviderContainer(
      overrides: [
        manualHealthWeightRepositoryProvider.overrideWith(
          (ref) => ref.watch(selectedRepositoryProvider),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      manualHealthWeightEntriesControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    expect(
      await container.read(manualHealthWeightEntriesControllerProvider.future),
      isEmpty,
    );

    container.read(selectedRepositoryProvider.notifier).unlock();
    final entries = await container.read(
      manualHealthWeightEntriesControllerProvider.future,
    );

    expect(entries, hasLength(1));
    expect(entries.single.weightKg, 72.1);
  });
}
