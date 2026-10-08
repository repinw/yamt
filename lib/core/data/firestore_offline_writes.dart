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
) => readLocalFirst(reference.get);

/// Reads [query] from the local Firestore cache, and from the server only
/// when the cache read fails.
///
/// The cache holds the app's own writes at once, also before the server has
/// them, so a change that starts from this read sees the changes before it.
/// Use it for a query that a screen already watches, so the cache holds it.
Future<QuerySnapshot<Map<String, dynamic>>> readQueryLocalFirst(
  Query<Map<String, dynamic>> query,
) => readLocalFirst(query.get);

/// Runs [get] on the local cache, and once more with the default source when
/// the cache read fails.
Future<T> readLocalFirst<T>(
  Future<T> Function([GetOptions? options]) get,
) async {
  try {
    return await get(const GetOptions(source: Source.cache));
  } on FirebaseException {
    return await get();
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
      log(failureMessage, name: logName, error: error, stackTrace: stackTrace);
    }),
  );
}
