import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/inventory/data/prepared_meal_store.dart';

void main() {
  late PayloadCipher cipher;

  setUp(() async {
    cipher = PayloadCipher(await PayloadCipher.newDataKey());
  });

  test('replaceAll stores sealed meals under the household', () async {
    final firestore = FakeFirebaseFirestore();
    final store = FirestorePreparedMealStore(
      firestore: firestore,
      cipher: cipher,
    );

    final saved = await store.replaceAll(
      parse: (_, _) {},
      householdId: 'household-1',
      documentsById: <String, Map<String, dynamic>>{
        'meal-1': <String, dynamic>{'name': 'Lunch box'},
      },
    );

    expect(saved, isTrue);
    final raw = await firestore
        .doc('households/household-1/prepared_meals/meal-1')
        .get();
    expect(raw.data()!.keys, <String>[encryptedPayloadField]);
    final documents = await store.readAll(householdId: 'household-1');
    expect(documents.single.id, 'meal-1');
    expect(documents.single.data['name'], 'Lunch box');
  });

  test('replaceAll deletes a left-out meal only when it parses', () async {
    final firestore = FakeFirebaseFirestore();
    final store = FirestorePreparedMealStore(
      firestore: firestore,
      cipher: cipher,
    );
    await store.replaceAll(
      parse: (_, _) {},
      householdId: 'household-1',
      documentsById: <String, Map<String, dynamic>>{
        'eaten': <String, dynamic>{'name': 'Soup'},
        'broken': <String, dynamic>{'name': 'Broken'},
      },
    );

    await store.replaceAll(
      parse: (_, data) {
        if (data['name'] == 'Broken') {
          throw const FormatException('broken');
        }
      },
      householdId: 'household-1',
      documentsById: <String, Map<String, dynamic>>{
        'new': <String, dynamic>{'name': 'Rice'},
      },
    );

    final documents = await store.readAll(householdId: 'household-1');
    expect(
      documents.map((document) => document.id),
      unorderedEquals(<String>['new', 'broken']),
    );
  });

  test('replaceAll keeps a left-out meal that does not open', () async {
    final firestore = FakeFirebaseFirestore();
    final otherKey = PayloadCipher(await PayloadCipher.newDataKey());
    await FirestorePreparedMealStore(
      firestore: firestore,
      cipher: otherKey,
    ).replaceAll(
      parse: (_, _) {},
      householdId: 'household-1',
      documentsById: <String, Map<String, dynamic>>{
        'foreign': <String, dynamic>{'name': 'Soup'},
      },
    );

    await FirestorePreparedMealStore(
      firestore: firestore,
      cipher: cipher,
    ).replaceAll(
      parse: (_, _) {},
      householdId: 'household-1',
      documentsById: <String, Map<String, dynamic>>{
        'new': <String, dynamic>{'name': 'Rice'},
      },
    );

    final raw = await firestore
        .collection('households/household-1/prepared_meals')
        .get();
    expect(
      raw.docs.map((document) => document.id),
      unorderedEquals(<String>['foreign', 'new']),
    );
  });
}
