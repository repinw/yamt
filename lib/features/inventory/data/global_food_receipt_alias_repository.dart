import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';

import 'package:yamt/features/inventory/data/firestore_global_food_receipt_alias_repository.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_repository_contract.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_store.dart';

export 'firestore_global_food_receipt_alias_repository.dart';
export 'global_food_receipt_alias_repository_contract.dart';
export 'global_food_receipt_alias_store.dart';

/// The global food receipt alias repository provider.
final globalFoodReceiptAliasRepositoryProvider =
    Provider<GlobalFoodReceiptAliasRepository>((ref) {
      final store = _resolveStore();
      return FirestoreGlobalFoodReceiptAliasRepository(store: store);
    });

GlobalFoodReceiptAliasStore _resolveStore() {
  try {
    return FirestoreGlobalFoodReceiptAliasStore(
      firestore: FirebaseFirestore.instance,
    );
  } on Object catch (error, stackTrace) {
    log(
      'Falling back to unavailable global food receipt alias store.',
      name: 'GlobalFoodReceiptAliasRepositoryProvider',
      error: error,
      stackTrace: stackTrace,
    );
    return const _UnavailableGlobalFoodReceiptAliasStore();
  }
}

class _UnavailableGlobalFoodReceiptAliasStore
    implements GlobalFoodReceiptAliasStore {
  const _UnavailableGlobalFoodReceiptAliasStore();

  @override
  Future<List<GlobalFoodReceiptAliasDocument>> searchCandidates({
    required String normalizedStoreName,
    required String lookupKey,
    required String compactReceiptName,
    List<String> receiptSearchTokens = const <String>[],
    int limit = 5,
  }) async {
    return const <GlobalFoodReceiptAliasDocument>[];
  }

  @override
  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    return false;
  }
}
