import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';

part 'inventory_activity_event_repository.g.dart';

const _activityLogName = 'InventoryActivityEventRepository';
const _usersCollection = 'users';
const _activityEventsCollection = 'inventory_activity_events';
const _defaultRecentLimit = 100;
const _firestoreBatchWriteLimit = 500;

/// Inventory activity event repository.
abstract interface class InventoryActivityEventRepository {
  /// Watch recent events.
  Stream<List<InventoryActivityEvent>> watchRecent({int limit});

  /// Append all events.
  Future<bool> appendAll(List<InventoryActivityEvent> events);
}

/// Stores inventory activity events encrypted with the household key
/// [_cipher].
class FirestoreInventoryActivityEventRepository
    implements InventoryActivityEventRepository {
  /// Creates repository.
  const new({
    required this._firestore,
    required this._cipher,
    required this._currentUserId,
  });

  final FirebaseFirestore _firestore;
  final PayloadCipher _cipher;
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

    final collection = _collection(userId);
    return collection.reference
        .orderBy('happened_at', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap(
          (snapshot) async =>
              _decodeDocuments(await collection.openAll(snapshot)),
        );
  }

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async {
    final userId = _resolvedUserId();
    if (userId == null || events.isEmpty) {
      return events.isEmpty;
    }

    try {
      final collection = _collection(userId);
      final sealedById = await collection.sealAll(
        <String, Map<String, dynamic>>{
          for (final event in events) event.id: event.toJson(),
        },
      );
      for (
        var start = 0;
        start < events.length;
        start += _firestoreBatchWriteLimit
      ) {
        final batch = _firestore.batch();
        final end = _chunkEnd(start: start, itemCount: events.length);
        for (var index = start; index < end; index += 1) {
          final event = events[index];
          batch.set(collection.reference.doc(event.id), sealedById[event.id]!);
        }
        commitBatchInBackground(
          batch,
          failureMessage:
              'Server rejected inventory activity events for user $userId.',
          logName: _activityLogName,
        );
      }
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

  SealedCollection _collection(String userId) {
    return SealedCollection(
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_activityEventsCollection),
      cipher: _cipher,
      plaintextFields: inventoryActivityEventPlaintextFields,
    );
  }

  List<InventoryActivityEvent> _decodeDocuments(
    List<OpenedDocument> documents,
  ) {
    final events = <InventoryActivityEvent>[];
    for (final document in documents) {
      try {
        final data = normalizeFirestoreJson(document.data);
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

int _chunkEnd({required int start, required int itemCount}) {
  final cappedEnd = start + _firestoreBatchWriteLimit;
  if (cappedEnd > itemCount) {
    return itemCount;
  }
  return cappedEnd;
}

class _UnavailableInventoryActivityEventRepository
    implements InventoryActivityEventRepository {
  const new();

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
@riverpod
InventoryActivityEventRepository inventoryActivityEventRepository(Ref ref) {
  ref.watch(authStateChangesProvider);
  final householdCipher = ref.watch(householdCipherProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || householdCipher == null) {
    log(
      'Falling back to unavailable inventory activity event repository.',
      name: _activityLogName,
    );
    return const _UnavailableInventoryActivityEventRepository();
  }

  return FirestoreInventoryActivityEventRepository(
    firestore: firestore,
    cipher: householdCipher.cipher,
    currentUserId: householdCipher.ownerUid,
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
  return InventoryActivityActor(userId: user.uid, displayName: displayName);
}

/// Recent inventory activity events.
@riverpod
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
