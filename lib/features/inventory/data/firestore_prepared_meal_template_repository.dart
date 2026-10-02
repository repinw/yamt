import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository_contract.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_store.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

const String _repositoryLogName = 'FirestorePreparedMealTemplateRepository';

/// Defines firestore prepared meal template repository.
class FirestorePreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  /// Creates an instance.
  new({
    required this._session,
    required this._sessionShutdownSignal,
    required this._store,
  });

  final InventoryUserSession _session;
  final SessionShutdownSignal _sessionShutdownSignal;
  final PreparedMealTemplateStore _store;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  Stream<List<PreparedMeal>> watchAll() {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Stream<List<PreparedMeal>>.value(const <PreparedMeal>[]);
    }
    return _watchAllForHousehold(householdId);
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return const <PreparedMeal>[];
    }
    return await _readAllForHousehold(householdId);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> templates) {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(
      () => _replaceAllForHousehold(householdId, templates),
    );
  }

  String? _currentHouseholdId() {
    final householdId = _session.householdId;
    if (householdId != null && householdId.isNotEmpty) {
      return householdId;
    }
    log(
      'No active household for prepared meal template repository.',
      name: _repositoryLogName,
    );
    return null;
  }

  Stream<List<PreparedMeal>> _watchAllForHousehold(String householdId) async* {
    final collectionPath = 'households/$householdId/prepared_meal_templates';
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
          'Prepared meal template watch closed during session shutdown for '
          '$collectionPath.',
          name: _repositoryLogName,
        );
        yield const <PreparedMeal>[];
        return;
      }
      log(
        error.code == 'permission-denied'
            ? 'Prepared meal template watch denied by Firestore rules for '
                  '$collectionPath.'
            : 'Failed to watch prepared meal templates for '
                  'household $householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to watch prepared meal templates for household $householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<PreparedMeal>> _readAllForHousehold(String householdId) async {
    try {
      final documents = await _store.readAll(householdId: householdId);
      return _decodeDocuments(documents);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read prepared meal templates for household $householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      // Callers write the whole list back; no templates would delete them
      // all.
      rethrow;
    }
  }

  Future<bool> _replaceAllForHousehold(
    String householdId,
    List<PreparedMeal> templates,
  ) {
    final documentsById = <String, Map<String, dynamic>>{
      for (final template in templates) template.id: template.toJson(),
    };
    return _store.replaceAll(
      householdId: householdId,
      documentsById: documentsById,
      parse: _decode,
    );
  }

  List<PreparedMeal> _decodeDocuments(
    List<PreparedMealTemplateDocument> documents,
  ) {
    final templates = <PreparedMeal>[];
    for (var index = 0; index < documents.length; index += 1) {
      try {
        templates.add(_decode(documents[index].id, documents[index].data));
      } on Object catch (error, stackTrace) {
        log(
          'Skipping corrupted prepared meal template at index $index.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return templates;
  }

  /// Decodes a stored document; reads and the [saveAll] delete check agree.
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
