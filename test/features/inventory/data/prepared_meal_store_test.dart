import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
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
}
