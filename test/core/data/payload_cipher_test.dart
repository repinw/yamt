import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';

void main() {
  const aad = 'users/u1/calorie_entries/e1';

  test('round trip keeps values and restores DateTime', () async {
    final cipher = PayloadCipher(await PayloadCipher.newDataKey());
    final loggedAt = DateTime(2026, 9, 24, 12, 30, 15, 123, 456);
    final json = <String, dynamic>{
      'name': 'Nutella',
      'total_kcal': 539.5,
      'count': 3,
      'flag': true,
      'missing': null,
      'logged_at': loggedAt,
      'nested': <String, dynamic>{
        'items': <Object?>[1, 'two', DateTime.utc(2026)],
      },
    };

    final payload = await cipher.encryptJson(json, aad: aad);
    final decrypted = await cipher.decryptJson(payload, aad: aad);

    expect(payload, isNot(contains('Nutella')));
    expect(decrypted['name'], 'Nutella');
    expect(decrypted['total_kcal'], 539.5);
    expect(decrypted['count'], 3);
    expect(decrypted['flag'], isTrue);
    expect(decrypted.containsKey('missing'), isTrue);
    expect(decrypted['logged_at'], loggedAt);
    final nested = decrypted['nested'] as Map<String, dynamic>;
    final items = nested['items'] as List<dynamic>;
    expect(items[2], DateTime.utc(2026).toLocal());
  });

  test('uses a new nonce for every encryption', () async {
    final cipher = PayloadCipher(await PayloadCipher.newDataKey());
    final json = <String, dynamic>{'weight_kg': 80.5};

    final first = await cipher.encryptJson(json, aad: aad);
    final second = await cipher.encryptJson(json, aad: aad);

    expect(first, isNot(second));
  });

  test('fails with a wrong key', () async {
    final payload = await PayloadCipher(await PayloadCipher.newDataKey())
        .encryptJson(<String, dynamic>{'a': 1}, aad: aad);
    final otherCipher = PayloadCipher(await PayloadCipher.newDataKey());

    await expectLater(
      otherCipher.decryptJson(payload, aad: aad),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('fails when the payload is moved to another document', () async {
    final cipher = PayloadCipher(await PayloadCipher.newDataKey());
    final payload = await cipher.encryptJson(<String, dynamic>{
      'a': 1,
    }, aad: aad);

    await expectLater(
      cipher.decryptJson(payload, aad: 'users/u1/calorie_entries/e2'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('rejects values that are not JSON', () async {
    final cipher = PayloadCipher(await PayloadCipher.newDataKey());

    await expectLater(
      cipher.encryptJson(<String, dynamic>{'value': Object()}, aad: aad),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
  });

  test('keyedId is stable per key and reveals nothing', () async {
    final cipher = PayloadCipher(await PayloadCipher.newDataKey());
    final otherKey = PayloadCipher(await PayloadCipher.newDataKey());

    final id = await cipher.keyedId('health-weight-sample:a:80.00');

    expect(await cipher.keyedId('health-weight-sample:a:80.00'), id);
    expect(await cipher.keyedId('health-weight-sample:a:80.01'), isNot(id));
    expect(await otherKey.keyedId('health-weight-sample:a:80.00'), isNot(id));
    // The id holds none of the input; two digits would match by chance.
    expect(id, isNot(contains('health-weight-sample')));
    expect(id, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
  });

  test('keyedId keeps the ids it had without a salt', () async {
    final dataKey = SecretKey(List<int>.generate(32, (i) => i));
    // The derivation before the salt: HKDF with an empty salt.
    final macKey = await Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: dataKey,
      info: utf8.encode('yamt keyed id'),
    );
    final mac = await Hmac.sha256().calculateMac(
      utf8.encode('health-weight-sample:a:80.00'),
      secretKey: macKey,
    );

    expect(
      await PayloadCipher(dataKey).keyedId('health-weight-sample:a:80.00'),
      base64UrlEncode(mac.bytes).replaceAll('=', ''),
    );
  });

  test('encrypts bytes and opens them only with the same path', () async {
    final cipher = PayloadCipher(await PayloadCipher.newDataKey());
    final image = List<int>.generate(100, (i) => i % 256);

    final sealed = await cipher.encryptBytes(image, aad: 'users/u1/p/a');

    expect(sealed, hasLength(image.length + 28));
    expect(await cipher.decryptBytes(sealed, aad: 'users/u1/p/a'), image);
    await expectLater(
      cipher.decryptBytes(sealed, aad: 'users/u1/p/b'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
