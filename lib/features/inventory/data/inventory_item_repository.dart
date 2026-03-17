import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

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
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final store = _resolveStore();
  return FirestoreInventoryItemRepository(
    session: _CurrentInventoryUserSession(currentUserId: currentUserId),
    store: store,
  );
}

InventoryItemStore _resolveStore() {
  try {
    return FirestoreInventoryItemStore(firestore: FirebaseFirestore.instance);
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable inventory item store.',
      name: 'InventoryItemRepositoryProvider',
      error: error,
      stackTrace: stackTrace,
    );
    return const _UnavailableInventoryItemStore();
  }
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
