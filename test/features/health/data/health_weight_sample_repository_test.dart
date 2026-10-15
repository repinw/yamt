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
      expect(document['payload'], isNot(contains('80')));
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
}
