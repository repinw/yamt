import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/data/payload_cipher.dart';

/// Name of the field that holds the encrypted document.
const encryptedPayloadField = 'payload';

const _maxBatchSize = 400;

/// A collection whose documents are stored as an encrypted payload.
class EncryptedCollection {
  /// Creates a collection description.
  const new(this.path, {this.plaintextFields = const <String>[]});

  /// The collection path.
  final String path;

  /// Fields that stay readable next to the payload, for queries.
  final List<String> plaintextFields;
}

/// A map field of one document that is stored as an encrypted payload.
class EncryptedDocumentField {
  /// Creates a field description.
  const new(this.documentPath, this.field);

  /// The document path.
  final String documentPath;

  /// The field name.
  final String field;

  /// Additional authenticated data for the payload of this field.
  String get aad => '$documentPath#$field';
}

/// Encrypts documents and fields that were stored before encryption existed.
///
/// Reads from the server only, so a partial offline cache never counts as
/// done. Encrypted documents are skipped, so it is safe to run again.
///
/// Temporary: remove once all accounts are migrated.
Future<void> encryptPlaintextDocuments({
  required FirebaseFirestore firestore,
  required PayloadCipher cipher,
  required List<EncryptedCollection> collections,
  required List<EncryptedDocumentField> fields,
}) async {
  const serverOnly = GetOptions(source: Source.server);
  final operations = <FirestoreBatchWriteOperation>[];

  for (final collection in collections) {
    final snapshot = await firestore
        .collection(collection.path)
        .get(serverOnly);
    for (final document in snapshot.docs) {
      final data = document.data();
      if (data.containsKey(encryptedPayloadField)) {
        continue;
      }
      operations.add(
        FirestoreBatchWriteOperation.set(document.reference, <String, dynamic>{
          for (final field in collection.plaintextFields)
            if (data.containsKey(field)) field: data[field],
          encryptedPayloadField: await cipher.encryptJson(
            normalizeFirestoreJson(data),
            aad: document.reference.path,
          ),
        }),
      );
    }
  }

  for (final chunk in FirestoreBatchChunker.chunk(
    operations: operations,
    maxChunkSize: _maxBatchSize,
  )) {
    final batch = firestore.batch();
    for (final operation in chunk) {
      operation.apply(batch);
    }
    await batch.commit();
  }

  for (final field in fields) {
    final reference = firestore.doc(field.documentPath);
    final snapshot = await reference.get(serverOnly);
    final value = snapshot.data()?[field.field];
    if (value is! Map) {
      continue;
    }
    final normalizedValue = normalizeFirestoreValue(value);
    if (normalizedValue is! Map<String, dynamic>) {
      continue;
    }
    await reference.update(<String, dynamic>{
      field.field: await cipher.encryptJson(normalizedValue, aad: field.aad),
    });
  }
}
