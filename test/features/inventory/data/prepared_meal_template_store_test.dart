import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
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
}
