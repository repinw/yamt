import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

const _codecLogName = 'CalorieEntryDocumentCodec';

/// Decodes a Firestore document snapshot into a [CalorieEntry].
CalorieEntry decodeCalorieEntryDocument(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final rawData = doc.data() ?? const <String, dynamic>{};
  return CalorieEntry.fromJson(normalizeFirestoreJson(rawData));
}

/// Decodes a Firestore query snapshot into a list of [CalorieEntry],
/// skipping and logging any malformed documents.
List<CalorieEntry> decodeCalorieEntrySnapshot(
  QuerySnapshot<Map<String, dynamic>> snapshot, {
  void Function(String docId, Object error, StackTrace stackTrace)? onMalformed,
}) {
  final entries = <CalorieEntry>[];
  for (final document in snapshot.docs) {
    try {
      entries.add(decodeCalorieEntryDocument(document));
    } on Object catch (error, stackTrace) {
      if (onMalformed != null) {
        onMalformed(document.id, error, stackTrace);
      } else {
        log(
          'Skipping malformed calorie entry ${document.id}',
          name: _codecLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }
  return entries;
}

/// Normalizes a [CalorieEntry] for saving to Firestore with current user ID,
/// normalized image URL, and updated timestamp.
CalorieEntry prepareCalorieEntryForSave(
  CalorieEntry entry, {
  required String userId,
  required DateTime updatedAt,
}) {
  return entry.copyWith(
    imageUrl: normalizeCalorieProductImageUrl(entry.imageUrl),
    userId: userId,
    updatedAt: updatedAt,
  );
}
