import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';

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

/// Defines firestore inventory discard event repository.
class FirestoreInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  /// Creates an instance.
  FirestoreInventoryDiscardEventRepository({
    required FirebaseFirestore firestore,
    required String? currentUserId,
  }) : _firestore = firestore,
       _currentUserId = currentUserId;

  final FirebaseFirestore _firestore;
  final String? _currentUserId;

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    final userId = _resolvedUserId();
    if (userId == null) {
      return const <InventoryDiscardEvent>[];
    }

    try {
      final snapshot = await _collection(
        userId,
      ).orderBy('discarded_at', descending: true).get();
      return _decodeSnapshot(snapshot);
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
      await _collection(userId).doc(event.id).set(event.toJson());
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
      await _collection(userId).doc(normalizedEventId).delete();
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

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_discardEventsCollection);
  }

  List<InventoryDiscardEvent> _decodeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final events = <InventoryDiscardEvent>[];
    for (final document in snapshot.docs) {
      try {
        final rawData = document.data();
        final normalizedData = _normalizeFirestoreJson(rawData);
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

  Map<String, dynamic> _normalizeFirestoreJson(Map<String, dynamic> rawData) {
    return rawData.map(
      (key, value) =>
          MapEntry<String, dynamic>(key, _normalizeFirestoreValue(value)),
    );
  }

  dynamic _normalizeFirestoreValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry<String, dynamic>(
          key.toString(),
          _normalizeFirestoreValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value
          .map<dynamic>(_normalizeFirestoreValue)
          .toList(growable: false);
    }
    return value;
  }
}

class _UnavailableInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  const _UnavailableInventoryDiscardEventRepository();

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
final inventoryDiscardEventRepositoryProvider =
    Provider<InventoryDiscardEventRepository>((ref) {
      ref.watch(authStateChangesProvider);
      final currentUserId = ref.watch(
        effectiveHouseholdDataOwnerUserIdProvider,
      );
      final firestore = ref.watch(firebaseFirestoreProvider);
      if (firestore == null) {
        log(
          'Falling back to unavailable discard event repository.',
          name: _discardEventRepositoryLogName,
        );
        return const _UnavailableInventoryDiscardEventRepository();
      }

      return FirestoreInventoryDiscardEventRepository(
        firestore: firestore,
        currentUserId: currentUserId,
      );
    });
