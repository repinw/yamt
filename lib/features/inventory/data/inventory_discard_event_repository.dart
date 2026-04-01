import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';

const _discardEventRepositoryLogName = 'InventoryDiscardEventRepository';
const _usersCollection = 'users';
const _discardEventsCollection = 'inventory_discard_events';

abstract interface class InventoryDiscardEventRepository {
  Future<List<InventoryDiscardEvent>> readAll();

  Future<bool> saveEvent(InventoryDiscardEvent event);
}

class FirestoreInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
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
      log(
        'readAll(): reading discard events for user $userId',
        name: _discardEventRepositoryLogName,
      );
      final snapshot = await _collection(
        userId,
      ).orderBy('discarded_at', descending: true).get();
      final events = _decodeSnapshot(snapshot);
      log(
        'readAll(): decoded ${events.length} discard events for user $userId',
        name: _discardEventRepositoryLogName,
      );
      return events;
    } catch (error, stackTrace) {
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
      log(
        'saveEvent(): saving discard event ${event.id} '
        '(source=${event.sourceType.name}, sourceId=${event.sourceId}, '
        'reason=${event.reason.name})',
        name: _discardEventRepositoryLogName,
      );
      await _collection(userId).doc(event.id).set(event.toJson());
      log(
        'saveEvent(): saved discard event ${event.id}',
        name: _discardEventRepositoryLogName,
      );
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to save discard event ${event.id} for user $userId',
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
      } catch (error, stackTrace) {
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
}

final inventoryDiscardEventRepositoryProvider =
    Provider<InventoryDiscardEventRepository>((ref) {
      final authState = ref.watch(authStateChangesProvider);
      final currentUserId = authState.asData?.value?.uid;

      try {
        return FirestoreInventoryDiscardEventRepository(
          firestore: FirebaseFirestore.instance,
          currentUserId: currentUserId,
        );
      } catch (error, stackTrace) {
        log(
          'Falling back to unavailable discard event repository.',
          name: _discardEventRepositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
        return const _UnavailableInventoryDiscardEventRepository();
      }
    });
