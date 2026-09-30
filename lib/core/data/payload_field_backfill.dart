import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/payload_cipher.dart';

const _logName = 'PayloadFieldBackfill';
const _maxBatchSize = 400;

/// Adds the fields of [defaults] to the encrypted payload of every document
/// in [collection] that lacks them.
///
/// A migration for documents that an older app version wrote before a field
/// existed. It reads from the server only, so a partial offline cache never
/// counts as done. Documents that already hold every field stay untouched,
/// so it is safe to run again. A document that cannot be decrypted is
/// logged and skipped, so it does not block the others.
Future<void> backfillPayloadFields({
  required CollectionReference<Map<String, dynamic>> collection,
  required PayloadCipher cipher,
  required Map<String, Object?> defaults,
}) async {
  final snapshot = await collection.get(
    const GetOptions(source: Source.server),
  );
  final updates = <(DocumentReference<Map<String, dynamic>>, String)>[];
  for (final document in snapshot.docs) {
    final payload = document.data()[encryptedPayloadField];
    if (payload is! String) {
      continue;
    }
    final aad = document.reference.path;
    final Map<String, dynamic> data;
    try {
      data = await cipher.decryptJson(payload, aad: aad);
    } on Object catch (error, stackTrace) {
      log(
        'Skipping ${document.reference.path}: the payload does not open.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      continue;
    }
    final missing = <String, Object?>{
      for (final field in defaults.entries)
        if (!data.containsKey(field.key)) field.key: field.value,
    };
    if (missing.isEmpty) {
      continue;
    }
    final upgraded = await cipher.encryptJson(<String, dynamic>{
      ...data,
      ...missing,
    }, aad: aad);
    updates.add((document.reference, upgraded));
  }

  for (final chunk in FirestoreBatchChunker.chunk(
    operations: updates,
    maxChunkSize: _maxBatchSize,
  )) {
    final batch = collection.firestore.batch();
    for (final (reference, upgraded) in chunk) {
      batch.update(reference, <String, dynamic>{
        encryptedPayloadField: upgraded,
      });
    }
    await batch.commit();
  }
}
