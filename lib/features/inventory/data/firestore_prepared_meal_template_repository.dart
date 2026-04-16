import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import 'inventory_user_session.dart';
import 'prepared_meal_template_repository_contract.dart';
import 'prepared_meal_template_store.dart';

const String _repositoryLogName = 'FirestorePreparedMealTemplateRepository';

/// Defines firestore prepared meal template repository.
class FirestorePreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  /// Creates an instance.
  FirestorePreparedMealTemplateRepository({
    required InventoryUserSession session,
    required SessionShutdownSignal sessionShutdownSignal,
    required PreparedMealTemplateStore store,
  }) : _session = session,
       _sessionShutdownSignal = sessionShutdownSignal,
       _store = store;

  final InventoryUserSession _session;
  final SessionShutdownSignal _sessionShutdownSignal;
  final PreparedMealTemplateStore _store;
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
  Future<bool> saveAll(List<PreparedMeal> templates) {
    final userId = _currentUserId();
    if (userId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(() => _replaceAllForUser(userId, templates));
  }

  String? _currentUserId() {
    final userId = _session.currentUserId;
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    log(
      'No signed-in user for prepared meal template repository.',
      name: _repositoryLogName,
    );
    return null;
  }

  Stream<List<PreparedMeal>> _watchAllForUser(String userId) async* {
    final collectionPath = 'users/$userId/prepared_meal_templates';
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
            : 'Failed to watch prepared meal templates for user $userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      log(
        'Failed to watch prepared meal templates for user $userId.',
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
        'Failed to read prepared meal templates for user $userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <PreparedMeal>[];
    }
  }

  Future<bool> _replaceAllForUser(String userId, List<PreparedMeal> templates) {
    final documentsById = <String, Map<String, dynamic>>{
      for (final template in templates) template.id: template.toJson(),
    };
    return _store.replaceAll(userId: userId, documentsById: documentsById);
  }

  List<PreparedMeal> _decodeDocuments(
    List<PreparedMealTemplateDocument> documents,
  ) {
    final templates = <PreparedMeal>[];
    for (var index = 0; index < documents.length; index += 1) {
      final json = Map<String, dynamic>.from(documents[index].data);
      if ((json['id'] as String?)?.trim().isEmpty ?? true) {
        json['id'] = documents[index].id;
      }
      try {
        templates.add(PreparedMeal.fromJson(json));
      } catch (error, stackTrace) {
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
