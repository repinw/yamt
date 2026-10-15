import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

const _dateTimeTag = r'$dt';

/// Encrypts JSON documents and files with AES-256-GCM before they are stored.
///
/// The additional authenticated data (`aad`) is the document or file path, so
/// a payload cannot be copied into another document. `DateTime` values survive
/// the round trip as `DateTime`, like Firestore timestamps do after
/// `normalizeFirestoreJson`.
class PayloadCipher {
  /// Creates a cipher for the given data key.
  const new(this._dataKey);

  static final _algorithm = AesGcm.with256bits();
  static final _mac = Hmac.sha256();
  static final _macKeyDerivation = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  // RFC 5869's default salt of HashLen zeros, spelled out: the platform HMAC
  // on Android rejects the empty key that HKDF would otherwise extract with.
  // It gives the same keys as an empty salt.
  static final _macKeySalt = List<int>.unmodifiable(List<int>.filled(32, 0));

  final SecretKey _dataKey;

  /// Creates a new random data key.
  static Future<SecretKey> newDataKey() => _algorithm.newSecretKey();

  /// Encrypts [json] and returns the base64 payload.
  Future<String> encryptJson(
    Map<String, dynamic> json, {
    required String aad,
  }) async {
    final clearText = utf8.encode(jsonEncode(json, toEncodable: _encodeValue));
    return base64Encode(await encryptBytes(clearText, aad: aad));
  }

  /// A stable id for [value] that only this data key can produce.
  ///
  /// Equal values get the same id, so they can share a document, while the
  /// id reveals nothing about the value. Prefix [value] with its purpose, so
  /// ids of different kinds never meet.
  Future<String> keyedId(String value) async {
    // A key of its own, so the encryption key never serves as a MAC key.
    final macKey = await _macKeyDerivation.deriveKey(
      secretKey: _dataKey,
      nonce: _macKeySalt,
      info: utf8.encode('yamt keyed id'),
    );
    final mac = await _mac.calculateMac(utf8.encode(value), secretKey: macKey);
    return base64UrlEncode(mac.bytes).replaceAll('=', '');
  }

  /// Decrypts a payload created by [encryptJson].
  ///
  /// Throws [SecretBoxAuthenticationError] for a wrong key or a wrong [aad].
  Future<Map<String, dynamic>> decryptJson(
    String payload, {
    required String aad,
  }) async {
    final clearText = await decryptBytes(base64Decode(payload), aad: aad);
    final decoded = jsonDecode(utf8.decode(clearText), reviver: _reviveValue);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Payload is not a JSON object.');
    }
    return decoded;
  }

  /// Encrypts [clearBytes] and returns the nonce, the cipher text, and the
  /// MAC in one block.
  Future<Uint8List> encryptBytes(
    List<int> clearBytes, {
    required String aad,
  }) async {
    final secretBox = await _algorithm.encrypt(
      clearBytes,
      secretKey: _dataKey,
      aad: utf8.encode(aad),
    );
    return secretBox.concatenation();
  }

  /// Decrypts a block created by [encryptBytes].
  ///
  /// Throws [SecretBoxAuthenticationError] for a wrong key or a wrong [aad].
  Future<Uint8List> decryptBytes(
    List<int> sealedBytes, {
    required String aad,
  }) async {
    final secretBox = SecretBox.fromConcatenation(
      sealedBytes,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    final clearBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: _dataKey,
      aad: utf8.encode(aad),
    );
    return Uint8List.fromList(clearBytes);
  }
}

Object? _encodeValue(Object? value) {
  if (value is DateTime) {
    return <String, Object>{_dateTimeTag: value.microsecondsSinceEpoch};
  }
  throw UnsupportedError('Cannot encrypt value of type ${value.runtimeType}.');
}

Object? _reviveValue(Object? key, Object? value) {
  if (value is Map && value.length == 1) {
    final micros = value[_dateTimeTag];
    if (micros is int) {
      return DateTime.fromMicrosecondsSinceEpoch(micros);
    }
  }
  return value;
}
