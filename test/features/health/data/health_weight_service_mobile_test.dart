import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:yamt/features/health/data/health_weight_service_mobile.dart';

void main() {
  test(
    'queries weights through now for recent past ranges and filters locally',
    () async {
      final now = DateTime(2026, 4, 27, 12);
      final requestedStart = DateTime(2026, 4, 8);
      final requestedEnd = DateTime(2026, 4, 23);
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataPoint>[
          _buildWeightPoint(
            recordedAt: DateTime(2026, 4, 14, 8),
            weightKg: 83.5,
          ),
          _buildWeightPoint(
            recordedAt: DateTime(2026, 4, 24, 8),
            weightKg: 82.7,
          ),
        ],
      );
      final service = MobileHealthWeightService(
        health: fakeHealth,
        now: () => now,
      );

      final samples = await service.loadWeightSamples(
        startInclusive: requestedStart,
        endExclusive: requestedEnd,
      );
      final cachedSamples = await service.loadWeightSamples(
        startInclusive: requestedStart,
        endExclusive: requestedEnd,
      );

      expect(fakeHealth.requestedStartTimes.single, requestedStart);
      expect(fakeHealth.requestedEndTimes.single, now);
      expect(samples, hasLength(1));
      expect(samples.single.recordedAt, DateTime(2026, 4, 14, 8));
      expect(samples.single.weightKg, 83.5);
      expect(cachedSamples, hasLength(1));
      expect(fakeHealth.requestedEndTimes, hasLength(1));
    },
  );

  test('caches future requests after querying only through now', () async {
    final now = DateTime(2026, 4, 28, 12);
    final requestedStart = DateTime(2026, 4, 27);
    final requestedEnd = DateTime(2026, 5, 3);
    final fakeHealth = _FakeHealth(
      healthDataPoints: <HealthDataPoint>[
        _buildWeightPoint(
          recordedAt: DateTime(2026, 4, 27, 8),
          weightKg: 83.5,
        ),
        _buildWeightPoint(
          recordedAt: DateTime(2026, 4, 29, 8),
          weightKg: 83.2,
        ),
      ],
    );
    final service = MobileHealthWeightService(
      health: fakeHealth,
      now: () => now,
    );

    final samples = await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );
    final cachedSamples = await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );

    expect(fakeHealth.requestedStartTimes.single, requestedStart);
    expect(fakeHealth.requestedEndTimes.single, now);
    expect(samples, hasLength(1));
    expect(cachedSamples, hasLength(1));
  });

  test('keeps exact query end for old historical ranges', () async {
    final now = DateTime(2026, 4, 27, 12);
    final requestedStart = DateTime(2024);
    final requestedEnd = DateTime(2024, 2);
    final fakeHealth = _FakeHealth(
      healthDataPoints: <HealthDataPoint>[
        _buildWeightPoint(
          recordedAt: DateTime(2024, 1, 14, 8),
          weightKg: 83.5,
        ),
        _buildWeightPoint(
          recordedAt: DateTime(2026, 4, 24, 8),
          weightKg: 82.7,
        ),
      ],
    );
    final service = MobileHealthWeightService(
      health: fakeHealth,
      now: () => now,
    );

    final samples = await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );

    expect(fakeHealth.requestedStartTimes.single, requestedStart);
    expect(fakeHealth.requestedEndTimes.single, requestedEnd);
    expect(samples, hasLength(1));
    expect(samples.single.recordedAt, DateTime(2024, 1, 14, 8));
  });

  test('refreshes cache after ttl expires', () async {
    var now = DateTime(2026, 4, 27, 12);
    final requestedStart = DateTime(2026, 4, 8);
    final requestedEnd = DateTime(2026, 4, 23);
    final healthDataPoints = <HealthDataPoint>[
      _buildWeightPoint(
        recordedAt: DateTime(2026, 4, 14, 8),
        weightKg: 83.5,
      ),
    ];
    final fakeHealth = _FakeHealth(healthDataPoints: healthDataPoints);
    final service = MobileHealthWeightService(
      health: fakeHealth,
      now: () => now,
    );

    final firstRead = await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );
    healthDataPoints.add(
      _buildWeightPoint(
        recordedAt: DateTime(2026, 4, 15, 8),
        weightKg: 83.2,
      ),
    );
    now = now.add(const Duration(minutes: 6));
    final secondRead = await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );

    expect(firstRead, hasLength(1));
    expect(secondRead, hasLength(2));
    expect(fakeHealth.requestedEndTimes, hasLength(2));
  });

  test('refreshes cache for out-of-bounds requests', () async {
    final now = DateTime(2026, 4, 27, 12);
    final firstStart = DateTime(2026, 4, 8);
    final secondStart = DateTime(2026, 4, 7);
    final requestedEnd = DateTime(2026, 4, 23);
    final fakeHealth = _FakeHealth(
      healthDataPoints: <HealthDataPoint>[
        _buildWeightPoint(
          recordedAt: DateTime(2026, 4, 7, 8),
          weightKg: 84.5,
        ),
        _buildWeightPoint(
          recordedAt: DateTime(2026, 4, 14, 8),
          weightKg: 83.5,
        ),
      ],
    );
    final service = MobileHealthWeightService(
      health: fakeHealth,
      now: () => now,
    );

    final firstRead = await service.loadWeightSamples(
      startInclusive: firstStart,
      endExclusive: requestedEnd,
    );
    final secondRead = await service.loadWeightSamples(
      startInclusive: secondStart,
      endExclusive: requestedEnd,
    );

    expect(firstRead, hasLength(1));
    expect(secondRead, hasLength(2));
    expect(fakeHealth.requestedStartTimes, <DateTime>[
      firstStart,
      secondStart,
    ]);
  });

  test('clears cache after successful weight write', () async {
    final now = DateTime(2026, 4, 27, 12);
    final requestedStart = DateTime(2026, 4, 8);
    final requestedEnd = DateTime(2026, 4, 23);
    final fakeHealth = _FakeHealth(
      healthDataPoints: <HealthDataPoint>[
        _buildWeightPoint(
          recordedAt: DateTime(2026, 4, 14, 8),
          weightKg: 83.5,
        ),
      ],
    );
    final service = MobileHealthWeightService(
      health: fakeHealth,
      now: () => now,
    );

    await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );
    final saved = await service.saveWeightSample(
      recordedAt: DateTime(2026, 4, 15, 8),
      weightKg: 83.2,
    );
    await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );

    expect(saved, isTrue);
    expect(fakeHealth.writeCalls, 1);
    expect(fakeHealth.requestedEndTimes, hasLength(2));
  });

  test('keeps cache when weight write returns false', () async {
    final now = DateTime(2026, 4, 27, 12);
    final requestedStart = DateTime(2026, 4, 8);
    final requestedEnd = DateTime(2026, 4, 23);
    final healthDataPoints = <HealthDataPoint>[
      _buildWeightPoint(
        recordedAt: DateTime(2026, 4, 14, 8),
        weightKg: 83.5,
      ),
    ];
    final fakeHealth = _FakeHealth(
      healthDataPoints: healthDataPoints,
      writeSucceeds: false,
    );
    final service = MobileHealthWeightService(
      health: fakeHealth,
      now: () => now,
    );

    await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );
    healthDataPoints.add(
      _buildWeightPoint(
        recordedAt: DateTime(2026, 4, 15, 8),
        weightKg: 83.2,
      ),
    );
    final saved = await service.saveWeightSample(
      recordedAt: DateTime(2026, 4, 15, 8),
      weightKg: 83.2,
    );
    final cachedSamples = await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );

    expect(saved, isFalse);
    expect(cachedSamples, hasLength(1));
    expect(fakeHealth.writeCalls, 1);
    expect(fakeHealth.requestedEndTimes, hasLength(1));
  });

  test('keeps cache when weight write throws', () async {
    final now = DateTime(2026, 4, 27, 12);
    final requestedStart = DateTime(2026, 4, 8);
    final requestedEnd = DateTime(2026, 4, 23);
    final healthDataPoints = <HealthDataPoint>[
      _buildWeightPoint(
        recordedAt: DateTime(2026, 4, 14, 8),
        weightKg: 83.5,
      ),
    ];
    final fakeHealth = _FakeHealth(
      healthDataPoints: healthDataPoints,
      writeError: Exception('weight write failed'),
    );
    final service = MobileHealthWeightService(
      health: fakeHealth,
      now: () => now,
    );

    await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );
    healthDataPoints.add(
      _buildWeightPoint(
        recordedAt: DateTime(2026, 4, 15, 8),
        weightKg: 83.2,
      ),
    );
    await expectLater(
      service.saveWeightSample(
        recordedAt: DateTime(2026, 4, 15, 8),
        weightKg: 83.2,
      ),
      throwsA(isA<Exception>()),
    );
    final cachedSamples = await service.loadWeightSamples(
      startInclusive: requestedStart,
      endExclusive: requestedEnd,
    );

    expect(cachedSamples, hasLength(1));
    expect(fakeHealth.writeCalls, 1);
    expect(fakeHealth.requestedEndTimes, hasLength(1));
  });
}

