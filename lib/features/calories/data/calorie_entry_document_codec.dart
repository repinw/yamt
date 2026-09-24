import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

const _codecLogName = 'CalorieEntryDocumentCodec';

/// Field that stays readable next to the payload, for range queries.
const calorieEntryLoggedAtField = 'logged_at';

/// Encodes [entry] as the encrypted document at [reference].
Future<Map<String, dynamic>> encodeCalorieEntryDocument(
  CalorieEntry entry, {
  required DocumentReference<Map<String, dynamic>> reference,
  required PayloadCipher cipher,
}) async {
  return <String, dynamic>{
    calorieEntryLoggedAtField: entry.loggedAt,
    encryptedPayloadField: await cipher.encryptJson(
      entry.toJson(),
      aad: reference.path,
    ),
  };
}

/// Decrypts a Firestore document snapshot into a [CalorieEntry].
Future<CalorieEntry> decodeCalorieEntryDocument(
  DocumentSnapshot<Map<String, dynamic>> doc, {
  required PayloadCipher cipher,
}) async {
  final payload = doc.data()?[encryptedPayloadField];
  if (payload is! String) {
    throw FormatException('Calorie entry ${doc.id} has no payload.');
  }
  return CalorieEntry.fromJson(
    await cipher.decryptJson(payload, aad: doc.reference.path),
  );
}

/// Decrypts a Firestore query snapshot into a list of [CalorieEntry],
/// skipping and logging any malformed documents.
Future<List<CalorieEntry>> decodeCalorieEntrySnapshot(
  QuerySnapshot<Map<String, dynamic>> snapshot, {
  required PayloadCipher cipher,
  void Function(String docId, Object error, StackTrace stackTrace)? onMalformed,
}) async {
  final entries = await Future.wait(
    snapshot.docs.map((document) async {
      try {
        return await decodeCalorieEntryDocument(document, cipher: cipher);
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
        return null;
      }
    }),
  );
  return entries.nonNulls.toList();
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
