import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/data/calorie_entry_cache.dart';
import 'package:yamt/features/calories/data/calorie_entry_document_codec.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/unavailable_calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_log_repository.g.dart';

const _repositoryLogName = 'FirestoreCalorieLogRepository';
const _usersCollection = 'users';
const _calorieEntriesCollection = 'calorie_entries';

/// Defines firestore calorie log repository.
///
/// Entries are stored encrypted with the data key of the user. Only
/// `logged_at` stays readable, for the range queries.
///
/// It owns `users/{uid}/calorie_entries`: other writers add their entry
/// writes to a batch through [stage] and [stageDelete], which keep the entry
/// cache in step.
class FirestoreCalorieLogRepository implements CalorieLogRepositoryContract {
  /// Creates an instance.
  new({
    required this.dataCipher,
    required this.firestore,
    this._now = DateTime.now,
  });

  /// The signed-in user and the cipher for their data, or `null` while the
  /// data key is not ready.
  final UserDataCipher? dataCipher;

  /// The Firestore instance.
  final FirebaseFirestore firestore;

  final DateTime Function() _now;
  final _cache = CalorieEntryCache();

  @override
  CalorieEntry? cachedById(String entryId) => _cache.get(entryId);

  @override
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day) {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream<List<CalorieEntry>>.value(const <CalorieEntry>[]);
    }

    final bounds = diaryDayBounds(day);
    final query = _collection(userId)
        .where('logged_at', isGreaterThanOrEqualTo: bounds.startInclusive)
        .where('logged_at', isLessThan: bounds.endExclusive)
        .orderBy('logged_at');

    return Stream<List<CalorieEntry>>.multi((controller) {
      final subscription = query
          .snapshots()
          .asyncMap(
            (snapshot) => decodeCalorieEntrySnapshot(snapshot, cipher: _cipher),
          )
          .listen(
            (entries) {
              controller.add(_cache.rememberAll(entries));
            },
            onError: (Object error, StackTrace stackTrace) {
              log(
                'Failed to watch calories for user $userId',
                name: _repositoryLogName,
                error: error,
                stackTrace: stackTrace,
              );
              controller.add(const <CalorieEntry>[]);
            },
            onDone: controller.close,
          );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day) {
    final bounds = diaryDayBounds(day);
    return readEntriesInRange(
      startInclusive: bounds.startInclusive,
      endExclusive: bounds.endExclusive,
    );
  }

  @override
  Future<List<CalorieEntry>> readEntriesInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const <CalorieEntry>[];
    }

    try {
      final snapshot = await _collection(userId)
          .where('logged_at', isGreaterThanOrEqualTo: startInclusive)
          .where('logged_at', isLessThan: endExclusive)
          .orderBy('logged_at')
          .get();
      return _cache.rememberAll(
        await decodeCalorieEntrySnapshot(snapshot, cipher: _cipher),
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read calorie range for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <CalorieEntry>[];
    }
  }

  @override
  Future<DateTime?> readFirstEntryDate() async {
    final userId = _currentUserId();
    if (userId == null) {
      return null;
    }

    try {
      final snapshot = await _collection(userId)
          .orderBy('logged_at')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final loggedAt = snapshot.docs.first.data()[calorieEntryLoggedAtField];
      return (loggedAt as Timestamp).toDate();
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read first calorie entry date for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<bool> saveEntry(CalorieEntry entry) => saveEntryForCurrentUser(entry);

  @override
  Future<bool> saveEntryForCurrentUser(CalorieEntry entry) async {
    final userId = _currentUserId();
    if (userId == null) {
      return false;
    }

    try {
      final batch = firestore.batch();
      await stage(batch, entry);
      commitBatchInBackground(
        batch,
        failureMessage:
            'Server rejected calorie entry ${entry.id} for user $userId',
        logName: _repositoryLogName,
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save calorie entry ${entry.id} for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return false;
    }

    final batch = firestore.batch();
    stageDelete(batch, entryId);
    commitBatchInBackground(
      batch,
      failureMessage:
          'Server rejected deleting calorie entry $entryId for user $userId',
      logName: _repositoryLogName,
    );
    return true;
  }

  @override
  Future<CalorieEntry?> getById(String entryId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return null;
    }

    try {
      final snapshot = await _collection(userId).doc(entryId).get();
      if (!snapshot.exists) {
        _cache.remove(entryId);
        return null;
      }
      final entry = await decodeCalorieEntryDocument(snapshot, cipher: _cipher);
      _cache.put(entry);
      return entry;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load calorie entry $entryId for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Adds the write of [entry] to [batch] and returns the stored entry.
  ///
  /// The stored entry belongs to the signed-in user, carries a normalized
  /// image URL, and is updated at [updatedAt], or at the current time without
  /// it. Throws while no user with a data key is signed in.
  Future<CalorieEntry> stage(
    WriteBatch batch,
    CalorieEntry entry, {
    DateTime? updatedAt,
  }) async {
    final userId = _requireUserId();
    final stored = await stageCalorieEntry(
      batch,
      _collection(userId).doc(entry.id),
      entry,
      userId: userId,
      cipher: _cipher,
      updatedAt: updatedAt ?? _now(),
    );
    _cache.put(stored);
    return stored;
  }

  /// Adds the delete of the entry [entryId] to [batch]. Throws while no user
  /// with a data key is signed in.
  void stageDelete(WriteBatch batch, String entryId) {
    batch.delete(_collection(_requireUserId()).doc(entryId));
    _cache.remove(entryId);
  }

  String? _currentUserId() => dataCipher?.uid;

  String _requireUserId() =>
      _currentUserId() ??
      (throw StateError('No signed-in user with a data key for the diary.'));

  /// Only called after [_currentUserId] returned a user.
  PayloadCipher get _cipher => dataCipher!.cipher;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_calorieEntriesCollection);
  }
}

/// Calorie log repository.
@riverpod
CalorieLogRepositoryContract calorieLogRepository(Ref ref) {
  final dataCipher = ref.watch(userDataCipherProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return const UnavailableCalorieLogRepository();
  }
  return FirestoreCalorieLogRepository(
    dataCipher: dataCipher,
    firestore: firestore,
    now: ref.watch(clockProvider),
  );
}
