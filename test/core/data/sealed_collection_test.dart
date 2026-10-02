import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';
import 'package:yamt/core/data/payload_cipher.dart';
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

  test(
    'canDeleteStale allows a delete only when the document opens and parses',
    () async {
      Future<FirestoreStaleDeleteCandidate> candidate(
        String id,
        Map<String, dynamic> stored,
      ) async {
        await collection.reference.doc(id).set(stored);
        return FirestoreStaleDeleteCandidate(
          reference: collection.reference.doc(id),
          expectedData: stored,
        );
      }

      void parse(String id, Map<String, dynamic> data) {
        if (data['name'] == 'Broken') {
          throw const FormatException('broken');
        }
      }

      final readable = await candidate(
        'a',
        await collection.seal('a', <String, dynamic>{'name': 'Brot'}),
      );
      final broken = await candidate(
        'b',
        await collection.seal('b', <String, dynamic>{'name': 'Broken'}),
      );
      final plain = await candidate('c', <String, dynamic>{'name': 'Milch'});

      expect(await collection.canDeleteStale(readable, parse), isTrue);
      expect(await collection.canDeleteStale(broken, parse), isFalse);
      expect(await collection.canDeleteStale(plain, parse), isFalse);
    },
  );

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
