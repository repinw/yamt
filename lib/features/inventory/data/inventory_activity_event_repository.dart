import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';

part 'inventory_activity_event_repository.g.dart';

const _activityLogName = 'InventoryActivityEventRepository';
const _usersCollection = 'users';
const _activityEventsCollection = 'inventory_activity_events';
const _defaultRecentLimit = 100;

/// Inventory activity event repository.
abstract interface class InventoryActivityEventRepository {
  /// Watch recent events.
  Stream<List<InventoryActivityEvent>> watchRecent({int limit});

  /// Append all events.
  Future<bool> appendAll(List<InventoryActivityEvent> events);
}

/// Firestore inventory activity event repository.
class FirestoreInventoryActivityEventRepository
    implements InventoryActivityEventRepository {
  /// Creates repository.
  const FirestoreInventoryActivityEventRepository({
    required FirebaseFirestore firestore,
    required String? currentUserId,
  }) : _firestore = firestore,
       _currentUserId = currentUserId;

  final FirebaseFirestore _firestore;
  final String? _currentUserId;

  @override
  Stream<List<InventoryActivityEvent>> watchRecent({
    int limit = _defaultRecentLimit,
  }) {
    final userId = _resolvedUserId();
    if (userId == null || limit < 1) {
      return Stream<List<InventoryActivityEvent>>.value(
        const <InventoryActivityEvent>[],
      );
    }

    return _collection(userId)
        .orderBy('happened_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(_decodeSnapshot);
  }

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async {
    final userId = _resolvedUserId();
    if (userId == null || events.isEmpty) {
      return events.isEmpty;
    }

    try {
      final batch = _firestore.batch();
      final collection = _collection(userId);
      for (final event in events) {
        batch.set(collection.doc(event.id), event.toJson());
      }
      await batch.commit();
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to append inventory activity events for user $userId.',
        name: _activityLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  String? _resolvedUserId() {
    final userId = _currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_activityEventsCollection);
  }

  List<InventoryActivityEvent> _decodeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final events = <InventoryActivityEvent>[];
    for (final document in snapshot.docs) {
      try {
        final data = normalizeFirestoreJson(document.data());
        data['id'] = data['id'] ?? document.id;
        events.add(InventoryActivityEvent.fromJson(data));
      } on Object catch (error, stackTrace) {
        log(
          'Skipping malformed inventory activity event ${document.id}.',
          name: _activityLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return events;
  }
}

class _UnavailableInventoryActivityEventRepository
    implements InventoryActivityEventRepository {
  const _UnavailableInventoryActivityEventRepository();

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async {
    return true;
  }

  @override
  Stream<List<InventoryActivityEvent>> watchRecent({
    int limit = _defaultRecentLimit,
  }) {
    return Stream<List<InventoryActivityEvent>>.value(
      const <InventoryActivityEvent>[],
    );
  }
}

/// Inventory activity event repository provider.
@Riverpod(dependencies: [])
InventoryActivityEventRepository inventoryActivityEventRepository(Ref ref) {
  ref.watch(authStateChangesProvider);
  final currentUserId = ref.watch(effectiveHouseholdDataOwnerUserIdProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    log(
      'Falling back to unavailable inventory activity event repository.',
      name: _activityLogName,
    );
    return const _UnavailableInventoryActivityEventRepository();
  }

  return FirestoreInventoryActivityEventRepository(
    firestore: firestore,
    currentUserId: currentUserId,
  );
}

/// Current inventory activity actor.
@riverpod
InventoryActivityActor? inventoryActivityActor(Ref ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) {
    return null;
  }

  final profile = ref.watch(userProfileProvider).asData?.value;
  final displayName = _firstNonEmpty(
    profile?.displayName,
    user.displayName,
    profile?.email,
    user.email,
  );
  return InventoryActivityActor(
    userId: user.uid,
    displayName: displayName,
  );
}

/// Recent inventory activity events.
@Riverpod(dependencies: [inventoryActivityEventRepository])
Stream<List<InventoryActivityEvent>> inventoryActivityEvents(Ref ref) {
  return ref.watch(inventoryActivityEventRepositoryProvider).watchRecent();
}

String? _firstNonEmpty(
  String? first,
  String? second,
  String? third,
  String? fourth,
) {
  for (final value in <String?>[first, second, third, fourth]) {
    final normalized = value?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}
