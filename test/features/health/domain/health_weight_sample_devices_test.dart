import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_weight_sample_devices.dart';

void main() {
  final recordedAt = DateTime(2026, 10, 17, 7);

  test('a sync that adds a device keeps the ignored flag', () {
    final ignored = HealthWeightSample(
      recordedAt: recordedAt,
      weightKg: 81.4,
      isIgnored: true,
    );

    final plan = healthWeightDeviceSync(
      deviceId: 'phone',
      stored: {
        'id': (sample: ignored, devices: {'tablet'}),
      },
      inHealth: {
        'id': HealthWeightSample(recordedAt: recordedAt, weightKg: 81.4),
      },
      mirrorSince: recordedAt.subtract(const Duration(days: 30)),
      activeDevices: {'phone', 'tablet'},
    );

    expect(plan.writes['id']?.sample.isIgnored, isTrue);
    expect(plan.writes['id']?.devices, {'tablet', 'phone'});
  });

  test('a copy without the flag counts', () {
    final sample = HealthWeightSample.fromJson({
      'recordedAt': recordedAt,
      'weightKg': 81.4,
      'fromThisApp': false,
    });

    expect(sample.isIgnored, isFalse);
    expect(
      HealthWeightSample(
        recordedAt: recordedAt,
        weightKg: 81.4,
        isIgnored: true,
      ).toJson()['ignored'],
      isTrue,
    );
  });
}
