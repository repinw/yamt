import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

const _usersCollection = 'users';
const _weightsCollection = 'health_weights';
const _logName = 'FirestoreManualHealthWeightRepository';

/// Defines firestore manual health weight repository.
///
/// Weights are stored encrypted with the data key of the user. The document
/// id is the day.
class FirestoreManualHealthWeightRepository
    implements ManualHealthWeightRepository {
  /// Creates an instance.
  new({required this._firestore, required this._dataCipher});

  final FirebaseFirestore? _firestore;
  final UserDataCipher? _dataCipher;

  @override
  Future<List<ManualHealthWeightEntry>> readEntries() async {
    final collection = _collection();
    if (collection == null) {
      return const <ManualHealthWeightEntry>[];
    }

    try {
      final snapshot = await collection.get();
      final decoded = await Future.wait(snapshot.docs.map(_decodeDocument));
      final entries = decoded.nonNulls.toList(growable: false)
        ..sort((left, right) => left.day.compareTo(right.day));
      return List<ManualHealthWeightEntry>.unmodifiable(entries);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read fallback weight entries.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <ManualHealthWeightEntry>[];
    }
  }

  @override
  Future<bool> saveEntry(ManualHealthWeightEntry entry) async {
    final collection = _collection();
    if (collection == null) {
      return false;
    }

    try {
      final reference = collection.doc(_documentIdForDay(entry.day));
      await reference.set(<String, Object?>{
        encryptedPayloadField: await _dataCipher!.cipher.encryptJson(
          entry.toJson(),
          aad: reference.path,
        ),
      });
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save fallback weight entry.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> deleteEntryForDay(DateTime day) async {
    final collection = _collection();
    if (collection == null) {
      return false;
    }

    try {
      await collection.doc(_documentIdForDay(day)).delete();
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete fallback weight entry.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<ManualHealthWeightEntry?> _decodeDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    try {
      final payload = document.data()[encryptedPayloadField];
      if (payload is! String) {
        throw FormatException('Weight ${document.id} has no payload.');
      }
      return ManualHealthWeightEntry.fromJson(
        await _dataCipher!.cipher.decryptJson(
          payload,
          aad: document.reference.path,
        ),
      );
    } on Object catch (error, stackTrace) {
      log(
        'Skipping malformed weight entry ${document.id}.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? _collection() {
    final firestore = _firestore;
    final userId = _dataCipher?.uid;
    if (firestore == null || userId == null) {
      return null;
    }
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_weightsCollection);
  }
}

String _documentIdForDay(DateTime day) {
  final normalizedDay = normalizeLocalDay(day);
  final month = normalizedDay.month.toString().padLeft(2, '0');
  final date = normalizedDay.day.toString().padLeft(2, '0');
  return '${normalizedDay.year}-$month-$date';
}
