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

  test('saveEntry keeps the day in the payload for 3.8.1', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreManualHealthWeightRepository(
      firestore: firestore,
      dataCipher: signedIn,
    );
    final recordedAt = DateTime(2026, 3, 20, 7, 12);

    await repository.saveEntry(
      ManualHealthWeightEntry(
        day: recordedAt,
        weightKg: 71.2,
        recordedAt: recordedAt,
      ),
    );
    final reference = firestore.doc('users/user-1/health_weights/2026-03-20');
    final payload = await signedIn.cipher.decryptJson(
      (await reference.get()).data()!['payload'] as String,
      aad: reference.path,
    );
    final entry = (await repository.readEntries()).single;

    expect(payload['day'], '2026-03-20');
    expect(payload['weightKg'], 71.2);
    expect(entry.recordedAt, recordedAt);
    expect(entry.id, '2026-03-20');
  });

  test('reads an entry of 3.8.1 without a time', () async {
    final repository = FirestoreManualHealthWeightRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: signedIn,
    );
    await repository.saveEntry(
      ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 71.2),
    );

    final entry = (await repository.readEntries()).single;

    expect(entry.recordedAt, isNull);
    expect(entry.day, DateTime(2026, 3, 20));
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

  test('updateEntry stores the entry under a new id and drops the day '
      'document', () async {
    final repository = FirestoreManualHealthWeightRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: signedIn,
    );
    await repository.saveEntry(
      ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 71.2),
    );
    final legacy = (await repository.readEntries()).single;
    final morning = DateTime(2026, 3, 20, 7);

    // The controller keeps the id; the repository moves the day document.
    final stored = await repository.updateEntry(
      legacy,
      ManualHealthWeightEntry(
        day: morning,
        weightKg: 71,
        recordedAt: morning,
        id: legacy.id,
      ),
    );
    final entries = await repository.readEntries();

    expect(stored.id, isNot('2026-03-20'));
    expect(entries.map((entry) => (entry.id, entry.weightKg)), [
      (stored.id, 71.0),
    ]);
  });

  test('updateEntry rewrites the document when the id stays', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreManualHealthWeightRepository(
      firestore: firestore,
      dataCipher: signedIn,
    );
    final morning = DateTime(2026, 3, 20, 7);
    final entry = ManualHealthWeightEntry(
      day: morning,
      weightKg: 71.2,
      recordedAt: morning,
      id: 'morning',
    );
    await repository.saveEntry(entry);
    await repository.saveEntry(
      ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 70),
    );

    await repository.updateEntry(
      entry,
      ManualHealthWeightEntry(
        day: morning,
        weightKg: 71,
        recordedAt: DateTime(2026, 3, 20, 8),
        id: 'morning',
      ),
    );
    final entries = await repository.readEntries();

    // The other weighing of the day stays.
    expect(entries.map((e) => (e.id, e.weightKg)), [
      ('2026-03-20', 70.0),
      ('morning', 71.0),
    ]);
    expect(
      entries.singleWhere((e) => e.id == 'morning').recordedAt,
      DateTime(2026, 3, 20, 8),
    );
  });

  test('keeps the day it was stored under in any time zone', () async {
    final entry = ManualHealthWeightEntry.fromJson({
      'day': '2026-03-20',
      'weightKg': 71.2,
      // Two days off in every zone, so only the stored day can give the 20th.
      'recordedAt': '2026-03-22T12:00:00.000Z',
    }, id: 'late')!;

    expect(entry.day, DateTime(2026, 3, 20));
  });

  test('deleteEntry deletes only that weighing', () async {
    final repository = FirestoreManualHealthWeightRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: signedIn,
    );
    final evening = DateTime(2026, 3, 20, 21, 40);
    final eveningEntry = ManualHealthWeightEntry(
      day: evening,
      weightKg: 71.9,
      recordedAt: evening,
      id: 'evening',
    );
    await repository.saveEntry(
      ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 71.2),
    );
    await repository.saveEntry(eveningEntry);

    await repository.deleteEntry(eveningEntry);
    final entries = await repository.readEntries();

    expect(entries.map((entry) => entry.weightKg), <double>[71.2]);
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
      () => noFirestoreRepository.deleteEntry(entry),
      throwsA(isA<StateError>()),
    );

    expect(await noKeyRepository.readEntries(), isEmpty);
    expect(await noKeyRepository.saveEntry(entry), isFalse);
    expect(
      () => noKeyRepository.deleteEntry(entry),
      throwsA(isA<StateError>()),
    );
  });
}
