import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_entry_document_codec.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

CalorieEntry _createEntry(String id, {String? imageUrl}) {
  final now = DateTime.utc(2026, 3, 20, 12);
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Banana',
    imageUrl: imageUrl,
    mealType: MealType.snack,
    consumedAmount: 120,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 89,
    per100Protein: 1.1,
    per100Carbs: 23,
    per100Fat: 0.3,
    loggedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CalorieEntryDocumentCodec', () {
    late FakeFirebaseFirestore firestore;
    late PayloadCipher cipher;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      cipher = PayloadCipher(await PayloadCipher.newDataKey());
    });

    Future<void> store(CalorieEntry entry) async {
      final reference = firestore.collection('entries').doc(entry.id);
      await reference.set(
        await encodeCalorieEntryDocument(
          entry,
          reference: reference,
          cipher: cipher,
        ),
      );
    }

    test('stores only the payload and logged_at', () async {
      final entry = _createEntry('entry-1');

      await store(entry);

      final stored = (await firestore.doc('entries/entry-1').get()).data()!;
      expect(stored.keys, unorderedEquals(<String>['payload', 'logged_at']));
      expect(
        (stored['logged_at'] as Timestamp).toDate(),
        entry.loggedAt.toLocal(),
      );
      expect(stored['payload'], isNot(contains('Banana')));
    });

    test('decodeCalorieEntryDocument decrypts a stored entry', () async {
      await store(_createEntry('entry-1'));

      final snapshot = await firestore.doc('entries/entry-1').get();
      final decoded = await decodeCalorieEntryDocument(
        snapshot,
        cipher: cipher,
      );

      expect(decoded.id, 'entry-1');
      expect(decoded.name, 'Banana');
      expect(decoded.consumedAmount, 120);
    });

    test('decodeCalorieEntrySnapshot skips malformed documents', () async {
      await store(_createEntry('entry-1'));
      await firestore
          .collection('entries')
          .doc('plaintext')
          .set(_createEntry('plaintext').toJson());
      await firestore.collection('entries').doc('other-key').set(
        <String, dynamic>{
          'payload': await PayloadCipher(await PayloadCipher.newDataKey())
              .encryptJson(<String, dynamic>{}, aad: 'entries/other-key'),
        },
      );

      final querySnapshot = await firestore.collection('entries').get();
      final malformedIds = <String>[];
      final entries = await decodeCalorieEntrySnapshot(
        querySnapshot,
        cipher: cipher,
        onMalformed: (docId, error, stackTrace) => malformedIds.add(docId),
      );

      expect(entries.map((entry) => entry.id), <String>['entry-1']);
      expect(malformedIds, unorderedEquals(<String>['plaintext', 'other-key']));
    });

    test(
      'prepareCalorieEntryForSave sets userId, updatedAt, normalizes imageUrl',
      () {
        final entry = _createEntry(
          'entry-1',
          imageUrl: '  https://example.com/pic.jpg  ',
        );
        final updatedAt = DateTime.utc(2026, 3, 21, 10);

        final prepared = prepareCalorieEntryForSave(
          entry,
          userId: 'user-42',
          updatedAt: updatedAt,
        );

        expect(prepared.userId, 'user-42');
        expect(prepared.updatedAt, updatedAt);
        expect(prepared.imageUrl, 'https://example.com/pic.jpg');
      },
    );
  });
}
