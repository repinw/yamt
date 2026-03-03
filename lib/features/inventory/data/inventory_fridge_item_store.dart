import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';

const String _storeLogName = 'FirestoreInventoryFridgeItemStore';
const String _usersCollection = 'users';
const String _inventoryItemsCollection = 'inventory_items';
const String _barcodeEnrichmentRequestsCollection =
    'barcode_enrichment_requests';

class InventoryFridgeItemDocument {
  const InventoryFridgeItemDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

abstract interface class InventoryFridgeItemStore {
  Future<List<InventoryFridgeItemDocument>> readAll({required String userId});

  Stream<List<InventoryFridgeItemDocument>> watchAll({required String userId});

  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });

  Future<bool> upsertAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });

  Future<Map<String, String>> readResolvedBarcodes({
    required String userId,
    required Iterable<String> fingerprints,
  });
}

class FirestoreInventoryFridgeItemStore implements InventoryFridgeItemStore {
  const FirestoreInventoryFridgeItemStore({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore,
       _onBeforeDeleteStaleDocuments = null;
  @visibleForTesting
  const FirestoreInventoryFridgeItemStore.testing({
    required FirebaseFirestore firestore,
    Future<void> Function()? onBeforeDeleteStaleDocuments,
  }) : _firestore = firestore,
       _onBeforeDeleteStaleDocuments = onBeforeDeleteStaleDocuments;

  final FirebaseFirestore _firestore;
  final Future<void> Function()? _onBeforeDeleteStaleDocuments;

  FirestoreAtomicReplaceService get _atomicReplaceService {
    return FirestoreAtomicReplaceService(firestore: _firestore);
  }

  @override
  Future<List<InventoryFridgeItemDocument>> readAll({
    required String userId,
  }) async {
    final snapshot = await _collection(userId).get();
    return _mapSnapshot(snapshot);
  }

  @override
  Stream<List<InventoryFridgeItemDocument>> watchAll({required String userId}) {
    return _collection(userId).snapshots().map(_mapSnapshot);
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _replaceAllUnsafe(userId: userId, documentsById: documentsById);
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to replace inventory items for user $userId',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> upsertAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _upsertAllUnsafe(userId: userId, documentsById: documentsById);
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to upsert inventory items for user $userId',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<Map<String, String>> readResolvedBarcodes({
    required String userId,
    required Iterable<String> fingerprints,
  }) async {
    final normalizedFingerprints = fingerprints
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedFingerprints.isEmpty) {
      return const <String, String>{};
    }

    final resolved = <String, String>{};
    for (final fingerprint in normalizedFingerprints) {
      final snapshot = await _requestDoc(
        userId: userId,
        fingerprint: fingerprint,
      ).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        continue;
      }

      final status = _readString(data['status']);
      if (status != 'resolved') {
        continue;
      }

      final barcode =
          _readString(data['resolved_barcode']) ??
          _readString(data['barcode']) ??
          _readString(data['provided_barcode']);
      if (barcode == null) {
        continue;
      }
      resolved[fingerprint] = barcode;
    }
    return resolved;
  }

  Future<void> _replaceAllUnsafe({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    final collection = _collection(userId);
    await _atomicReplaceService.replaceAll(
      collection: collection,
      documentsById: documentsById,
      onBeforeDeleteStaleDocuments: _onBeforeDeleteStaleDocuments,
    );
  }

  Future<void> _upsertAllUnsafe({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    final collection = _collection(userId);
    await _atomicReplaceService.upsertAll(
      collection: collection,
      documentsById: documentsById,
    );
  }

  List<InventoryFridgeItemDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(_toDocument).toList(growable: false);
  }

  InventoryFridgeItemDocument _toDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return InventoryFridgeItemDocument(
      id: document.id,
      data: Map<String, dynamic>.from(document.data()),
    );
  }

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_inventoryItemsCollection);
  }

  DocumentReference<Map<String, dynamic>> _requestDoc({
    required String userId,
    required String fingerprint,
  }) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_barcodeEnrichmentRequestsCollection)
        .doc(fingerprint);
  }

  String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}
