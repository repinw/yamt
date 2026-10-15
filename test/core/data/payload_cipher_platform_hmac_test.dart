import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';

/// HMAC that rejects an empty key, like the platform HMAC on Android.
class _EmptyKeyRejectingHmac extends DartHmac {
  const new(super.hashAlgorithm);

  @override
  Future<Mac> calculateMac(
    List<int> bytes, {
    required SecretKey secretKey,
    List<int> nonce = const <int>[],
    List<int> aad = const <int>[],
  }) async {
    if ((await secretKey.extractBytes()).isEmpty) {
      throw ArgumentError('Empty key');
    }
    return await super.calculateMac(
      bytes,
      secretKey: secretKey,
      nonce: nonce,
      aad: aad,
    );
  }
}

class _PlatformLikeCryptography extends DartCryptography {
  @override
  Hmac hmac(HashAlgorithm hashAlgorithm) =>
      _EmptyKeyRejectingHmac(hashAlgorithm);
}

void main() {
  // Before the first use of PayloadCipher, whose algorithms are static.
  Cryptography.instance = _PlatformLikeCryptography();

  test('keyedId never computes an HMAC with an empty key', () async {
    final cipher = PayloadCipher(await PayloadCipher.newDataKey());

    expect(await cipher.keyedId('health-weight-sample:a:80.00'), isNotEmpty);
  });
}
