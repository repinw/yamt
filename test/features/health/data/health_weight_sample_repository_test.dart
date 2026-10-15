import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

import '../../../helpers/memory_app_preferences.dart';

final _longAgo = DateTime(2000);

void main() {
  late UserDataCipher signedIn;

  setUpAll(() async {
    signedIn = (
      uid: 'user-1',
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  });

  Future<List<Map<String, dynamic>>> storedDocuments(
    FakeFirebaseFirestore firestore,
  ) async {
    final snapshot = await firestore
        .collection('users/user-1/health_weight_samples')
        .get();
    return [for (final document in snapshot.docs) document.data()];
  }

  test('stores every sample encrypted, without readable fields', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = HealthWeightSampleRepository(
      firestore: firestore,
      dataCipher: signedIn,
      preferences: MemoryAppPreferences(),
    );

    await repository.syncDevice(
      loadHealth: () async => [
        HealthWeightSample(
          recordedAt: DateTime(2026, 3, 21, 7, 5),
          weightKg: 80.4,
          sourcePackageName: 'com.scale',
        ),
        HealthWeightSample(
          recordedAt: DateTime(2026, 3, 20, 7),
          weightKg: 80.9,
        ),
      ],
      mirrorSince: _longAgo,
      activeDevices: const {},
    );
    await pumpEventQueue();

    final stored = await storedDocuments(firestore);
    expect(stored, hasLength(2));
    for (final document in stored) {
      expect(document.keys, <String>['payload']);
      // Base64 has no dot, so a readable weight would show here.
      expect(document['payload'], isNot(contains('80.4')));
      expect(document['payload'], isNot(contains('com.scale')));
    }
  });

  test(
    'stores one document per minute and weight, whatever the source',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = HealthWeightSampleRepository(
        firestore: firestore,
        dataCipher: signedIn,
        preferences: MemoryAppPreferences(),
      );
      final measurement = HealthWeightSample(
        recordedAt: DateTime(2026, 3, 20, 7, 0, 12),
        weightKg: 80.9,
        sourcePackageName: 'com.android.scale',
      );

      await repository.syncDevice(
        loadHealth: () async => [
          measurement,
          HealthWeightSample(
            recordedAt: DateTime(2026, 3, 20, 7, 0, 48),
            weightKg: 80.9,
            sourcePackageName: 'com.apple.scale',
          ),
        ],
        mirrorSince: _longAgo,
        activeDevices: const {},
      );
      await pumpEventQueue();
      await repository.syncDevice(
        loadHealth: () async => [measurement],
        mirrorSince: _longAgo,
        activeDevices: const {},
      );
      await pumpEventQueue();

      expect(await storedDocuments(firestore), hasLength(1));
    },
  );

  test('refuses to store without a signed-in user', () async {
    final repository = HealthWeightSampleRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: null,
      preferences: MemoryAppPreferences(),
    );

    await expectLater(
      repository.syncDevice(
        loadHealth: () async => [
          HealthWeightSample(recordedAt: DateTime(2026, 3, 20), weightKg: 80),
        ],
        mirrorSince: _longAgo,
        activeDevices: const {},
      ),
      throwsStateError,
    );
  });

  group('watchSamples', () {
    test('delivers the stored samples, also those of other devices', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = HealthWeightSampleRepository(
        firestore: firestore,
        dataCipher: signedIn,
        preferences: MemoryAppPreferences(),
      );
      final samples = repository.watchSamples();

      await repository.syncDevice(
        loadHealth: () async => [
          HealthWeightSample(
            recordedAt: DateTime(2026, 3, 21, 7, 5),
            weightKg: 80.4,
            sourcePackageName: 'com.scale',
          ),
        ],
        mirrorSince: _longAgo,
        activeDevices: const {},
      );
      await repository.saveAppWeight(
        recordedAt: DateTime(2026, 3, 22, 7),
        weightKg: 80,
      );

      final stored = [...await samples.firstWhere((list) => list.length == 2)]
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      expect(stored.first.recordedAt, DateTime(2026, 3, 21, 7, 5));
      expect(stored.first.weightKg, 80.4);
      expect(stored.first.sourcePackageName, 'com.scale');
      expect(stored.last.weightKg, 80);
    });

    test('drops a deleted sample and skips a malformed one', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = HealthWeightSampleRepository(
        firestore: firestore,
        dataCipher: signedIn,
        preferences: MemoryAppPreferences(),
      );
      final sample = HealthWeightSample(
        recordedAt: DateTime(2026, 3, 21, 7, 5, 30),
        weightKg: 80.4,
      );
      await repository.saveAppWeight(
        recordedAt: sample.recordedAt,
        weightKg: sample.weightKg,
      );
      await firestore
          .collection('users/user-1/health_weight_samples')
          .doc('broken')
          .set({'payload': 'not encrypted'});
      final samples = repository.watchSamples();
      expect(await samples.first, hasLength(1));

      await repository.deleteSample(
        // Another reading of the same measurement finds the same document.
        HealthWeightSample(
          recordedAt: DateTime(2026, 3, 21, 7, 5),
          weightKg: 80.4,
        ),
      );

      expect(await samples.firstWhere((list) => list.isEmpty), isEmpty);
    });

    test('delivers a failed read as an error', () async {
      final repository = HealthWeightSampleRepository(
        firestore: _DeniedFirestore(),
        dataCipher: signedIn,
        preferences: MemoryAppPreferences(),
      );

      await expectLater(
        repository.watchSamples().first,
        throwsA(isA<FirebaseException>()),
      );
    });

    test('delivers no samples without a signed-in user', () async {
      final repository = HealthWeightSampleRepository(
        firestore: FakeFirebaseFirestore(),
        dataCipher: null,
        preferences: MemoryAppPreferences(),
      );

      expect(await repository.watchSamples().first, isEmpty);
    });
  });

  test('a saved sample is not stored again by the sync', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = HealthWeightSampleRepository(
      firestore: firestore,
      dataCipher: signedIn,
      preferences: MemoryAppPreferences(),
    );
    final sample = HealthWeightSample(
      recordedAt: DateTime(2026, 3, 21, 12),
      weightKg: 79.8,
    );

    await repository.saveAppWeight(
      recordedAt: sample.recordedAt,
      weightKg: sample.weightKg,
    );
    await pumpEventQueue();
    await repository.syncDevice(
      loadHealth: () async => [sample],
      mirrorSince: _longAgo,
      activeDevices: const {},
    );
    await pumpEventQueue();

    expect(await storedDocuments(firestore), hasLength(1));
  });

  test('a corrected app weight replaces the earlier one of that day', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = HealthWeightSampleRepository(
      firestore: firestore,
      dataCipher: signedIn,
      preferences: MemoryAppPreferences(),
    );
    await repository.syncDevice(
      loadHealth: () async => [
        HealthWeightSample(
          recordedAt: DateTime(2026, 3, 20, 7),
          weightKg: 80.9,
        ),
      ],
      mirrorSince: _longAgo,
      activeDevices: const {},
    );
    await repository.saveAppWeight(
      recordedAt: DateTime(2026, 3, 20, 12),
      weightKg: 80,
    );
    await pumpEventQueue();

    await repository.saveAppWeight(
      recordedAt: DateTime(2026, 3, 20, 12),
      weightKg: 81,
    );
    await pumpEventQueue();

    final weights = [
      for (final sample in await repository.loadSamples()) sample.weightKg,
    ]..sort();
    // The scale weight of that day stays.
    expect(weights, [80.9, 81]);
  });

  group('mirrors Health deletions', () {
    final scale = HealthWeightSample(
      recordedAt: DateTime(2026, 3, 20, 7),
      weightKg: 80.9,
    );
    // A later weighing that stays, so the Health read is not empty.
    final kept = HealthWeightSample(
      recordedAt: DateTime(2026, 3, 25, 7),
      weightKg: 80.2,
    );
    late FakeFirebaseFirestore firestore;
    late HealthWeightSampleRepository phone;
    late HealthWeightSampleRepository tablet;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      phone = _device(firestore, signedIn, 'phone');
      tablet = _device(firestore, signedIn, 'tablet');
    });

    Future<void> sync(
      HealthWeightSampleRepository device,
      List<HealthWeightSample> samples, {
      DateTime? mirrorSince,
      Set<String> activeDevices = const {'phone', 'tablet'},
    }) async {
      await device.syncDevice(
        loadHealth: () async => samples,
        mirrorSince: mirrorSince ?? DateTime(2026, 3),
        activeDevices: activeDevices,
      );
      await pumpEventQueue();
    }

    Future<List<double>> weights() async =>
        [for (final sample in await phone.loadSamples()) sample.weightKg]
          ..sort();

    test('deletes a sample once no device holds it', () async {
      await sync(phone, [scale, kept]);
      await sync(tablet, [scale, kept]);

      await sync(phone, [kept]);
      expect(await weights(), [80.2, 80.9]);

      await sync(tablet, [kept]);
      expect(await weights(), [80.2]);
    });

    test('keeps samples from before the mirrored days', () async {
      await sync(phone, [scale, kept]);

      await sync(phone, [kept], mirrorSince: DateTime(2026, 3, 21));

      expect(await weights(), [80.2, 80.9]);
    });

    test('mirrors nothing when Health returns no recent weight', () async {
      await sync(phone, [scale, kept]);

      // As after a lost read access, not a deletion of every weighing.
      await sync(phone, []);

      expect(await weights(), [80.2, 80.9]);
    });

    test('a weight saved while the sync loads Health stays', () async {
      await sync(phone, [kept]);

      await phone.syncDevice(
        loadHealth: () async {
          // Saved after the sync read the copies, before Health answered.
          await phone.saveAppWeight(
            recordedAt: DateTime(2026, 3, 26, 12),
            weightKg: 79.9,
          );
          await pumpEventQueue();
          return [kept];
        },
        mirrorSince: DateTime(2026, 3),
        activeDevices: const {'phone'},
      );
      await pumpEventQueue();

      expect(await weights(), [79.9, 80.2]);
    });

    test('a weight deleted in the app is gone at once', () async {
      await sync(phone, [scale, kept]);
      await sync(tablet, [scale, kept]);

      await phone.deleteSample(scale);
      await pumpEventQueue();

      expect(await weights(), [80.2]);
    });

    test(
      'a reinstalled device deletes what only its old install held',
      () async {
        final oldInstall = _device(firestore, signedIn, 'old-phone');
        await sync(oldInstall, [scale, kept]);
        await sync(phone, [scale, kept]);

        // The old install no longer records its version, so it is inactive.
        await sync(phone, [kept], activeDevices: const {'phone'});

        expect(await weights(), [80.2]);
      },
    );

    test('an app weight replaces only the earlier one of its device', () async {
      await phone.saveAppWeight(
        recordedAt: DateTime(2026, 3, 20, 12),
        weightKg: 80,
      );
      await tablet.saveAppWeight(
        recordedAt: DateTime(2026, 3, 20, 12, 1),
        weightKg: 79.5,
      );
      await pumpEventQueue();

      await phone.saveAppWeight(
        recordedAt: DateTime(2026, 3, 20, 12),
        weightKg: 81,
      );
      await pumpEventQueue();

      final weights = [
        for (final sample in await phone.loadSamples()) sample.weightKg,
      ]..sort();
      expect(weights, [79.5, 81]);
    });
  });
}

/// Denies every read of the samples, like the rules before their deploy.
class _DeniedFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _DeniedCollection();
}

// ignore: subtype_of_sealed_class, a fake that only fails the read.
class _DeniedCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _DeniedDocument();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.error(
    FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
  );
}

// ignore: subtype_of_sealed_class, a fake that only fails the read.
class _DeniedDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _DeniedCollection();
}

HealthWeightSampleRepository _device(
  FakeFirebaseFirestore firestore,
  UserDataCipher signedIn,
  String installId,
) {
  return HealthWeightSampleRepository(
    firestore: firestore,
    dataCipher: signedIn,
    preferences: MemoryAppPreferences(
      initialStrings: {'app_install_id_v1': installId},
    ),
  );
}
