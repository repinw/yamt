import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_store.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

const String _repositoryLogName = 'FirestoreInventoryItemRepository';

/// Defines firestore inventory item repository.
class FirestoreInventoryItemRepository implements InventoryItemRepository {
  /// Creates an instance.
  FirestoreInventoryItemRepository({
    required InventoryUserSession session,
    required SessionShutdownSignal sessionShutdownSignal,
    required InventoryItemStore store,
  }) : _session = session,
       _sessionShutdownSignal = sessionShutdownSignal,
       _store = store;

  final InventoryUserSession _session;
  final SessionShutdownSignal _sessionShutdownSignal;
  final InventoryItemStore _store;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  Stream<List<InventoryItem>> watchAll() {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream<List<InventoryItem>>.value(const <InventoryItem>[]);
    }
    return _watchAllForUser(userId);
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const <InventoryItem>[];
    }
    return _readAllForUser(userId);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) {
    final userId = _currentUserId();
    if (userId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(() => _replaceAllForUser(userId, items));
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) {
    final userId = _currentUserId();
    if (userId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(() => _upsertAllForUser(userId, items));
  }

  String? _currentUserId() {
    final userId = _session.currentUserId;
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    log(
      'No signed-in user for inventory repository.',
      name: _repositoryLogName,
    );
    return null;
  }

  Stream<List<InventoryItem>> _watchAllForUser(String userId) async* {
    final collectionPath = 'users/$userId/inventory_items';
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
          'Inventory watch closed during session shutdown for '
          '$collectionPath.',
          name: _repositoryLogName,
        );
        yield const <InventoryItem>[];
        return;
      }
      log(
        _isPermissionDenied(error)
            ? 'Inventory watch denied by Firestore rules for '
                  '$collectionPath.'
            : 'Failed to watch inventory items from firestore for user '
                  '$userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      log(
        'Failed to watch inventory items from firestore for user $userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<InventoryItem>> _readAllForUser(String userId) async {
    final collectionPath = 'users/$userId/inventory_items';
    try {
      final documents = await _store.readAll(userId: userId);
      return _decodeDocuments(documents);
    } on FirebaseException catch (error, stackTrace) {
      log(
        _isPermissionDenied(error)
            ? 'Inventory read denied by Firestore rules for '
                  '$collectionPath.'
            : 'Failed to read inventory items from firestore for user '
                  '$userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      log(
        'Failed to read inventory items from firestore for user $userId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> _replaceAllForUser(String userId, List<InventoryItem> items) {
    if (items.isEmpty) {
      log(
        'Replacing inventory with an empty collection for user $userId.',
        name: _repositoryLogName,
      );
    }
    final documentsById = <String, Map<String, dynamic>>{
      for (final item in items) item.id: _normalizeItem(item).toJson(),
    };
    return _store.replaceAll(userId: userId, documentsById: documentsById);
  }

  Future<bool> _upsertAllForUser(String userId, List<InventoryItem> items) {
    if (items.isEmpty) {
      return Future<bool>.value(true);
    }
    final documentsById = <String, Map<String, dynamic>>{
      for (final item in items) item.id: _normalizeItem(item).toJson(),
    };
    return _store.upsertAll(userId: userId, documentsById: documentsById);
  }

  List<InventoryItem> _decodeDocuments(List<InventoryItemDocument> documents) {
    final items = <InventoryItem>[];
    for (var index = 0; index < documents.length; index++) {
      final json = Map<String, dynamic>.from(documents[index].data);
      if ((json['id'] as String?)?.trim().isEmpty ?? true) {
        json['id'] = documents[index].id;
      }
      try {
        items.add(_normalizeItem(InventoryItem.fromJson(json)));
      } catch (error, stackTrace) {
        log(
          'Skipping corrupted inventory item at index $index.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return items;
  }

  InventoryItem _normalizeItem(InventoryItem item) {
    final barcode = item.normalizedBarcode;
    return item.copyWith(
      globalFoodItemId: item.globalFoodItemId.trim(),
      barcode: barcode,
      foodFingerprint: item.resolvedFoodFingerprint,
      barcodeLookupUncertain: !(barcode == null) && item.barcodeLookupUncertain,
      barcodeResolvedAt: barcode == null
          ? null
          : (item.barcodeResolvedAt ?? DateTime.now()),
    );
  }

  Future<T> _runExclusiveWrite<T>(Future<T> Function() operation) {
    final queuedOperation = _writeBarrier.then((_) => operation());
    _writeBarrier = queuedOperation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return queuedOperation;
  }

  bool _isPermissionDenied(FirebaseException error) {
    return error.code == 'permission-denied';
  }

  bool _isShutdownRelatedPermissionDenied({
    required FirebaseException error,
    required int shutdownEpoch,
  }) {
    return _isPermissionDenied(error) &&
        (_sessionShutdownSignal.isInProgress ||
            _sessionShutdownSignal.hasShutdownSince(shutdownEpoch));
  }
}
