import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/delivered_watches.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository_contract.dart';
import 'package:yamt/features/inventory/data/prepared_meal_store.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

const String _repositoryLogName = 'FirestorePreparedMealRepository';

/// Defines firestore prepared meal repository.
class FirestorePreparedMealRepository implements PreparedMealRepository {
  /// Creates an instance.
  new({required this._household, required this._sessionShutdownSignal});

  final HouseholdStore<PreparedMealStore>? _household;
  final SessionShutdownSignal _sessionShutdownSignal;

  /// Only called after [_currentHouseholdId] returned a household.
  PreparedMealStore get _store => _household!.store;
  Future<void> _writeBarrier = Future<void>.value();

  /// The running [watchAll] streams that have delivered a list. While one
  /// runs, the local cache holds the household's meals and follows the
  /// server.
  final _deliveredWatches = DeliveredWatches();

  @override
  Stream<List<PreparedMeal>> watchAll() {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Stream<List<PreparedMeal>>.value(const <PreparedMeal>[]);
    }
    return _deliveredWatches.track(_watchAllForHousehold(householdId));
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return const <PreparedMeal>[];
    }
    return await _readAllForHousehold(householdId, localFirst: false);
  }

  @override
  Future<List<PreparedMeal>> readAllForChange() async {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return const <PreparedMeal>[];
    }
    return await _readAllForHousehold(
      householdId,
      localFirst: _deliveredWatches.any,
    );
  }

  @override
  Future<bool> save(PreparedMeal meal) {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(
      () => _store.save(
        householdId: householdId,
        id: meal.id,
        data: meal.toJson(),
      ),
    );
  }

  @override
  Future<bool> delete(String mealId) {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(
      () => _store.delete(householdId: householdId, id: mealId),
    );
  }

  String? _currentHouseholdId() {
    final householdId = _household?.householdId;
    if (householdId != null && householdId.isNotEmpty) {
      return householdId;
    }
    log(
      'No active household for prepared meal repository.',
      name: _repositoryLogName,
    );
    return null;
  }

  Stream<List<PreparedMeal>> _watchAllForHousehold(String householdId) async* {
    final collectionPath = 'households/$householdId/prepared_meals';
    final shutdownEpoch = _sessionShutdownSignal.epoch;
    try {
      await for (final documents in _store.watchAll(householdId: householdId)) {
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
            : 'Failed to watch prepared meals for household $householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to watch prepared meals for household $householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<PreparedMeal>> _readAllForHousehold(
    String householdId, {
    required bool localFirst,
  }) async {
    try {
      final documents = localFirst
          ? await _store.readAllLocal(householdId: householdId)
          : await _store.readAll(householdId: householdId);
      return _decodeDocuments(documents);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read prepared meals for household $householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  List<PreparedMeal> _decodeDocuments(List<PreparedMealDocument> documents) {
    final meals = <PreparedMeal>[];
    for (var index = 0; index < documents.length; index += 1) {
      try {
        meals.add(_decode(documents[index].id, documents[index].data));
      } on Object catch (error, stackTrace) {
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

  /// Decodes a stored document.
  PreparedMeal _decode(String id, Map<String, dynamic> data) =>
      PreparedMeal.fromJson(withDocumentId(id, data));

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
