import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const _keyLength = 16;
const _encodedLength = 26;
const _groupLength = 4;
const _wrapInfo = 'yamt data key backup v1';

/// Keeps the bit buffer small: it never holds more than 12 pending bits.
const _bitBufferMask = 0xffff;

/// Secret that only the user knows. It protects the backup of the data key.
///
/// It holds 128 random bits, written in Crockford Base32 as
/// `XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XX`.
class RecoveryKey {
  const new _(this._bytes);

  /// Creates a new random recovery key.
  factory generate() {
    final random = Random.secure();
    return RecoveryKey._(
      Uint8List.fromList(
        List<int>.generate(_keyLength, (_) => random.nextInt(256)),
      ),
    );
  }

  /// Parses a recovery key typed by the user.
  ///
  /// Ignores case, dashes, and spaces, and reads `I`, `L` as `1` and `O` as
  /// `0`. Throws [FormatException] for any other input.
  factory parse(String input) {
    final characters = input
        .toUpperCase()
        .replaceAll(RegExp(r'[\s-]'), '')
        .replaceAll(RegExp('[IL]'), '1')
        .replaceAll('O', '0');
    if (characters.length != _encodedLength) {
      throw const FormatException('Recovery key has the wrong length.');
    }
    final bytes = Uint8List(_keyLength);
    var buffer = 0;
    var bufferedBits = 0;
    var byteIndex = 0;
    for (final character in characters.split('')) {
      final value = _alphabet.indexOf(character);
      if (value < 0) {
        throw const FormatException('Recovery key has an invalid character.');
      }
      buffer = ((buffer << 5) | value) & _bitBufferMask;
      bufferedBits += 5;
      if (bufferedBits >= 8 && byteIndex < _keyLength) {
        bufferedBits -= 8;
        bytes[byteIndex++] = (buffer >> bufferedBits) & 0xff;
      }
    }
    return RecoveryKey._(bytes);
  }

  final Uint8List _bytes;

  /// The key in groups of four characters, for display.
  String get formatted {
    final encoded = StringBuffer();
    var buffer = 0;
    var bufferedBits = 0;
    for (final byte in _bytes) {
      buffer = ((buffer << 8) | byte) & _bitBufferMask;
      bufferedBits += 8;
      while (bufferedBits >= 5) {
        bufferedBits -= 5;
        encoded.write(_alphabet[(buffer >> bufferedBits) & 0x1f]);
      }
    }
    if (bufferedBits > 0) {
      encoded.write(_alphabet[(buffer << (5 - bufferedBits)) & 0x1f]);
    }
    final characters = encoded.toString();
    return [
      for (var start = 0; start < characters.length; start += _groupLength)
        characters.substring(
          start,
          min(start + _groupLength, characters.length),
        ),
    ].join('-');
  }

  /// Encrypts [dataKey] for the backup document of [uid].
  Future<String> wrapDataKey(SecretKey dataKey, {required String uid}) async {
    final secretBox = await AesGcm.with256bits().encrypt(
      await dataKey.extractBytes(),
      secretKey: await _wrappingKey(uid),
      aad: utf8.encode(uid),
    );
    return base64Encode(secretBox.concatenation());
  }

  /// Decrypts a data key created by [wrapDataKey].
  ///
  /// Throws [SecretBoxAuthenticationError] if this is not the right key.
  Future<SecretKey> unwrapDataKey(String wrapped, {required String uid}) async {
    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox.fromConcatenation(
      base64Decode(wrapped),
      nonceLength: algorithm.nonceLength,
      macLength: algorithm.macAlgorithm.macLength,
    );
    final dataKeyBytes = await algorithm.decrypt(
      secretBox,
      secretKey: await _wrappingKey(uid),
      aad: utf8.encode(uid),
    );
    return SecretKey(dataKeyBytes);
  }

  Future<SecretKey> _wrappingKey(String uid) {
    return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: SecretKey(_bytes),
      nonce: utf8.encode(uid),
      info: utf8.encode(_wrapInfo),
    );
  }
}
