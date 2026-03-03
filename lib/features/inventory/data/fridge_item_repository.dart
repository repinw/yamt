import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'firestore_fridge_item_repository.dart';
import 'fridge_item_repository_contract.dart';
import 'inventory_fridge_item_store.dart';
import 'inventory_user_session.dart';

export 'firestore_fridge_item_repository.dart';
export 'fridge_item_repository_contract.dart';
export 'inventory_fridge_item_store.dart';
export 'inventory_user_session.dart';

part 'fridge_item_repository.g.dart';

@riverpod
FridgeItemRepository fridgeItemRepository(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final store = _resolveStore();
  return FirestoreFridgeItemRepository(
    session: _CurrentInventoryUserSession(currentUserId: currentUserId),
    store: store,
  );
}

InventoryFridgeItemStore _resolveStore() {
  try {
    return FirestoreInventoryFridgeItemStore(
      firestore: FirebaseFirestore.instance,
    );
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable inventory store.',
      name: 'FridgeItemRepositoryProvider',
      error: error,
      stackTrace: stackTrace,
    );
    return const _UnavailableInventoryFridgeItemStore();
  }
}

class _CurrentInventoryUserSession implements InventoryUserSession {
  const _CurrentInventoryUserSession({required String? currentUserId})
    : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

class _UnavailableInventoryFridgeItemStore implements InventoryFridgeItemStore {
  const _UnavailableInventoryFridgeItemStore();

  @override
  Future<List<InventoryFridgeItemDocument>> readAll({
    required String userId,
  }) async {
    return const <InventoryFridgeItemDocument>[];
  }

  @override
  Stream<List<InventoryFridgeItemDocument>> watchAll({required String userId}) {
    return const Stream<List<InventoryFridgeItemDocument>>.empty();
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

  @override
  Future<Map<String, String>> readResolvedBarcodes({
    required String userId,
    required Iterable<String> fingerprints,
  }) async {
    return const <String, String>{};
  }
}
