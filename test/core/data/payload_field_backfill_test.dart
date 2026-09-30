import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/payload_field_backfill.dart';

void main() {
  const collectionPath = 'users/u1/calorie_entries';
  late FakeFirebaseFirestore firestore;
  late PayloadCipher cipher;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    cipher = PayloadCipher(await PayloadCipher.newDataKey());
  });

  Future<void> store(
    String id,
    Map<String, dynamic> data, {
    PayloadCipher? sealedWith,
  }) async {
    final reference = firestore.collection(collectionPath).doc(id);
    await reference.set(<String, dynamic>{
      'logged_at': DateTime(2026, 9, 20),
      'payload': await (sealedWith ?? cipher).encryptJson(
        data,
        aad: reference.path,
      ),
    });
  }

  Future<Map<String, dynamic>> open(String id) async {
    final reference = firestore.collection(collectionPath).doc(id);
    final snapshot = await reference.get();
    return await cipher.decryptJson(
      snapshot.data()!['payload'] as String,
      aad: reference.path,
    );
  }

  Future<void> backfill() {
    return backfillPayloadFields(
      collection: firestore.collection(collectionPath),
      cipher: cipher,
      defaults: const <String, Object?>{'is_quick_entry': false},
    );
  }

  test('adds a missing field and keeps the other fields', () async {
    await store('e1', <String, dynamic>{'name': 'Apfel', 'total_kcal': 52});

    await backfill();

    expect(await open('e1'), <String, dynamic>{
      'name': 'Apfel',
      'total_kcal': 52,
      'is_quick_entry': false,
    });
  });

  test('keeps a value that the document already holds', () async {
    await store('e1', <String, dynamic>{
      'name': 'Snack',
      'is_quick_entry': true,
    });

    await backfill();

    expect((await open('e1'))['is_quick_entry'], isTrue);
  });

  test('keeps the plaintext fields next to the payload', () async {
    await store('e1', <String, dynamic>{'name': 'Apfel'});

    await backfill();

    final snapshot = await firestore.doc('$collectionPath/e1').get();
    expect(
      snapshot.data()!.keys,
      unorderedEquals(<String>['logged_at', 'payload']),
    );
  });

  test('skips a document it cannot decrypt and migrates the rest', () async {
    final otherCipher = PayloadCipher(await PayloadCipher.newDataKey());
    await store('foreign', <String, dynamic>{
      'name': 'x',
    }, sealedWith: otherCipher);
    await store('e1', <String, dynamic>{'name': 'Apfel'});
    final foreignBefore = await firestore.doc('$collectionPath/foreign').get();

    await backfill();

    final foreignAfter = await firestore.doc('$collectionPath/foreign').get();
    expect(foreignAfter.data(), foreignBefore.data());
    expect((await open('e1'))['is_quick_entry'], isFalse);
  });
}
