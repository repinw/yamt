import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';

part 'inventory_discard_event_repository.g.dart';

const _discardEventRepositoryLogName = 'InventoryDiscardEventRepository';
const _householdsCollection = 'households';
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

/// Stores discard events encrypted with the household key.
class FirestoreInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  /// Creates an instance.
  new({required this._household});

  /// The active household, or `null` without a household key.
  final HouseholdDataScope? _household;

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    final householdId = _resolvedHouseholdId();
    if (householdId == null) {
      return const <InventoryDiscardEvent>[];
    }

    try {
      final collection = _collection(householdId);
      final snapshot = await collection.reference
          .orderBy('discarded_at', descending: true)
          .get();
      return _decodeDocuments(await collection.openAll(snapshot));
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read discard events for household $householdId',
        name: _discardEventRepositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <InventoryDiscardEvent>[];
    }
  }

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async {
    final householdId = _resolvedHouseholdId();
    if (householdId == null) {
      return false;
    }

    try {
      final collection = _collection(householdId);
      await collection.reference
          .doc(event.id)
          .set(await collection.seal(event.id, event.toJson()));
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save discard event ${event.id} for household $householdId',
        name: _discardEventRepositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    final householdId = _resolvedHouseholdId();
    final normalizedEventId = eventId.trim();
    if (householdId == null || normalizedEventId.isEmpty) {
      return false;
    }

    try {
      await _collection(householdId).reference.doc(normalizedEventId).delete();
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete discard event $normalizedEventId for '
        'household $householdId',
        name: _discardEventRepositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  String? _resolvedHouseholdId() {
    final householdId = _household?.householdId;
    if (householdId == null || householdId.isEmpty) {
      return null;
    }
    return householdId;
  }

  SealedCollection _collection(String householdId) {
    final household = _household!;
    return SealedCollection(
      household.firestore
          .collection(_householdsCollection)
          .doc(householdId)
          .collection(_discardEventsCollection),
      cipher: household.cipher,
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

/// The inventory discard event repository provider.
@riverpod
InventoryDiscardEventRepository inventoryDiscardEventRepository(Ref ref) {
  return FirestoreInventoryDiscardEventRepository(
    household: ref.watch(householdDataScopeProvider),
  );
}
