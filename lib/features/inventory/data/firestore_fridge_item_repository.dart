import 'dart:async';
import 'dart:developer' show log;

import 'package:yamt/features/inventory/domain/food_fingerprint.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';

import 'fridge_item_repository_contract.dart';
import 'inventory_fridge_item_store.dart';
import 'inventory_user_session.dart';

const String _repositoryLogName = 'FirestoreFridgeItemRepository';

class FirestoreFridgeItemRepository implements FridgeItemRepository {
  FirestoreFridgeItemRepository({
    required InventoryUserSession session,
    required InventoryFridgeItemStore store,
  }) : _session = session,
       _store = store;

  final InventoryUserSession _session;
  final InventoryFridgeItemStore _store;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  Stream<List<FridgeItem>> watchAll() {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream<List<FridgeItem>>.value(const <FridgeItem>[]);
    }
    return _watchAllForUser(userId);
  }

  @override
  Future<List<FridgeItem>> readAll() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const <FridgeItem>[];
    }
    return _readAllForUser(userId);
  }

  @override
  Future<bool> saveAll(List<FridgeItem> items) {
    final userId = _currentUserId();
    if (userId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(() => _replaceAllForUser(userId, items));
  }

  @override
  Future<bool> appendAll(List<FridgeItem> items) {
    final userId = _currentUserId();
    if (userId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(() => _upsertAllForUser(userId, items));
  }

  Future<bool> _upsertAllForUser(String userId, List<FridgeItem> items) {
    if (items.isEmpty) {
      return Future<bool>.value(true);
    }

    final normalizedItems = items
        .map(_normalizeItemForPersistence)
        .toList(growable: false);
    final documentsById = <String, Map<String, dynamic>>{
      for (final item in normalizedItems) item.id: item.toJson(),
    };
    return _store.upsertAll(userId: userId, documentsById: documentsById);
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

  Stream<List<FridgeItem>> _watchAllForUser(String userId) async* {
    try {
      await for (final documents in _store.watchAll(userId: userId)) {
        final decodedItems = _decodeDocuments(documents);
        yield await _hydrateResolvedBarcodesForUser(
          userId: userId,
          items: decodedItems,
        );
      }
    } catch (error, stackTrace) {
      log(
        'Failed to watch inventory items from firestore for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<FridgeItem>> _readAllForUser(String userId) async {
    try {
      final documents = await _store.readAll(userId: userId);
      final decodedItems = _decodeDocuments(documents);
      return _hydrateResolvedBarcodesForUser(
        userId: userId,
        items: decodedItems,
      );
    } catch (error, stackTrace) {
      log(
        'Failed to read inventory items from firestore for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <FridgeItem>[];
    }
  }

  List<FridgeItem> _decodeDocuments(
    List<InventoryFridgeItemDocument> documents,
  ) {
    final items = <FridgeItem>[];
    for (var index = 0; index < documents.length; index++) {
      final json = _normalizeDocumentJson(documents[index]);
      try {
        items.add(_normalizeLoadedItem(FridgeItem.fromJson(json)));
      } catch (error, stackTrace) {
        log(
          'Skipping corrupted firestore fridge item at index $index',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return items;
  }

  Map<String, dynamic> _normalizeDocumentJson(
    InventoryFridgeItemDocument document,
  ) {
    final json = Map<String, dynamic>.from(document.data);
    final idValue = json['id'];
    if (idValue is! String || idValue.trim().isEmpty) {
      json['id'] = document.id;
    }
    return json;
  }

  Future<bool> _replaceAllForUser(String userId, List<FridgeItem> items) {
    final normalizedItems = items
        .map(_normalizeItemForPersistence)
        .toList(growable: false);
    final documentsById = <String, Map<String, dynamic>>{
      for (final item in normalizedItems) item.id: item.toJson(),
    };
    return _store.replaceAll(userId: userId, documentsById: documentsById);
  }

  FridgeItem _normalizeLoadedItem(FridgeItem item) {
    final fingerprint = item.foodFingerprint?.trim();
    if (fingerprint != null && fingerprint.isNotEmpty) {
      return item;
    }
    return item.copyWith(
      foodFingerprint: computeFoodFingerprint(
        name: item.name,
        brand: item.brand,
      ),
    );
  }

  Future<List<FridgeItem>> _hydrateResolvedBarcodesForUser({
    required String userId,
    required List<FridgeItem> items,
  }) async {
    if (items.isEmpty) {
      return items;
    }

    final pendingFingerprints = <String>{
      for (final item in items)
        if (item.normalizedBarcode == null) item.resolvedFoodFingerprint,
    };
    if (pendingFingerprints.isEmpty) {
      return items;
    }

    Map<String, String> resolvedByFingerprint;
    try {
      resolvedByFingerprint = await _store.readResolvedBarcodes(
        userId: userId,
        fingerprints: pendingFingerprints,
      );
    } catch (error, stackTrace) {
      log(
        'Failed to read resolved barcode requests for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return items;
    }
    if (resolvedByFingerprint.isEmpty) {
      return items;
    }

    final now = DateTime.now();
    final updatedItems = <FridgeItem>[];
    final hydratedItems = List<FridgeItem>.from(items);
    for (var index = 0; index < hydratedItems.length; index++) {
      final item = hydratedItems[index];
      if (item.normalizedBarcode != null) {
        continue;
      }

      final resolvedBarcode =
          resolvedByFingerprint[item.resolvedFoodFingerprint]?.trim();
      if (resolvedBarcode == null || resolvedBarcode.isEmpty) {
        continue;
      }

      final updated = item.copyWith(
        barcode: resolvedBarcode,
        barcodeResolvedAt: item.barcodeResolvedAt ?? now,
      );
      hydratedItems[index] = updated;
      updatedItems.add(updated);
    }
    if (updatedItems.isEmpty) {
      return items;
    }

    unawaited(
      _runExclusiveWrite(() => _upsertAllForUser(userId, updatedItems)),
    );
    return hydratedItems;
  }

  FridgeItem _normalizeItemForPersistence(FridgeItem item) {
    final barcode = item.normalizedBarcode;
    final fingerprint = item.foodFingerprint?.trim();
    return item.copyWith(
      barcode: barcode,
      foodFingerprint: (fingerprint == null || fingerprint.isEmpty)
          ? computeFoodFingerprint(name: item.name, brand: item.brand)
          : fingerprint,
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
}
