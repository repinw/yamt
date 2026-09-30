import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/data/payload_cipher.dart';

const _logName = 'PayloadFieldBackfill';

/// Temporary migration, added in 3.4.1: removed in 3.7.0. Adds the fields
/// of [defaults] to the encrypted payload of every document in [collection]
/// that lacks them.
///
/// For documents that an older app version wrote before a field existed. It
/// reads from the server only, so a partial offline cache never counts as
/// done. Documents that already hold every field stay untouched, so it is
/// safe to run again. A document that does not decrypt, or whose write is
/// rejected, is logged and skipped, so it does not block the others. Each
/// write runs in a transaction that re-reads the document and skips it when
/// its payload changed since the read, so an edit made meanwhile is never
/// overwritten.
Future<void> backfillPayloadFields({
  required CollectionReference<Map<String, dynamic>> collection,
  required PayloadCipher cipher,
  required Map<String, Object?> defaults,
}) async {
  final snapshot = await collection.get(
    const GetOptions(source: Source.server),
  );
  final updates = <(DocumentReference<Map<String, dynamic>>, String, String)>[];
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
    updates.add((document.reference, payload, upgraded));
  }

  for (final (reference, read, upgraded) in updates) {
    try {
      await collection.firestore.runTransaction((transaction) async {
        final current = await transaction.get(reference);
        if (current.data()?[encryptedPayloadField] != read) {
          return;
        }
        transaction.update(reference, <String, dynamic>{
          encryptedPayloadField: upgraded,
        });
      });
    } on FirebaseException catch (error, stackTrace) {
      log(
        'Skipping ${reference.path}: the update was rejected.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
