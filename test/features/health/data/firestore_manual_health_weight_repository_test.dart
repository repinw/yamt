import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/health/data/'
    'firestore_manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

void main() {
  late UserDataCipher signedIn;

  setUpAll(() async {
    signedIn = (
      uid: 'user-1',
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  });

  test('saveEntry stores an encrypted day document', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreManualHealthWeightRepository(
      firestore: firestore,
      dataCipher: signedIn,
    );

    final saved = await repository.saveEntry(
      ManualHealthWeightEntry(day: DateTime(2026, 3, 20, 18), weightKg: 71.2),
    );
    final entries = await repository.readEntries();
    final stored =
        (await firestore.doc('users/user-1/health_weights/2026-03-20').get())
            .data()!;

    expect(saved, isTrue);
    expect(entries, hasLength(1));
    expect(entries.single.day, DateTime(2026, 3, 20));
    expect(entries.single.weightKg, 71.2);
    expect(stored.keys, <String>['payload']);
    expect(stored['payload'], isNot(contains('71.2')));
  });

  test('readEntries skips documents it cannot decrypt', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreManualHealthWeightRepository(
      firestore: firestore,
      dataCipher: signedIn,
    );
    await repository.saveEntry(
      ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 71.2),
    );
    await firestore.doc('users/user-1/health_weights/2026-03-21').set(
      <String, dynamic>{'day': '2026-03-21', 'weightKg': 70.9},
    );

    final entries = await repository.readEntries();

    expect(entries.map((entry) => entry.weightKg), <double>[71.2]);
  });

  test('deleteEntryForDay removes persisted day document', () async {
    final repository = FirestoreManualHealthWeightRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: signedIn,
    );
    await repository.saveEntry(
      ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 71.2),
    );

    final deleted = await repository.deleteEntryForDay(
      DateTime(2026, 3, 20, 9),
    );
    final entries = await repository.readEntries();

    expect(deleted, isTrue);
    expect(entries, isEmpty);
  });

  test('returns safe defaults when firestore or data key missing', () async {
    final noFirestoreRepository = FirestoreManualHealthWeightRepository(
      firestore: null,
      dataCipher: signedIn,
    );
    final noKeyRepository = FirestoreManualHealthWeightRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: null,
    );
    final entry = ManualHealthWeightEntry(
      day: DateTime(2026, 3, 20),
      weightKg: 71.2,
    );

    expect(await noFirestoreRepository.readEntries(), isEmpty);
    expect(await noFirestoreRepository.saveEntry(entry), isFalse);
    expect(
      await noFirestoreRepository.deleteEntryForDay(DateTime(2026, 3, 20)),
      isFalse,
    );

    expect(await noKeyRepository.readEntries(), isEmpty);
    expect(await noKeyRepository.saveEntry(entry), isFalse);
    expect(
      await noKeyRepository.deleteEntryForDay(DateTime(2026, 3, 20)),
      isFalse,
    );
  });
}