class _FakeHealth extends Health {
  _FakeHealth({
    required this.healthDataPoints,
    this.writeSucceeds = true,
    this.writeError,
  });

  final List<HealthDataPoint> healthDataPoints;
  final bool writeSucceeds;
  final Exception? writeError;
  final List<DateTime> requestedStartTimes = <DateTime>[];
  final List<DateTime> requestedEndTimes = <DateTime>[];
  int writeCalls = 0;

  @override
  Future<void> configure() async {}

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    requestedStartTimes.add(startTime);
    requestedEndTimes.add(endTime);
    return healthDataPoints
        .where((point) => types.contains(point.type))
        .where(
          (point) =>
              !point.dateFrom.isBefore(startTime) &&
              point.dateFrom.isBefore(endTime),
        )
        .toList(growable: false);
  }

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    return true;
  }

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    return true;
  }

  @override
  Future<bool> writeHealthData({
    required double value,
    required HealthDataType type,
    required DateTime startTime,
    HealthDataUnit? unit,
    String? clientRecordId,
    double? clientRecordVersion,
    DateTime? endTime,
    RecordingMethod recordingMethod = RecordingMethod.automatic,
  }) async {
    writeCalls += 1;
    final error = writeError;
    if (error != null) {
      throw error;
    }
    return writeSucceeds;
  }
}

HealthDataPoint _buildWeightPoint({
  required DateTime recordedAt,
  required double weightKg,
}) {
  return HealthDataPoint(
    uuid: 'weight-${recordedAt.millisecondsSinceEpoch}',
    value: NumericHealthValue(numericValue: weightKg),
    type: HealthDataType.WEIGHT,
    unit: HealthDataUnit.KILOGRAM,
    dateFrom: recordedAt,
    dateTo: recordedAt,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'device-id',
    sourceId: 'health-connect',
    sourceName: 'Health Connect',
  );
}
