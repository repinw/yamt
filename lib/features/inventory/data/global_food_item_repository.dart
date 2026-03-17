import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'firestore_global_food_item_repository.dart';
import 'global_food_item_repository_contract.dart';
import 'global_food_item_store.dart';

export 'firestore_global_food_item_repository.dart';
export 'global_food_item_repository_contract.dart';
export 'global_food_item_store.dart';

part 'global_food_item_repository.g.dart';

@riverpod
GlobalFoodItemRepository globalFoodItemRepository(Ref ref) {
  final store = _resolveStore();
  return FirestoreGlobalFoodItemRepository(store: store);
}

GlobalFoodItemStore _resolveStore() {
  try {
    return FirestoreGlobalFoodItemStore(firestore: FirebaseFirestore.instance);
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable global food item store.',
      name: 'GlobalFoodItemRepositoryProvider',
      error: error,
      stackTrace: stackTrace,
    );
    return const _UnavailableGlobalFoodItemStore();
  }
}

class _UnavailableGlobalFoodItemStore implements GlobalFoodItemStore {
  const _UnavailableGlobalFoodItemStore();

  @override
  Future<List<GlobalFoodItemDocument>> readAll() async {
    return const <GlobalFoodItemDocument>[];
  }

  @override
  Future<List<GlobalFoodItemDocument>> searchCandidates({
    String? normalizedName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    return const <GlobalFoodItemDocument>[];
  }

  @override
  Stream<List<GlobalFoodItemDocument>> watchAll() {
    return const Stream<List<GlobalFoodItemDocument>>.empty();
  }

  @override
  Future<bool> replaceAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    return false;
  }

  @override
  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    return false;
  }
}
