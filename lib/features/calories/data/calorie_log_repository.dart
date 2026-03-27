import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

part 'calorie_log_repository.g.dart';

const _repositoryLogName = 'FirestoreCalorieLogRepository';
const _usersCollection = 'users';
const _calorieEntriesCollection = 'calorie_entries';

abstract interface class CalorieLogUserSession {
  String? get currentUserId;
}

class FirestoreCalorieLogRepository implements CalorieLogRepositoryContract {
  FirestoreCalorieLogRepository({
    required CalorieLogUserSession session,
    required FirebaseFirestore firestore,
  }) : _session = session,
       _firestore = firestore;

  final CalorieLogUserSession _session;
  final FirebaseFirestore _firestore;

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
    final dayLabel = _formatDebugDay(day);

    log(
      'Starting calorie entry watch user=$userId day=$dayLabel '
      'rangeStart=${bounds.startInclusive.toIso8601String()} '
      'rangeEnd=${bounds.endExclusive.toIso8601String()}.',
      name: _repositoryLogName,
    );

    return Stream<List<CalorieEntry>>.multi((controller) {
      final subscription = query.snapshots().listen(
        (snapshot) {
          final entries = _decodeSnapshot(snapshot);
          log(
            'Calorie watch snapshot user=$userId day=$dayLabel '
            'docs=${snapshot.docs.length} decoded=${entries.length} '
            'bundles=${_bundleCount(entries)}.',
            name: _repositoryLogName,
          );
          controller.add(entries);
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
      controller.onCancel = () {
        subscription.cancel();
      };
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
      final dayLabel = _formatDebugDay(day);
      log(
        'Reading calorie entries user=$userId day=$dayLabel '
        'rangeStart=${bounds.startInclusive.toIso8601String()} '
        'rangeEnd=${bounds.endExclusive.toIso8601String()}.',
        name: _repositoryLogName,
      );
      final snapshot = await _collection(userId)
          .where('logged_at', isGreaterThanOrEqualTo: bounds.startInclusive)
          .where('logged_at', isLessThan: bounds.endExclusive)
          .orderBy('logged_at')
          .get();
      final entries = _decodeSnapshot(snapshot);
      log(
        'Calorie entries read completed user=$userId day=$dayLabel '
        'docs=${snapshot.docs.length} decoded=${entries.length} '
        'bundles=${_bundleCount(entries)}.',
        name: _repositoryLogName,
      );
      return entries;
    } catch (error, stackTrace) {
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
  Future<bool> saveEntry(CalorieEntry entry) async {
    final userId = _currentUserId();
    if (userId == null) {
      return false;
    }

    try {
      log(
        'Saving calorie entry id=${entry.id} user=$userId '
        'isBundle=${entry.isBundle} mealType=${entry.mealType.name} '
        'loggedAt=${entry.loggedAt.toIso8601String()} '
        'bundleComponents=${entry.bundleComponents.length}.',
        name: _repositoryLogName,
      );
      final normalizedEntry = entry.copyWith(
        imageUrl: normalizeCalorieProductImageUrl(entry.imageUrl),
        userId: userId,
        updatedAt: DateTime.now(),
      );
      await _collection(
        userId,
      ).doc(normalizedEntry.id).set(normalizedEntry.toJson());
      log(
        'Saved calorie entry id=${normalizedEntry.id} user=$userId '
        'isBundle=${normalizedEntry.isBundle} '
        'sourceMealId=${normalizedEntry.bundleSourcePreparedMealId}.',
        name: _repositoryLogName,
      );
      return true;
    } catch (error, stackTrace) {
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
      return true;
    } catch (error, stackTrace) {
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
        return null;
      }
      return _decodeDocument(snapshot);
    } catch (error, stackTrace) {
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
      } catch (error, stackTrace) {
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
    final normalizedData = _normalizeFirestoreJson(rawData);
    final id = normalizedData['id'];
    if (id is! String || id.trim().isEmpty) {
      normalizedData['id'] = doc.id;
    }
    final entry = CalorieEntry.fromJson(normalizedData);
    final normalizedEntry = entry.copyWith(
      imageUrl: normalizeCalorieProductImageUrl(entry.imageUrl),
    );
    if (normalizedEntry.isBundle) {
      log(
        'Decoded bundle calorie entry docId=${doc.id} '
        'sourceMealId=${normalizedEntry.bundleSourcePreparedMealId} '
        'components=${normalizedEntry.bundleComponents.length} '
        'loggedAt=${normalizedEntry.loggedAt.toIso8601String()}.',
        name: _repositoryLogName,
      );
    }
    return normalizedEntry;
  }

  Map<String, dynamic> _normalizeFirestoreJson(Map<String, dynamic> rawData) {
    return rawData.map(
      (key, value) =>
          MapEntry<String, dynamic>(key, _normalizeFirestoreValue(value)),
    );
  }

  dynamic _normalizeFirestoreValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry<String, dynamic>(
          key.toString(),
          _normalizeFirestoreValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value
          .map<dynamic>(_normalizeFirestoreValue)
          .toList(growable: false);
    }
    return value;
  }

  ({DateTime startInclusive, DateTime endExclusive}) _dayBoundsLocal(
    DateTime day,
  ) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (startInclusive: start, endExclusive: end);
  }

  int _bundleCount(List<CalorieEntry> entries) {
    return entries.where((entry) => entry.isBundle).length;
  }

  String _formatDebugDay(DateTime day) {
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '$year-$month-$dayOfMonth';
  }
}

@riverpod
CalorieLogRepositoryContract calorieLogRepository(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final firestore = _resolveFirestore();
  if (firestore == null) {
    return const _UnavailableCalorieLogRepository();
  }
  return FirestoreCalorieLogRepository(
    session: _CurrentCalorieLogUserSession(currentUserId: currentUserId),
    firestore: firestore,
  );
}

class _CurrentCalorieLogUserSession implements CalorieLogUserSession {
  const _CurrentCalorieLogUserSession({required String? currentUserId})
    : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

FirebaseFirestore? _resolveFirestore() {
  try {
    return FirebaseFirestore.instance;
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable calorie log repository.',
      name: _repositoryLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

class _UnavailableCalorieLogRepository implements CalorieLogRepositoryContract {
  const _UnavailableCalorieLogRepository();

  @override
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day) {
    return Stream<List<CalorieEntry>>.value(const <CalorieEntry>[]);
  }

  @override
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day) async {
    return const <CalorieEntry>[];
  }

  @override
  Future<bool> saveEntry(CalorieEntry entry) async {
    return false;
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    return false;
  }

  @override
  Future<CalorieEntry?> getById(String entryId) async {
    return null;
  }
}
