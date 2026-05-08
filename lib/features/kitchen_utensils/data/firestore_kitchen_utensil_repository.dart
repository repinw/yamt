import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_image_store.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_store.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';

const String _repositoryLogName = 'FirestoreKitchenUtensilRepository';

/// Firestore/Firebase Storage kitchen utensil repository.
class FirestoreKitchenUtensilRepository implements KitchenUtensilRepository {
  /// Creates repository.
  FirestoreKitchenUtensilRepository({
    required InventoryUserSession session,
    required SessionShutdownSignal sessionShutdownSignal,
    required KitchenUtensilStore store,
    required KitchenUtensilImageStore imageStore,
  }) : _session = session,
       _sessionShutdownSignal = sessionShutdownSignal,
       _store = store,
       _imageStore = imageStore;

  final InventoryUserSession _session;
  final SessionShutdownSignal _sessionShutdownSignal;
  final KitchenUtensilStore _store;
  final KitchenUtensilImageStore _imageStore;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  Stream<List<KitchenUtensil>> watchAll() {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream<List<KitchenUtensil>>.value(
        const <KitchenUtensil>[],
      );
    }
    return _watchAllForUser(userId);
  }

  @override
  Future<List<KitchenUtensil>> readAll() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const <KitchenUtensil>[];
    }
    return _readAllForUser(userId);
  }

  @override
  Future<bool> save(KitchenUtensil utensil) {
    final userId = _currentUserId();
    if (userId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(() {
      return _store.upsert(
        userId: userId,
        utensilId: utensil.id,
        data: utensil.toJson(),
      );
    });
  }

  @override
  Future<bool> delete(String utensilId) {
    final userId = _currentUserId();
    if (userId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(() {
      return _store.delete(userId: userId, utensilId: utensilId);
    });
  }

  @override
  Future<String?> uploadImage({
    required String utensilId,
    required String imageId,
    required Uint8List bytes,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return null;
    }
    final path = kitchenUtensilImageStoragePath(
      userId: userId,
      utensilId: utensilId,
      imageId: imageId,
    );
    return _imageStore.uploadBytes(path: path, bytes: bytes);
  }

  @override
  Future<bool> deleteImage(String imageStoragePath) {
    return _imageStore.deleteImage(imageStoragePath);
  }

  @override
  Future<String?> imageUrl(String imageStoragePath) {
    return _imageStore.downloadUrl(imageStoragePath);
  }

  String? _currentUserId() {
    final userId = _session.currentUserId;
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    log(
      'No signed-in user for kitchen utensil repository.',
      name: _repositoryLogName,
    );
    return null;
  }

  Stream<List<KitchenUtensil>> _watchAllForUser(String userId) async* {
    final collectionPath = 'users/$userId/kitchen_utensils';
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
          'Kitchen utensil watch closed during session shutdown for '
          '$collectionPath.',
          name: _repositoryLogName,
        );
        yield const <KitchenUtensil>[];
        return;
      }
      log(
        error.code == 'permission-denied'
            ? 'Kitchen utensil watch denied by Firestore rules for '
                  '$collectionPath.'
            : 'Failed to watch kitchen utensils for user $userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to watch kitchen utensils for user $userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<KitchenUtensil>> _readAllForUser(String userId) async {
    try {
      final documents = await _store.readAll(userId: userId);
      return _decodeDocuments(documents);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read kitchen utensils for user $userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <KitchenUtensil>[];
    }
  }

  List<KitchenUtensil> _decodeDocuments(
    List<KitchenUtensilDocument> documents,
  ) {
    final utensils = <KitchenUtensil>[];
    for (var index = 0; index < documents.length; index += 1) {
      try {
        final json = Map<String, dynamic>.from(documents[index].data);
        final rawId = json['id'];
        if (rawId == null || (rawId is String && rawId.trim().isEmpty)) {
          json['id'] = documents[index].id;
        }
        utensils.add(KitchenUtensil.fromJson(json));
      } on Object catch (error, stackTrace) {
        log(
          'Skipping corrupted kitchen utensil at index $index.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return utensils;
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
