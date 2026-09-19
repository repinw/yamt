import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/data/unavailable_calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_log_repository.g.dart';

const _repositoryLogName = 'FirestoreCalorieLogRepository';
const _usersCollection = 'users';
const _calorieEntriesCollection = 'calorie_entries';

/// Defines calorie log user session.
abstract interface class CalorieLogUserSession {
  /// The current user id.
  String? get currentUserId;
}

/// Defines firestore calorie log repository.
class FirestoreCalorieLogRepository implements CalorieLogRepositoryContract {
  /// Creates an instance.
  new({required this._session, required this._firestore});

  final CalorieLogUserSession _session;
  final FirebaseFirestore _firestore;
  final _cache = <String, CalorieEntry>{};

  @override
  CalorieEntry? cachedById(String entryId) => _cache[entryId];

  List<CalorieEntry> _remember(List<CalorieEntry> entries) {
    for (final entry in entries) {
      _cache[entry.id] = entry;
    }
    return entries;
  }

  @override
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day) {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream<List<CalorieEntry>>.value(const <CalorieEntry>[]);
    }

    final bounds = _dayBoundsLocal(day);
    final query = _collection(userId)
        .where('logged_at', isGreaterThanOrEqualTo: bounds.startInclusive)
        .where('logged_at', isLessThan: bounds.endExclusive)
        .orderBy('logged_at');

    return Stream<List<CalorieEntry>>.multi((controller) {
      final subscription = query.snapshots().listen(
        (snapshot) {
          controller.add(_remember(_decodeSnapshot(snapshot)));
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
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const <CalorieEntry>[];
    }

    try {
      final bounds = _dayBoundsLocal(day);
      final snapshot = await _collection(userId)
          .where('logged_at', isGreaterThanOrEqualTo: bounds.startInclusive)
          .where('logged_at', isLessThan: bounds.endExclusive)
          .orderBy('logged_at')
          .get();
      return _remember(_decodeSnapshot(snapshot));
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read calories for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <CalorieEntry>[];
    }
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
      return _remember(_decodeSnapshot(snapshot));
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
      return _decodeDocument(snapshot.docs.first).loggedAt;
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
  Future<bool> saveEntry(CalorieEntry entry) async {
    return await saveEntryForCurrentUser(entry);
  }

  @override
  Future<bool> saveEntryForCurrentUser(CalorieEntry entry) async {
    final userId = _currentUserId();
    if (userId == null) {
      return false;
    }

    try {
      final normalizedEntry = entry.copyWith(
        imageUrl: normalizeCalorieProductImageUrl(entry.imageUrl),
        userId: userId,
        updatedAt: DateTime.now(),
      );
      await _collection(userId)
          .doc(normalizedEntry.id)
          .set(normalizedEntry.toJson());
      _cache[normalizedEntry.id] = normalizedEntry;
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

    try {
      await _collection(userId).doc(entryId).delete();
      _cache.remove(entryId);
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete calorie entry $entryId for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
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
      final entry = _decodeDocument(snapshot);
      _cache[entry.id] = entry;
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

  String? _currentUserId() {
    final userId = _session.currentUserId;
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_calorieEntriesCollection);
  }

  List<CalorieEntry> _decodeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final entries = <CalorieEntry>[];
    for (final document in snapshot.docs) {
      try {
        entries.add(_decodeDocument(document));
      } on Object catch (error, stackTrace) {
        log(
          'Skipping malformed calorie entry ${document.id}',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return entries;
  }

  CalorieEntry _decodeDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final rawData = doc.data() ?? const <String, dynamic>{};
    final normalizedData = normalizeFirestoreJson(rawData);
    final id = normalizedData['id'];
    if (id is! String || id.trim().isEmpty) {
      normalizedData['id'] = doc.id;
    }
    final entry = CalorieEntry.fromJson(normalizedData);
    return entry.copyWith(
      imageUrl: normalizeCalorieProductImageUrl(entry.imageUrl),
    );
  }

  ({DateTime startInclusive, DateTime endExclusive}) _dayBoundsLocal(
    DateTime day,
  ) {
    final start = normalizeDiaryDay(day);
    final end = nextDiaryDay(start);
    return (startInclusive: start, endExclusive: end);
  }
}

/// Calorie log repository.
@riverpod
CalorieLogRepositoryContract calorieLogRepository(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final firestore = _resolveFirestore();
  if (firestore == null) {
    return const UnavailableCalorieLogRepository();
  }
  return FirestoreCalorieLogRepository(
    session: _CurrentCalorieLogUserSession(currentUserId: currentUserId),
    firestore: firestore,
  );
}

class _CurrentCalorieLogUserSession implements CalorieLogUserSession {
  const new({required this._currentUserId});

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

FirebaseFirestore? _resolveFirestore() {
  try {
    return FirebaseFirestore.instance;
  } on Object catch (error, stackTrace) {
    log(
      'Falling back to unavailable calorie log repository.',
      name: _repositoryLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}
