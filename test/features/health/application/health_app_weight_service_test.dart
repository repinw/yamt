import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/application/health_app_weight_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

import '../../../helpers/fake_health_weight_sample_repository.dart';

class _FakeHealthWeightService implements HealthWeightService {
  _FakeHealthWeightService({
    this.local = const [],
    this.saves = true,
    this.deletes = true,
  });

  final List<HealthWeightSample> local;
  final bool saves;
  final bool deletes;
  final deleted = <HealthWeightSample>[];
  final loadedRanges = <(DateTime, DateTime)>[];

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    loadedRanges.add((startInclusive, endExclusive));
    return local;
  }

  @override
  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  }) async => saves;

  @override
  Future<bool> deleteWeightSample(HealthWeightSample sample) async {
    deleted.add(sample);
    return deletes;
  }
}

final _at = DateTime(2026, 10, 18, 7, 30, 20);

HealthWeightSample _own({DateTime? at, double kg = 80.4, String? uuid}) =>
    HealthWeightSample(
      recordedAt: at ?? _at,
      weightKg: kg,
      isFromThisApp: true,
      uuid: uuid,
    );

void main() {
  late FakeHealthWeightSampleRepository cloud;

  setUp(() => cloud = FakeHealthWeightSampleRepository());
  tearDown(() => cloud.dispose());

  HealthAppWeightService service(_FakeHealthWeightService health) =>
      HealthAppWeightService(
        healthWeightService: health,
        sampleRepository: cloud,
      );

  group('add', () {
    test('writes to Health and the cloud', () async {
      final added = await service(_FakeHealthWeightService())
          .add(recordedAt: _at, weightKg: 80.4);

      expect(added, isTrue);
      expect(cloud.samples.single.recordedAt, _at);
      expect(cloud.samples.single.weightKg, 80.4);
      expect(cloud.samples.single.isFromThisApp, isTrue);
    });

    test('returns false and stores nothing when Health refuses', () async {
      final added = await service(_FakeHealthWeightService(saves: false))
          .add(recordedAt: _at, weightKg: 80.4);

      expect(added, isFalse);
      expect(cloud.samples, isEmpty);
    });

    test('still counts as saved when the cloud copy fails', () async {
      cloud.failChanges = true;

      final added = await service(_FakeHealthWeightService())
          .add(recordedAt: _at, weightKg: 80.4);

      expect(added, isTrue);
    });
  });

  group('isOnThisDevice', () {
    test('matches the minute and the weight to 0.01', () async {
      final health = _FakeHealthWeightService(
        local: [_own(at: DateTime(2026, 10, 18, 7, 30, 59), kg: 80.401)],
      );

      final found = await service(health).isOnThisDevice(_own(kg: 80.4));

      expect(found, isTrue);
      expect(health.loadedRanges.single, (
        DateTime(2026, 10, 18, 7, 30),
        DateTime(2026, 10, 18, 7, 31),
      ));
    });

    test('is false for another weight, minute, or source', () async {
      for (final local in [
        _own(kg: 80.5),
        _own(at: DateTime(2026, 10, 18, 7, 31)),
        _own(at: DateTime(2026, 10, 18, 7, 29, 59)),
        HealthWeightSample(recordedAt: _at, weightKg: 80.4),
      ]) {
        final found = await service(_FakeHealthWeightService(local: [local]))
            .isOnThisDevice(_own());

        expect(found, isFalse, reason: '${local.recordedAt} ${local.weightKg}');
      }
    });
  });

  group('delete', () {
    test('deletes the Health record of this device and the copy', () async {
      cloud = FakeHealthWeightSampleRepository([_own()]);
      final health = _FakeHealthWeightService(local: [_own(uuid: 'health-1')]);

      await service(health).delete(_own());

      expect(health.deleted.single.uuid, 'health-1');
      expect(cloud.samples, isEmpty);
    });

    test('throws and keeps the copy when this device lacks it', () async {
      cloud = FakeHealthWeightSampleRepository([_own()]);
      final health = _FakeHealthWeightService();

      await expectLater(service(health).delete(_own()), throwsStateError);

      expect(health.deleted, isEmpty);
      expect(cloud.samples, hasLength(1));
    });

    test('throws and keeps the copy when Health refuses', () async {
      cloud = FakeHealthWeightSampleRepository([_own()]);
      final health = _FakeHealthWeightService(
        local: [_own(uuid: 'health-1')],
        deletes: false,
      );

      await expectLater(service(health).delete(_own()), throwsStateError);

      expect(cloud.samples, hasLength(1));
    });
  });
}
