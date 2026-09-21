import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
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

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test(
      'decodeCalorieEntryDocument decodes valid document snapshot',
      () async {
        final entry = _createEntry('entry-1');
        final docRef = firestore.collection('entries').doc('entry-1');
        await docRef.set(entry.toJson());

        final snapshot = await docRef.get();
        final decoded = decodeCalorieEntryDocument(snapshot);

        expect(decoded.id, 'entry-1');
        expect(decoded.name, 'Banana');
        expect(decoded.consumedAmount, 120);
      },
    );

    test(
      'decodeCalorieEntrySnapshot decodes valid query and skips malformed',
      () async {
        final entry1 = _createEntry('entry-1');
        await firestore
            .collection('entries')
            .doc('entry-1')
            .set(entry1.toJson());
        // Malformed document: missing required fields
        await firestore.collection('entries').doc('bad-entry').set(
          <String, dynamic>{'id': 'bad-entry', 'consumed_amount': 'invalid'},
        );

        final querySnapshot = await firestore.collection('entries').get();
        final malformedIds = <String>[];

        final entries = decodeCalorieEntrySnapshot(
          querySnapshot,
          onMalformed: (docId, error, stackTrace) {
            malformedIds.add(docId);
          },
        );

        expect(entries, hasLength(1));
        expect(entries.single.id, 'entry-1');
        expect(malformedIds, ['bad-entry']);
      },
    );

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
    });
  });
}
