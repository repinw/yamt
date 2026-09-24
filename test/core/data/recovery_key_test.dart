import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';

void main() {
  test('formats as seven groups of Crockford Base32', () {
    final formatted = RecoveryKey.generate().formatted;

    expect(
      formatted,
      matches(RegExp(r'^([0-9A-HJKMNP-TV-Z]{4}-){6}[0-9A-HJKMNP-TV-Z]{2}$')),
    );
  });

  test('parse reads its own format back', () {
    final key = RecoveryKey.generate();

    expect(RecoveryKey.parse(key.formatted).formatted, key.formatted);
  });

  test('parse ignores case, spaces, dashes, and look-alike letters', () {
    final formatted = RecoveryKey.generate().formatted;
    final typed = formatted
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('1', 'l')
        .replaceAll('0', 'o');

    expect(RecoveryKey.parse(typed).formatted, formatted);
  });

  test('parse rejects wrong length and invalid characters', () {
    expect(() => RecoveryKey.parse('ABCD'), throwsFormatException);
    expect(
      () => RecoveryKey.parse('UUUU-UUUU-UUUU-UUUU-UUUU-UUUU-UU'),
      throwsFormatException,
    );
  });

  test('wrap and unwrap return the same data key', () async {
    final recoveryKey = RecoveryKey.generate();
    final dataKey = await PayloadCipher.newDataKey();

    final wrapped = await recoveryKey.wrapDataKey(dataKey, uid: 'u1');
    final unwrapped = await RecoveryKey.parse(
      recoveryKey.formatted,
    ).unwrapDataKey(wrapped, uid: 'u1');

    expect(await unwrapped.extractBytes(), await dataKey.extractBytes());
  });

  test('unwrap fails with another recovery key or another uid', () async {
    final recoveryKey = RecoveryKey.generate();
    final wrapped = await recoveryKey.wrapDataKey(
      await PayloadCipher.newDataKey(),
      uid: 'u1',
    );

    await expectLater(
      RecoveryKey.generate().unwrapDataKey(wrapped, uid: 'u1'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
    await expectLater(
      recoveryKey.unwrapDataKey(wrapped, uid: 'u2'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
