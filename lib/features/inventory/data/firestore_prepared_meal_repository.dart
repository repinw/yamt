import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import 'inventory_user_session.dart';
import 'prepared_meal_repository_contract.dart';
import 'prepared_meal_store.dart';

const String _repositoryLogName = 'FirestorePreparedMealRepository';

class FirestorePreparedMealRepository implements PreparedMealRepository {
  FirestorePreparedMealRepository({
    required InventoryUserSession session,
    required PreparedMealStore store,
  }) : _session = session,
       _store = store;

  final InventoryUserSession _session;
  final PreparedMealStore _store;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  Stream<List<PreparedMeal>> watchAll() {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream<List<PreparedMeal>>.value(const <PreparedMeal>[]);
    }
    log(
      'watchAll(): starting stream for user $userId',
      name: _repositoryLogName,
    );
    return _watchAllForUser(userId);
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const <PreparedMeal>[];
    }
    log('readAll(): reading meals for user $userId', name: _repositoryLogName);
    return _readAllForUser(userId);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) {
    final userId = _currentUserId();
    if (userId == null) {
      return Future<bool>.value(false);
    }
    log(
      'saveAll(): queueing write of ${meals.length} meals for user $userId',
      name: _repositoryLogName,
    );
    return _runExclusiveWrite(() => _replaceAllForUser(userId, meals));
  }

  String? _currentUserId() {
    final userId = _session.currentUserId;
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    log(
      'No signed-in user for prepared meal repository.',
      name: _repositoryLogName,
    );
    return null;
  }

  Stream<List<PreparedMeal>> _watchAllForUser(String userId) async* {
    try {
      await for (final documents in _store.watchAll(userId: userId)) {
        final meals = _decodeDocuments(documents);
        log(
          '_watchAllForUser(): received ${meals.length} meals for user $userId',
          name: _repositoryLogName,
        );
        yield meals;
      }
    } on FirebaseException catch (error, stackTrace) {
      if (error.code == 'permission-denied') {
        log(
          'Skipping prepared meal watch for user $userId: permission denied.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
        yield const <PreparedMeal>[];
        return;
      }
      log(
        'Failed to watch prepared meals for user $userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      log(
        'Failed to watch prepared meals for user $userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<PreparedMeal>> _readAllForUser(String userId) async {
    try {
      final documents = await _store.readAll(userId: userId);
      final meals = _decodeDocuments(documents);
      log(
        '_readAllForUser(): decoded ${meals.length} meals for user $userId',
        name: _repositoryLogName,
      );
      return meals;
    } catch (error, stackTrace) {
      log(
        'Failed to read prepared meals for user $userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <PreparedMeal>[];
    }
  }

  Future<bool> _replaceAllForUser(String userId, List<PreparedMeal> meals) {
    final documentsById = <String, Map<String, dynamic>>{
      for (final meal in meals) meal.id: meal.toJson(),
    };
    log(
      '_replaceAllForUser(): writing ${documentsById.length} docs '
      'for user $userId',
      name: _repositoryLogName,
    );
    return _store.replaceAll(userId: userId, documentsById: documentsById);
  }

  List<PreparedMeal> _decodeDocuments(List<PreparedMealDocument> documents) {
    final meals = <PreparedMeal>[];
    for (var index = 0; index < documents.length; index += 1) {
      final json = Map<String, dynamic>.from(documents[index].data);
      if ((json['id'] as String?)?.trim().isEmpty ?? true) {
        json['id'] = documents[index].id;
      }
      try {
        meals.add(PreparedMeal.fromJson(json));
      } catch (error, stackTrace) {
        log(
          'Skipping corrupted prepared meal at index $index.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return meals;
  }

  Future<T> _runExclusiveWrite<T>(Future<T> Function() operation) {
    log('_runExclusiveWrite(): waiting for write barrier', name: _repositoryLogName);
    final queuedOperation = _writeBarrier.then((_) async {
      log('_runExclusiveWrite(): entering write operation', name: _repositoryLogName);
      final value = await operation();
      log('_runExclusiveWrite(): leaving write operation', name: _repositoryLogName);
      return value;
    });
    _writeBarrier = queuedOperation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return queuedOperation;
  }
}
