import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

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
    );

    await repository.addSamples([
      HealthWeightSample(
        recordedAt: DateTime(2026, 3, 21, 7, 5),
        weightKg: 80.4,
        sourcePackageName: 'com.scale',
      ),
      HealthWeightSample(recordedAt: DateTime(2026, 3, 20, 7), weightKg: 80.9),
    ]);
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
      );
      final measurement = HealthWeightSample(
        recordedAt: DateTime(2026, 3, 20, 7, 0, 12),
        weightKg: 80.9,
        sourcePackageName: 'com.android.scale',
      );

      await repository.addSamples([
        measurement,
        HealthWeightSample(
          recordedAt: DateTime(2026, 3, 20, 7, 0, 48),
          weightKg: 80.9,
          sourcePackageName: 'com.apple.scale',
        ),
      ]);
      await pumpEventQueue();
      await repository.addSamples([measurement]);
      await pumpEventQueue();

      expect(await storedDocuments(firestore), hasLength(1));
    },
  );

  test('refuses to store without a signed-in user', () async {
    final repository = HealthWeightSampleRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: null,
    );

    await expectLater(
      repository.addSamples([
        HealthWeightSample(recordedAt: DateTime(2026, 3, 20), weightKg: 80),
      ]),
      throwsStateError,
    );
  });

  group('watchSamples', () {
    test('delivers the stored samples, also those of other devices', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = HealthWeightSampleRepository(
        firestore: firestore,
        dataCipher: signedIn,
      );
      final samples = repository.watchSamples();

      await repository.addSamples([
        HealthWeightSample(
          recordedAt: DateTime(2026, 3, 21, 7, 5),
          weightKg: 80.4,
          sourcePackageName: 'com.scale',
        ),
      ]);
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
      );

      expect(await repository.watchSamples().first, isEmpty);
    });
  });

  test('a saved sample is not stored again by the sync', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = HealthWeightSampleRepository(
      firestore: firestore,
      dataCipher: signedIn,
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
    await repository.addSamples([sample]);
    await pumpEventQueue();

    expect(await storedDocuments(firestore), hasLength(1));
  });

  test('a corrected app weight replaces the earlier one of that day', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = HealthWeightSampleRepository(
      firestore: firestore,
      dataCipher: signedIn,
    );
    await repository.addSamples([
      HealthWeightSample(recordedAt: DateTime(2026, 3, 20, 7), weightKg: 80.9),
    ]);
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
      for (final sample in await repository.readSamples()) sample.weightKg,
    ]..sort();
    // The scale weight of that day stays.
    expect(weights, [80.9, 81]);
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
