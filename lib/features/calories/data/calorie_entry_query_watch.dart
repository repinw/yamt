import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/calories/data/calorie_entry_cache.dart';
import 'package:yamt/features/calories/data/calorie_entry_document_codec.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Watches the entries of [query], the local cache first, and remembers
/// them in [cache]. Each snapshot decrypts only the documents that changed.
///
/// A failure is logged, then delivered as an empty list when [emptyOnError]
/// is set, or as the error.
Stream<List<CalorieEntry>> watchCalorieEntryQuery(
  Query<Map<String, dynamic>> query, {
  required String userId,
  required PayloadCipher cipher,
  required CalorieEntryCache cache,
  required bool emptyOnError,
}) {
  return Stream<List<CalorieEntry>>.multi((controller) {
    // Decoded entries by document id; null marks a malformed document.
    final decoded = <String, CalorieEntry?>{};
    Future<List<CalorieEntry>> decodeChanges(
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) async {
      final changed = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          decoded.remove(change.doc.id);
        } else {
          changed.add(change.doc);
        }
      }
      await Future.wait(
        changed.map((document) async {
          decoded[document.id] = await decodeCalorieEntryDocumentOrNull(
            document,
            cipher: cipher,
          );
        }),
      );
      return [for (final document in snapshot.docs) ?decoded[document.id]];
    }

    final subscription = query
        .snapshots()
        .asyncMap(decodeChanges)
        .listen(
          (entries) {
            controller.add(cache.rememberAll(entries));
          },
          onError: (Object error, StackTrace stackTrace) {
            log(
              'Failed to watch calories for user $userId',
              name: 'FirestoreCalorieLogRepository',
              error: error,
              stackTrace: stackTrace,
            );
            if (emptyOnError) {
              controller.add(const <CalorieEntry>[]);
            } else {
              controller.addError(error, stackTrace);
            }
          },
          onDone: controller.close,
        );
    controller.onCancel = subscription.cancel;
  });
}
