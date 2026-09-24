import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_document.dart';

void main() {
  const path = 'users/u1/inventory_items/i1';
  late PayloadCipher cipher;

  setUp(() async {
    cipher = PayloadCipher(await PayloadCipher.newDataKey());
  });

  test('seal keeps only the payload and the plaintext fields', () async {
    final sealed = await sealDocument(
      <String, dynamic>{
        'name': 'Milch',
        'entry_date': '2026-09-24',
        'is_deposit': false,
      },
      path: path,
      cipher: cipher,
      plaintextFields: const <String>['entry_date', 'is_deposit', 'missing'],
    );

    expect(
      sealed.keys,
      unorderedEquals(<String>['payload', 'entry_date', 'is_deposit']),
    );
    expect(sealed['payload'], isNot(contains('Milch')));
  });

  test('open returns the same map a plaintext read would return', () async {
    final updatedAt = Timestamp.fromDate(DateTime(2026, 9, 24, 12));
    final data = <String, dynamic>{
      'name': 'Milch',
      'updated_at': updatedAt,
      'nutrition': <String, dynamic>{'kcal': 64},
      'tags': <Object?>['a', updatedAt],
    };

    final sealed = await sealDocument(data, path: path, cipher: cipher);
    final opened = await openDocument(sealed, path: path, cipher: cipher);

    expect(opened, data);
  });

  test('open fails without payload or for another document', () async {
    final sealed = await sealDocument(
      <String, dynamic>{'name': 'Milch'},
      path: path,
      cipher: cipher,
    );

    await expectLater(
      openDocument(
        <String, dynamic>{'name': 'Milch'},
        path: path,
        cipher: cipher,
      ),
      throwsFormatException,
    );
    await expectLater(
      openDocument(sealed, path: 'users/u1/inventory_items/i2', cipher: cipher),
      throwsA(anything),
    );
  });
}
