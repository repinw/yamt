import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_weight_state_refresh.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_weighing_controller.dart';

import '../../../../helpers/fake_health_weight_sample_repository.dart';
import '../../../calories/support/fake_calories_repositories.dart';

class _ThrowingHealthConnectionService extends FakeHealthConnectionService {
  _ThrowingHealthConnectionService()
    : super(const HealthConnectionStatus.unsupported());

  @override
  Future<void> openHealthApp() async => throw StateError('no Health app');
}

final _morning = DateTime(2026, 10, 18, 7, 30);

ProgressWeighing _manual(ManualHealthWeightEntry entry) => ProgressWeighing(
  day: entry.day,
  at: entry.recordedAt,
  weightKg: entry.weightKg,
  source: ProgressWeighingSource.manual,
  entry: entry,
);

ProgressWeighing _health(HealthWeightSample sample) => ProgressWeighing(
  day: DateTime(
    sample.recordedAt.year,
    sample.recordedAt.month,
    sample.recordedAt.day,
  ),
  at: sample.recordedAt,
  weightKg: sample.weightKg,
  source: sample.isFromThisApp
      ? ProgressWeighingSource.manual
      : ProgressWeighingSource.scale,
  sample: sample,
);

void main() {
  final entry = ManualHealthWeightEntry(
    day: _morning,
    weightKg: 80.4,
    recordedAt: _morning,
    id: 'morning',
  );
  final scale = HealthWeightSample(
    recordedAt: DateTime(2026, 10, 17, 6),
    weightKg: 81,
    sourcePackageName: 'com.scale',
  );
  final own = HealthWeightSample(
    recordedAt: DateTime(2026, 10, 16, 6),
    weightKg: 82,
    isFromThisApp: true,
  );

  late FakeManualHealthWeightRepository manual;
  late FakeHealthWeightSampleRepository cloud;
  late FakeHealthWeightService health;
  late FakeHealthConnectionService connection;
  late List<DateTime> refreshedDays;
  late ProviderContainer container;
  late List<AsyncValue<void>> states;

  ProviderContainer _container({HealthConnectionService? service}) {
    final result = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => _morning),
        manualHealthWeightRepositoryProvider.overrideWithValue(manual),
        healthWeightSampleRepositoryProvider.overrideWithValue(cloud),
        healthWeightServiceProvider.overrideWithValue(health),
        healthConnectionServiceProvider.overrideWithValue(
          service ?? connection,
        ),
        calorieWeightStateRefreshProvider.overrideWith(
          (ref) =>
              ({required DateTime day}) async => refreshedDays.add(day),
        ),
      ],
    );
    addTearDown(result.dispose);
    states = [];
    final subscription = result.listen(
      progressWeighingControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    return result;
  }

  setUp(() {
    manual = FakeManualHealthWeightRepository([entry]);
    cloud = FakeHealthWeightSampleRepository([scale, own]);
    health = FakeHealthWeightService(const []);
    connection = FakeHealthConnectionService(
      const HealthConnectionStatus.unsupported(),
    );
    refreshedDays = [];
    container = _container();
  });

  tearDown(() => cloud.dispose());

  ProgressWeighingController controller() =>
      container.read(progressWeighingControllerProvider.notifier);

  test(
    'canChange: manual always, a scale never, own Health on its device',
    () async {
      expect(await controller().canChange(_manual(entry)), isTrue);
      expect(await controller().canChange(_health(scale)), isFalse);
      // This device does not hold the weighing in its Health store.
      expect(await controller().canChange(_health(own)), isFalse);
      health = FakeHealthWeightService([
        HealthWeightSample(
          recordedAt: own.recordedAt,
          weightKg: own.weightKg,
          isFromThisApp: true,
          uuid: 'health-1',
        ),
      ]);
      container = _container();
      expect(await controller().canChange(_health(own)), isTrue);
    },
  );

  test(
    'save changes a manual entry and refreshes from the earlier day',
    () async {
      final saved = await controller().save(
        _manual(entry),
        at: DateTime(2026, 10, 15, 8),
        weightKg: 79.9,
      );

      expect(saved, isTrue);
      expect(manual.entries.single.id, 'morning');
      expect(manual.entries.single.weightKg, 79.9);
      expect(manual.entries.single.recordedAt, DateTime(2026, 10, 15, 8));
      // The weighing moved back, so the weeks from its new day change.
      expect(refreshedDays, [DateTime(2026, 10, 15)]);
    },
  );

  test(
    'save refreshes from the old day when the weighing moves later',
    () async {
      await controller().save(
        _manual(entry),
        at: DateTime(2026, 10, 18, 21),
        weightKg: 80.4,
      );

      expect(refreshedDays, [DateTime(2026, 10, 18)]);
      final moved = ProgressWeighing(
        day: DateTime(2026, 10, 10),
        at: DateTime(2026, 10, 10, 8),
        weightKg: 80,
        source: ProgressWeighingSource.manual,
        entry: manual.entries.single,
      );
      await controller().save(
        moved,
        at: DateTime(2026, 10, 18, 8),
        weightKg: 80,
      );
      expect(refreshedDays.last, DateTime(2026, 10, 10));
    },
  );

  test('save of an own Health weighing replaces it in Health', () async {
    health = FakeHealthWeightService([
      HealthWeightSample(
        recordedAt: own.recordedAt,
        weightKg: own.weightKg,
        isFromThisApp: true,
        uuid: 'health-1',
      ),
    ]);
    container = _container();

    final saved = await controller().save(
      _health(own),
      at: DateTime(2026, 10, 16, 7),
      weightKg: 81.5,
    );

    expect(saved, isTrue);
    expect(health.deletedSamples.single.uuid, 'health-1');
    // Health is unsupported in this setup, so the new weighing is manual.
    expect(manual.entries.any((e) => e.weightKg == 81.5), isTrue);
    expect(refreshedDays, [DateTime(2026, 10, 16)]);
  });

  test(
    'save fails without a refresh when this device lacks the weighing',
    () async {
      final saved = await controller().save(
        _health(own),
        at: DateTime(2026, 10, 16, 7),
        weightKg: 81.5,
      );

      expect(saved, isFalse);
      expect(refreshedDays, isEmpty);
      expect(manual.entries, [entry]);
    },
  );

  test('delete removes a manual entry and refreshes its day', () async {
    final deleted = await controller().delete(_manual(entry));

    expect(deleted, isTrue);
    expect(manual.entries, isEmpty);
    expect(refreshedDays, [DateTime(2026, 10, 18)]);
  });

  test(
    'delete fails without a refresh when Health keeps the weighing',
    () async {
      final deleted = await controller().delete(_health(own));

      expect(deleted, isFalse);
      expect(refreshedDays, isEmpty);
      expect(cloud.samples, hasLength(2));
    },
  );

  test('setIgnored flags the copy and refreshes from its day', () async {
    expect(await controller().setIgnored(scale, ignored: true), isTrue);

    expect(cloud.samples.firstWhere((s) => s.weightKg == 81).isIgnored, isTrue);
    expect(refreshedDays, [DateTime(2026, 10, 17)]);

    expect(await controller().setIgnored(scale, ignored: false), isTrue);
    expect(
      cloud.samples.firstWhere((s) => s.weightKg == 81).isIgnored,
      isFalse,
    );
  });

  test('setIgnored is false without a refresh when the cloud fails', () async {
    cloud.failChanges = true;

    expect(await controller().setIgnored(scale, ignored: true), isFalse);
    expect(refreshedDays, isEmpty);
  });

  test('openHealth opens the Health app', () async {
    expect(await controller().openHealth(), isTrue);
    expect(connection.openHealthAppCallCount, 1);
  });

  test('openHealth is false when Health cannot open', () async {
    container = _container(service: _ThrowingHealthConnectionService());

    expect(await controller().openHealth(), isFalse);
  });

  test('the actions leave the state as it was', () async {
    await controller().delete(_manual(entry));
    await controller().setIgnored(scale, ignored: true);

    expect(states, hasLength(1));
    expect(states.single, const AsyncData<void>(null));
  });
}
