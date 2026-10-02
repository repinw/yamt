import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_store.dart';

void main() {
  late PayloadCipher cipher;

  setUp(() async {
    cipher = PayloadCipher(await PayloadCipher.newDataKey());
  });

  test('replaceAll stores sealed templates under the household', () async {
    final firestore = FakeFirebaseFirestore();
    final store = FirestorePreparedMealTemplateStore(
      firestore: firestore,
      cipher: cipher,
    );

    final saved = await store.replaceAll(
      parse: (_, _) {},
      householdId: 'household-1',
      documentsById: <String, Map<String, dynamic>>{
        'template-1': <String, dynamic>{'name': 'Chili'},
      },
    );

    expect(saved, isTrue);
    final raw = await firestore
        .doc('households/household-1/prepared_meal_templates/template-1')
        .get();
    expect(raw.data()!.keys, <String>[encryptedPayloadField]);
    final documents = await store.readAll(householdId: 'household-1');
    expect(documents.single.id, 'template-1');
    expect(documents.single.data['name'], 'Chili');
  });

  test('replaceAll deletes a left-out template only when it parses', () async {
    final firestore = FakeFirebaseFirestore();
    final store = FirestorePreparedMealTemplateStore(
      firestore: firestore,
      cipher: cipher,
    );
    await store.replaceAll(
      parse: (_, _) {},
      householdId: 'household-1',
      documentsById: <String, Map<String, dynamic>>{
        'gone': <String, dynamic>{'name': 'Soup'},
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
}
