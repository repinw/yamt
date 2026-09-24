import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';

/// Encrypts [data] for the document at [path].
///
/// The result holds the encrypted payload and a plaintext copy of the
/// [plaintextFields] that Firestore queries need.
Future<Map<String, dynamic>> sealDocument(
  Map<String, dynamic> data, {
  required String path,
  required PayloadCipher cipher,
  List<String> plaintextFields = const <String>[],
}) async {
  return <String, dynamic>{
    for (final field in plaintextFields)
      if (data.containsKey(field)) field: data[field],
    encryptedPayloadField: await cipher.encryptJson(
      normalizeFirestoreJson(data),
      aad: path,
    ),
  };
}

/// Decrypts a document written by [sealDocument].
///
/// Returns the same map a plaintext read would return: dates come back as
/// Firestore [Timestamp]s. Throws [FormatException] for a document without a
/// payload.
Future<Map<String, dynamic>> openDocument(
  Map<String, dynamic> raw, {
  required String path,
  required PayloadCipher cipher,
}) async {
  final payload = raw[encryptedPayloadField];
  if (payload is! String) {
    throw FormatException('Document $path has no payload.');
  }
  final data = await cipher.decryptJson(payload, aad: path);
  return data.map(
    (key, value) => MapEntry<String, dynamic>(key, _restoreTimestamps(value)),
  );
}

Object? _restoreTimestamps(Object? value) {
  if (value is DateTime) {
    return Timestamp.fromDate(value);
  }
  if (value is Map<String, dynamic>) {
    return value.map(
      (key, nested) =>
          MapEntry<String, dynamic>(key, _restoreTimestamps(nested)),
    );
  }
  if (value is List) {
    return value.map(_restoreTimestamps).toList(growable: false);
  }
  return value;
}
