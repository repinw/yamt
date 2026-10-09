import 'dart:developer' show log;

import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/sealed_collection.dart';

/// Writes one sealed document of a household collection without waiting for
/// the server, so the local cache shows the change at once. Shared by the
/// Vorrat item, meal and cookbook template stores.
mixin SealedHouseholdDocumentWrites {
  /// Name under which failed writes are logged.
  String get writeLogName;

  /// The sealed collection of [householdId] that the documents live in.
  SealedCollection householdCollection(String householdId);

  /// Seals [data] and writes it as the document [id]. Returns `false` when
  /// sealing fails; a later server rejection is only logged.
  Future<bool> save({
    required String householdId,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final collection = householdCollection(householdId);
    final document = collection.reference.doc(id);
    try {
      final sealed = await collection.seal(id, data);
      commitBatchInBackground(
        document.firestore.batch()..set(document, sealed),
        failureMessage: 'Server rejected ${document.path}.',
        logName: writeLogName,
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save ${document.path}.',
        name: writeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Deletes the document [id]. A server rejection is only logged.
  Future<bool> delete({required String householdId, required String id}) async {
    final document = householdCollection(householdId).reference.doc(id);
    commitBatchInBackground(
      document.firestore.batch()..delete(document),
      failureMessage: 'Server rejected deleting ${document.path}.',
      logName: writeLogName,
    );
    return true;
  }
}
