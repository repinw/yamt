import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import 'inventory_user_session.dart';
import 'prepared_meal_repository_contract.dart';
import 'prepared_meal_store.dart';

const String _repositoryLogName = 'FirestorePreparedMealRepository';

class FirestorePreparedMealRepository implements PreparedMealRepository {
  FirestorePreparedMealRepository({
    required InventoryUserSession session,
    required SessionShutdownSignal sessionShutdownSignal,
    required PreparedMealStore store,
  }) : _session = session,
       _sessionShutdownSignal = sessionShutdownSignal,
       _store = store;

  final InventoryUserSession _session;
  final SessionShutdownSignal _sessionShutdownSignal;
  final PreparedMealStore _store;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  Stream<List<PreparedMeal>> watchAll() {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream<List<PreparedMeal>>.value(const <PreparedMeal>[]);
    }
    return _watchAllForUser(userId);
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const <PreparedMeal>[];
    }
    return _readAllForUser(userId);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) {
    final userId = _currentUserId();
    if (userId == null) {
      return Future<bool>.value(false);
    }
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
    final collectionPath = 'users/$userId/prepared_meals';
    final shutdownEpoch = _sessionShutdownSignal.epoch;
    try {
      await for (final documents in _store.watchAll(userId: userId)) {
        yield _decodeDocuments(documents);
      }
    } on FirebaseException catch (error, stackTrace) {
      if (_isShutdownRelatedPermissionDenied(
        error: error,
        shutdownEpoch: shutdownEpoch,
      )) {
        log(
          'Prepared meal watch closed during session shutdown for '
          '$collectionPath.',
          name: _repositoryLogName,
        );
        yield const <PreparedMeal>[];
        return;
      }
      log(
        error.code == 'permission-denied'
            ? 'Prepared meal watch denied by Firestore rules for '
                  '$collectionPath.'
            : 'Failed to watch prepared meals for user $userId.',
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
      return _decodeDocuments(documents);
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
    final queuedOperation = _writeBarrier.then((_) => operation());
    _writeBarrier = queuedOperation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return queuedOperation;
  }

  bool _isShutdownRelatedPermissionDenied({
    required FirebaseException error,
    required int shutdownEpoch,
  }) {
    return error.code == 'permission-denied' &&
        (_sessionShutdownSignal.isInProgress ||
            _sessionShutdownSignal.hasShutdownSince(shutdownEpoch));
  }
}
