import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

const _codecLogName = 'CalorieProductCacheDocumentCodec';
const _offCacheStatusFound = 'found';

/// Decodes a Firestore document snapshot into a [CalorieProductProfile].
CalorieProductProfile? decodeCalorieProductDocument(
  DocumentSnapshot<Map<String, dynamic>> snapshot, {
  required String fallbackBarcode,
}) {
  final raw = snapshot.data();
  if (raw == null) {
    return null;
  }
  return decodeCalorieProductJson(
    normalizeFirestoreJson(raw),
    fallbackBarcode: fallbackBarcode,
    documentId: snapshot.id,
  );
}

/// Decodes normalized product JSON into a [CalorieProductProfile], or `null`
/// if it is malformed.
CalorieProductProfile? decodeCalorieProductJson(
  Map<String, dynamic> json, {
  required String fallbackBarcode,
  required String documentId,
}) {
  final normalized = Map<String, dynamic>.of(json);
  final barcode = normalized['barcode'];
  if (barcode is! String || barcode.isEmpty) {
    normalized['barcode'] = fallbackBarcode;
  }

  try {
    return CalorieProductProfile.fromJson(normalized);
  } on Object catch (error, stackTrace) {
    log(
      'Malformed calorie product cache document $documentId.',
      name: _codecLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

/// Decodes an Open Food Facts cache document snapshot into a
/// [CalorieProductProfile].
CalorieProductProfile? decodeOffCacheProductDocument(
  DocumentSnapshot<Map<String, dynamic>> snapshot, {
  required String fallbackBarcode,
}) {
  final raw = snapshot.data();
  if (raw == null) {
    return null;
  }

  final status = raw['status'];
  if (status is! String || status != _offCacheStatusFound) {
    return null;
  }

  final product = raw['product'];
  if (product is! Map<String, dynamic>) {
    return null;
  }

  final normalized = normalizeFirestoreJson(product);

  final barcode = normalized['barcode'];
  if (barcode is! String || barcode.isEmpty) {
    normalized['barcode'] = fallbackBarcode;
  }

  try {
    return CalorieProductProfile.fromJson(normalized);
  } on Object catch (error, stackTrace) {
    log(
      'Malformed OFF product cache document ${snapshot.id}.',
      name: _codecLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

/// Prepares a global product profile payload for saving to Firestore.
Map<String, dynamic> prepareGlobalProductPayload(
  CalorieProductProfile profile, {
  required DateTime updatedAt,
}) {
  final normalized = profile.copyWith(updatedAt: updatedAt);
  return normalized.toJson();
}

/// Prepares a user override payload for saving to Firestore.
Map<String, dynamic> prepareUserOverridePayload({
  required CalorieProductProfile profile,
  required String userId,
  required String reason,
  required DateTime now,
}) {
  final payload = profile
      .copyWith(
        source: CalorieProductSource.userOverride,
        updatedAt: now,
        createdAt: now,
      )
      .toJson();
  payload['user_id'] = userId;
  payload['reason'] = reason;
  return payload;
}
