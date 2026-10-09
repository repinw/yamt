import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_store.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

const String _repositoryLogName = 'FirestoreInventoryItemRepository';

/// Defines firestore inventory item repository.
class FirestoreInventoryItemRepository
    implements InventoryItemRepository, InventoryItemRecentManualReader {
  /// Creates an instance.
  new({required this._household, required this._sessionShutdownSignal});

  final HouseholdStore<InventoryItemStore>? _household;
  final SessionShutdownSignal _sessionShutdownSignal;

  /// Only called after [_currentHouseholdId] returned a household.
  InventoryItemStore get _store => _household!.store;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  bool get supportsLimitedRecentManualReads => true;

  @override
  Stream<List<InventoryItem>> watchAll() {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Stream<List<InventoryItem>>.value(const <InventoryItem>[]);
    }
    return _watchAllForHousehold(householdId);
  }

  @override
  Future<List<InventoryItem>> readAll() => _readAll(localFirst: false);

  @override
  Future<List<InventoryItem>> readAllLocal() => _readAll(localFirst: true);

  @override
  Future<List<InventoryItem>> readRecentManualItems({
    required int limit,
  }) async {
    final householdId = _currentHouseholdId();
    if (householdId == null || limit <= 0) {
      return const <InventoryItem>[];
    }
    return await _readRecentManualForHousehold(
      householdId: householdId,
      limit: limit,
    );
  }

  @override
  Future<bool> save(InventoryItem item) {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(
      () => _store.save(
        householdId: householdId,
        id: item.id,
        data: _normalizeItem(item).toJson(),
      ),
    );
  }

  @override
  Future<bool> delete(String itemId) {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(
      () => _store.delete(householdId: householdId, id: itemId),
    );
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(() => _upsertAllForHousehold(householdId, items));
  }

  String? _currentHouseholdId() {
    final householdId = _household?.householdId;
    if (householdId != null && householdId.isNotEmpty) {
      return householdId;
    }
    log(
      'No active household for inventory repository.',
      name: _repositoryLogName,
    );
    return null;
  }

  Stream<List<InventoryItem>> _watchAllForHousehold(String householdId) async* {
    final collectionPath = 'households/$householdId/inventory_items';
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
            : 'Failed to watch inventory items from firestore for household '
                  '$householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to watch inventory items from firestore for '
        'household $householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<InventoryItem>> _readAll({required bool localFirst}) async {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return const <InventoryItem>[];
    }
    final collectionPath = 'households/$householdId/inventory_items';
    try {
      final documents = localFirst
          ? await _store.readAllLocal(householdId: householdId)
          : await _store.readAll(householdId: householdId);
      return _decodeDocuments(documents);
    } on FirebaseException catch (error, stackTrace) {
      log(
        _isPermissionDenied(error)
            ? 'Inventory read denied by Firestore rules for '
                  '$collectionPath.'
            : 'Failed to read inventory items from firestore for household '
                  '$householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read inventory items from firestore for '
        'household $householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<InventoryItem>> _readRecentManualForHousehold({
    required String householdId,
    required int limit,
  }) async {
    final collectionPath = 'households/$householdId/inventory_items';
    try {
      final store = _store;
      if (store is InventoryItemRecentManualStore) {
        final recentStore = store as InventoryItemRecentManualStore;
        final documents = await recentStore.readRecentManual(
          householdId: householdId,
          limit: limit,
        );
        return _decodeDocuments(documents);
      }

      throw StateError(
        'Inventory item store does not support recent manual reads.',
      );
    } on FirebaseException catch (error, stackTrace) {
      log(
        _isPermissionDenied(error)
            ? 'Recent manual inventory read denied by Firestore rules for '
                  '$collectionPath.'
            : 'Failed to read recent manual inventory items from firestore '
                  'for household $householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read recent manual inventory items from firestore for '
        'household $householdId.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> _upsertAllForHousehold(
    String householdId,
    List<InventoryItem> items,
  ) {
    if (items.isEmpty) {
      return Future<bool>.value(true);
    }
    final documentsById = <String, Map<String, dynamic>>{
      for (final item in items) item.id: _normalizeItem(item).toJson(),
    };
    return _store.upsertAll(
      householdId: householdId,
      documentsById: documentsById,
    );
  }

  List<InventoryItem> _decodeDocuments(List<InventoryItemDocument> documents) {
    final items = <InventoryItem>[];
    for (var index = 0; index < documents.length; index++) {
      try {
        items.add(_decode(documents[index].id, documents[index].data));
      } on Object catch (error, stackTrace) {
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

  InventoryItem _decode(String id, Map<String, dynamic> data) =>
      _normalizeItem(InventoryItem.fromJson(withDocumentId(id, data)));

  InventoryItem _normalizeItem(InventoryItem item) {
    final barcode = item.normalizedBarcode;
    return item.copyWith(
      globalFoodItemId: item.globalFoodItemId.trim(),
      barcode: barcode,
      foodFingerprint: item.resolvedFoodFingerprint,
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
