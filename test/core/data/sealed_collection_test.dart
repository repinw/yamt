import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/data/sealed_collection.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SealedCollection collection;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    collection = SealedCollection(
      firestore.collection('users/u1/inventory_items'),
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
      plaintextFields: const <String>['origin'],
    );
  });

  test('sealed documents open again and keep query fields', () async {
    final sealed = await collection.sealAll(<String, Map<String, dynamic>>{
      'a': <String, dynamic>{'name': 'Milch', 'origin': 'manualAdd'},
      'b': <String, dynamic>{'name': 'Brot'},
    });
    for (final entry in sealed.entries) {
      await collection.reference.doc(entry.key).set(entry.value);
    }

    final raw = await collection.reference.doc('a').get();
    expect(
      raw.data()!.keys,
      unorderedEquals(<String>[encryptedPayloadField, 'origin']),
    );
    expect(await collection.open(raw), <String, dynamic>{
      'name': 'Milch',
      'origin': 'manualAdd',
    });
    final opened = await collection.openAll(await collection.reference.get());
    expect(opened.map((document) => document.id), <String>['a', 'b']);
  });

  test('openAll fails for a plaintext document', () async {
    await collection.reference.doc('plain').set(<String, dynamic>{
      'name': 'Milch',
    });

    await expectLater(
      collection.openAll(await collection.reference.get()),
      throwsFormatException,
    );
  });

  test('openAll fails for a document copied from another path', () async {
    await collection.reference
        .doc('moved')
        .set(await collection.seal('other', <String, dynamic>{'name': 'Brot'}));

    await expectLater(
      collection.openAll(await collection.reference.get()),
      throwsA(anything),
    );
  });

  test('ensureAllSealed fails while a plaintext document exists', () async {
    await collection.reference
        .doc('a')
        .set(await collection.seal('a', <String, dynamic>{'name': 'Brot'}));
    await collection.ensureAllSealed();

    await collection.reference.doc('plain').set(<String, dynamic>{
      'name': 'Milch',
    });

    await expectLater(collection.ensureAllSealed(), throwsStateError);
  });
}
