import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads [reference] from the local Firestore cache, and from the server only
/// when the cache does not hold the document.
///
/// Documents that a screen already watches are in the cache, so the read also
/// works offline.
Future<DocumentSnapshot<Map<String, dynamic>>> readDocumentLocalFirst(
  DocumentReference<Map<String, dynamic>> reference,
) async {
  try {
    return await reference.get(const GetOptions(source: Source.cache));
  } on FirebaseException {
    return await reference.get();
  }
}

/// Commits [batch] without waiting for the server.
///
/// Firestore applies the batch to its local cache at once and sends it when
/// a connection is available, also after an app restart. A later rejection by
/// the server is logged with [failureMessage].
void commitBatchInBackground(
  WriteBatch batch, {
  required String failureMessage,
  required String logName,
}) {
  unawaited(
    batch.commit().catchError((Object error, StackTrace stackTrace) {
      log(
        failureMessage,
        name: logName,
        error: error,
        stackTrace: stackTrace,
      );
    }),
  );
}
