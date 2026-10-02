import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts Firestore values into JSON values accepted by model factories.
Map<String, dynamic> normalizeFirestoreJson(Map<String, dynamic> rawData) {
  return rawData.map(
    (key, value) =>
        MapEntry<String, dynamic>(key, normalizeFirestoreValue(value)),
  );
}

/// A copy of the stored [data] that holds the document [id] when its own
/// `id` is missing or empty. Throws when the stored `id` is not a string.
Map<String, dynamic> withDocumentId(String id, Map<String, dynamic> data) {
  final json = Map<String, dynamic>.from(data);
  if ((json['id'] as String?)?.trim().isEmpty ?? true) {
    json['id'] = id;
  }
  return json;
}

/// Converts nested Firestore values into JSON values.
dynamic normalizeFirestoreValue(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is Map<String, dynamic>) {
    return normalizeFirestoreJson(value);
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry<String, dynamic>(
        key.toString(),
        normalizeFirestoreValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map<dynamic>(normalizeFirestoreValue).toList(growable: false);
  }
  return value;
}
