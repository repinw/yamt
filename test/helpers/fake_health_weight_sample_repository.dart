import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

/// The cloud copies of Health weights, kept in memory. [watchSamples] is a
/// real asynchronous stream that delivers again after each change.
class FakeHealthWeightSampleRepository extends Fake
    implements HealthWeightSampleRepository {
  /// Creates the repository holding [samples].
  FakeHealthWeightSampleRepository([
    Iterable<HealthWeightSample> samples = const [],
  ]) : _samples = [...samples];

  final List<HealthWeightSample> _samples;
  final _changes = StreamController<void>.broadcast();

  /// Makes every change throw, like a missing copy.
  bool failChanges = false;

  /// The samples now.
  List<HealthWeightSample> get samples => List.unmodifiable(_samples);

  /// Ends the change stream.
  Future<void> dispose() => _changes.close();

  bool _same(HealthWeightSample left, HealthWeightSample right) =>
      left.recordedAt == right.recordedAt && left.weightKg == right.weightKg;

  void _changed() => _changes.add(null);

  @override
  Stream<List<HealthWeightSample>> watchSamples() async* {
    await Future<void>.delayed(Duration.zero);
    yield samples;
    await for (final _ in _changes.stream) {
      yield samples;
    }
  }

  @override
  Future<void> saveAppWeight({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    if (failChanges) throw StateError('save failed');
    _samples.add(
      HealthWeightSample(
        recordedAt: recordedAt,
        weightKg: weightKg,
        isFromThisApp: true,
      ),
    );
    _changed();
  }

  @override
  Future<void> setIgnored(
    HealthWeightSample sample, {
    required bool ignored,
  }) async {
    if (failChanges) throw StateError('ignore failed');
    final index = _samples.indexWhere((other) => _same(other, sample));
    if (index < 0) throw StateError('no copy');
    final stored = _samples[index];
    _samples[index] = HealthWeightSample(
      recordedAt: stored.recordedAt,
      weightKg: stored.weightKg,
      sourcePackageName: stored.sourcePackageName,
      isFromThisApp: stored.isFromThisApp,
      isIgnored: ignored,
    );
    _changed();
  }

  @override
  Future<void> deleteSample(HealthWeightSample sample) async {
    if (failChanges) throw StateError('delete failed');
    _samples.removeWhere((other) => _same(other, sample));
    _changed();
  }
}
