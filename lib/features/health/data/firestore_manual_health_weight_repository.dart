import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

const _usersCollection = 'users';
const _weightsCollection = 'health_weights';
const _logName = 'FirestoreManualHealthWeightRepository';

/// Defines firestore manual health weight repository.
class FirestoreManualHealthWeightRepository
    implements ManualHealthWeightRepository {
  /// Creates an instance.
  FirestoreManualHealthWeightRepository({
    required FirebaseFirestore? firestore,
    required String? currentUserId,
  }) : _firestore = firestore,
       _currentUserId = currentUserId;

  final FirebaseFirestore? _firestore;
  final String? _currentUserId;

  @override
  Future<List<ManualHealthWeightEntry>> readEntries() async {
    final collection = _collection();
    if (collection == null) {
      return const <ManualHealthWeightEntry>[];
    }

    try {
      final snapshot = await collection.get();
      final entries =
          snapshot.docs
              .map(
                (document) => ManualHealthWeightEntry.fromJson(document.data()),
              )
              .whereType<ManualHealthWeightEntry>()
              .toList(growable: false)
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
      await collection.doc(_documentIdForDay(entry.day)).set(<String, Object?>{
        ...entry.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
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

  CollectionReference<Map<String, dynamic>>? _collection() {
    final firestore = _firestore;
    final userId = _normalizedUserId;
    if (firestore == null || userId == null) {
      return null;
    }
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_weightsCollection);
  }

  String? get _normalizedUserId {
    final userId = _currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }
}

String _documentIdForDay(DateTime day) {
  final normalizedDay = normalizeDiaryDay(day);
  final month = normalizedDay.month.toString().padLeft(2, '0');
  final date = normalizedDay.day.toString().padLeft(2, '0');
  return '${normalizedDay.year}-$month-$date';
}
