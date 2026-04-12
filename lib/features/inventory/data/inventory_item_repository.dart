import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';

import 'firestore_inventory_item_repository.dart';
import 'inventory_item_repository_contract.dart';
import 'inventory_item_store.dart';
import 'inventory_user_session.dart';

export 'firestore_inventory_item_repository.dart';
export 'inventory_item_repository_contract.dart';
export 'inventory_item_store.dart';
export 'inventory_user_session.dart';

part 'inventory_item_repository.g.dart';

@riverpod
InventoryItemRepository inventoryItemRepository(Ref ref) {
  ref.watch(authStateChangesProvider);
  final currentUserId = ref.watch(effectiveHouseholdDataOwnerUserIdProvider);
  final store = _resolveStore(ref);
  return FirestoreInventoryItemRepository(
    session: _CurrentInventoryUserSession(currentUserId: currentUserId),
    sessionShutdownSignal: ref.watch(sessionShutdownSignalProvider),
    store: store,
  );
}

InventoryItemStore _resolveStore(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    log(
      'Falling back to unavailable inventory item store.',
      name: 'InventoryItemRepositoryProvider',
    );
    return const _UnavailableInventoryItemStore();
  }
  return FirestoreInventoryItemStore(firestore: firestore);
}

class _CurrentInventoryUserSession implements InventoryUserSession {
  const _CurrentInventoryUserSession({required String? currentUserId})
    : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

class _UnavailableInventoryItemStore implements InventoryItemStore {
  const _UnavailableInventoryItemStore();

  @override
  Future<List<InventoryItemDocument>> readAll({required String userId}) async {
    return const <InventoryItemDocument>[];
  }

  @override
  Stream<List<InventoryItemDocument>> watchAll({required String userId}) {
    return const Stream<List<InventoryItemDocument>>.empty();
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    return false;
  }

  @override
  Future<bool> upsertAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    return false;
  }
}
