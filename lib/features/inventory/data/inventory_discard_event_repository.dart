import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';

part 'inventory_discard_event_repository.g.dart';

const _discardEventRepositoryLogName = 'InventoryDiscardEventRepository';
const _usersCollection = 'users';
const _discardEventsCollection = 'inventory_discard_events';

/// Defines inventory discard event repository.
abstract interface class InventoryDiscardEventRepository {
  /// Read all.
  Future<List<InventoryDiscardEvent>> readAll();

  /// Save event.
  Future<bool> saveEvent(InventoryDiscardEvent event);

  /// Delete event.
  Future<bool> deleteEvent(String eventId);
}

/// Stores discard events encrypted with the household key [_cipher].
class FirestoreInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  /// Creates an instance.
  new({
    required this._firestore,
    required this._cipher,
    required this._currentUserId,
  });

  final FirebaseFirestore _firestore;
  final PayloadCipher _cipher;
  final String? _currentUserId;

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    final userId = _resolvedUserId();
    if (userId == null) {
      return const <InventoryDiscardEvent>[];
    }

    try {
      final collection = _collection(userId);
      final snapshot = await collection.reference
          .orderBy('discarded_at', descending: true)
          .get();
      return _decodeDocuments(await collection.openAll(snapshot));
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read discard events for user $userId',
        name: _discardEventRepositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <InventoryDiscardEvent>[];
    }
  }

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async {
    final userId = _resolvedUserId();
    if (userId == null) {
      return false;
    }

    try {
      final collection = _collection(userId);
      await collection.reference
          .doc(event.id)
          .set(await collection.seal(event.id, event.toJson()));
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save discard event ${event.id} for user $userId',
        name: _discardEventRepositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    final userId = _resolvedUserId();
    final normalizedEventId = eventId.trim();
    if (userId == null || normalizedEventId.isEmpty) {
      return false;
    }

    try {
      await _collection(userId).reference.doc(normalizedEventId).delete();
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete discard event $normalizedEventId for user $userId',
        name: _discardEventRepositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  String? _resolvedUserId() {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  SealedCollection _collection(String userId) {
    return SealedCollection(
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_discardEventsCollection),
      cipher: _cipher,
      plaintextFields: inventoryDiscardEventPlaintextFields,
    );
  }

  List<InventoryDiscardEvent> _decodeDocuments(List<OpenedDocument> documents) {
    final events = <InventoryDiscardEvent>[];
    for (final document in documents) {
      try {
        final normalizedData = normalizeFirestoreJson(document.data);
        normalizedData['id'] = normalizedData['id'] ?? document.id;
        events.add(InventoryDiscardEvent.fromJson(normalizedData));
      } on Object catch (error, stackTrace) {
        log(
          'Skipping malformed discard event ${document.id}',
          name: _discardEventRepositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return events;
  }
}

class _UnavailableInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  const new();

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    return const <InventoryDiscardEvent>[];
  }

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async {
    return false;
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    return false;
  }
}

/// The inventory discard event repository provider.
@riverpod
InventoryDiscardEventRepository inventoryDiscardEventRepository(Ref ref) {
  ref.watch(authStateChangesProvider);
  final householdCipher = ref.watch(householdCipherProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || householdCipher == null) {
    log(
      'Falling back to unavailable discard event repository.',
      name: _discardEventRepositoryLogName,
    );
    return const _UnavailableInventoryDiscardEventRepository();
  }

  return FirestoreInventoryDiscardEventRepository(
    firestore: firestore,
    cipher: householdCipher.cipher,
    currentUserId: householdCipher.ownerUid,
  );
}
