import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_key_session.dart';

import 'package:yamt/features/inventory/data/'
    'firestore_inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_store.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';

export 'firestore_inventory_item_repository.dart';
export 'inventory_item_repository_contract.dart';
export 'inventory_item_store.dart';
export 'inventory_user_session.dart';

part 'inventory_item_repository.g.dart';

/// Inventory item repository.
@riverpod
InventoryItemRepository inventoryItemRepository(Ref ref) {
  ref.watch(authStateChangesProvider);
  final householdCipher = ref.watch(householdCipherProvider);
  final store = _resolveStore(ref, householdCipher);
  return FirestoreInventoryItemRepository(
    session: _CurrentInventoryUserSession(
      householdId: householdCipher?.householdId,
    ),
    sessionShutdownSignal: ref.watch(sessionShutdownSignalProvider),
    store: store,
  );
}

InventoryItemStore _resolveStore(Ref ref, HouseholdCipher? householdCipher) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || householdCipher == null) {
    log(
      'Falling back to unavailable inventory item store.',
      name: 'InventoryItemRepositoryProvider',
    );
    return const _UnavailableInventoryItemStore();
  }
  return FirestoreInventoryItemStore(
    firestore: firestore,
    cipher: householdCipher.cipher,
  );
}

class _CurrentInventoryUserSession implements InventoryUserSession {
  const new({required this._householdId});

  final String? _householdId;

  @override
  String? get householdId => _householdId;
}

class _UnavailableInventoryItemStore
    implements InventoryItemStore, InventoryItemRecentManualStore {
  const new();

  @override
  bool get supportsLimitedRecentManualQuery => true;

  @override
  Future<List<InventoryItemDocument>> readAll({
    required String householdId,
  }) async {
    return const <InventoryItemDocument>[];
  }

  @override
  Future<List<InventoryItemDocument>> readRecentManual({
    required String householdId,
    required int limit,
  }) async {
    return const <InventoryItemDocument>[];
  }

  @override
  Stream<List<InventoryItemDocument>> watchAll({required String householdId}) {
    return const Stream<List<InventoryItemDocument>>.empty();
  }

  @override
  Future<bool> replaceAll({
    required String householdId,
    required Map<String, Map<String, dynamic>> documentsById,
    required void Function(String id, Map<String, dynamic> data) parse,
  }) async {
    return false;
  }

  @override
  Future<bool> upsertAll({
    required String householdId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    return false;
  }
}
