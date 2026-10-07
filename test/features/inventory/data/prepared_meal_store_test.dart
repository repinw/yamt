import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/inventory/data/prepared_meal_store.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestorePreparedMealStore store;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    store = FirestorePreparedMealStore(
      firestore: firestore,
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  });

  Future<List<String>> storedIds() async {
    final raw = await firestore
        .collection('households/household-1/prepared_meals')
        .get();
    return raw.docs.map((document) => document.id).toList();
  }

  test('save stores one sealed meal under the household', () async {
    final saved = await store.save(
      householdId: 'household-1',
      id: 'meal-1',
      data: <String, dynamic>{'name': 'Lunch box'},
    );

    expect(saved, isTrue);
    final raw = await firestore
        .doc('households/household-1/prepared_meals/meal-1')
        .get();
    expect(raw.data()!.keys, <String>[encryptedPayloadField]);
    final documents = await store.readAll(householdId: 'household-1');
    expect(documents.single.data['name'], 'Lunch box');
  });

  test('save and delete leave the other meals alone', () async {
    for (final id in ['soup', 'rice', 'chili']) {
      await store.save(
        householdId: 'household-1',
        id: id,
        data: <String, dynamic>{'name': id},
      );
    }
    // A meal another device wrote and this one never read.
    await firestore.doc('households/household-1/prepared_meals/foreign').set(
      <String, dynamic>{'payload': 'other key'},
    );

    await store.save(
      householdId: 'household-1',
      id: 'rice',
      data: <String, dynamic>{'name': 'More rice'},
    );
    await store.delete(householdId: 'household-1', id: 'soup');

    expect(await storedIds(), unorderedEquals(['rice', 'chili', 'foreign']));
  });

  test(
    'the meal list shows a saved meal before the server confirms it',
    () async {
      final meals = store.watchAll(householdId: 'household-1');
      final names = meals
          .map((documents) => documents.map((d) => d.data['name']).toList())
          .firstWhere((names) => names.contains('Soup'));

      await store.save(
        householdId: 'household-1',
        id: 'soup',
        data: <String, dynamic>{'name': 'Soup'},
      );

      expect(await names, ['Soup']);
    },
  );
}
