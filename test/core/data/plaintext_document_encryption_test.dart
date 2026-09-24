import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late PayloadCipher cipher;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    cipher = PayloadCipher(await PayloadCipher.newDataKey());
  });

  Future<void> migrate() {
    return encryptPlaintextDocuments(
      firestore: firestore,
      cipher: cipher,
      collections: const <EncryptedCollection>[
        EncryptedCollection(
          'users/u1/calorie_entries',
          plaintextFields: <String>['logged_at'],
        ),
      ],
      fields: const <EncryptedDocumentField>[
        EncryptedDocumentField('users/u1', 'burn_week_run_state'),
      ],
    );
  }

  test('encrypts plaintext documents and keeps query fields', () async {
    final loggedAt = DateTime(2026, 9, 24, 8);
    final entries = firestore.collection('users/u1/calorie_entries');
    await entries.doc('e1').set(<String, dynamic>{
      'name': 'Nutella',
      'total_kcal': 539,
      'logged_at': Timestamp.fromDate(loggedAt),
    });

    await migrate();

    final stored = (await entries.doc('e1').get()).data()!;
    expect(stored.keys, unorderedEquals(<String>['payload', 'logged_at']));
    expect((stored['logged_at'] as Timestamp).toDate(), loggedAt);
    final decrypted = await cipher.decryptJson(
      stored['payload'] as String,
      aad: 'users/u1/calorie_entries/e1',
    );
    expect(decrypted, <String, dynamic>{
      'name': 'Nutella',
      'total_kcal': 539,
      'logged_at': loggedAt,
    });
  });

  test('encrypts a map field and leaves other fields alone', () async {
    await firestore.doc('users/u1').set(<String, dynamic>{
      'uid': 'u1',
      'burn_week_run_state': <String, dynamic>{'active': true},
    });

    await migrate();

    final stored = (await firestore.doc('users/u1').get()).data()!;
    expect(stored['uid'], 'u1');
    final decrypted = await cipher.decryptJson(
      stored['burn_week_run_state'] as String,
      aad: 'users/u1#burn_week_run_state',
    );
    expect(decrypted, <String, dynamic>{'active': true});
  });

  test('leaves encrypted documents unchanged on a second run', () async {
    final entries = firestore.collection('users/u1/calorie_entries');
    await entries.doc('e1').set(<String, dynamic>{'name': 'Apfel'});
    await firestore.doc('users/u1').set(<String, dynamic>{
      'burn_week_run_state': <String, dynamic>{'active': false},
    });
    await migrate();
    final entryAfterFirstRun = (await entries.doc('e1').get()).data();
    final userAfterFirstRun = (await firestore.doc('users/u1').get()).data();

    await migrate();

    expect((await entries.doc('e1').get()).data(), entryAfterFirstRun);
    expect((await firestore.doc('users/u1').get()).data(), userAfterFirstRun);
  });
}
