import 'dart:developer' show log;

import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_repository_contract.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_store.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';

const String _repositoryLogName = 'FirestoreGlobalFoodReceiptAliasRepository';

/// Defines firestore global food receipt alias repository.
class FirestoreGlobalFoodReceiptAliasRepository
    implements GlobalFoodReceiptAliasRepository {
  /// Creates an instance.
  FirestoreGlobalFoodReceiptAliasRepository({
    required GlobalFoodReceiptAliasStore store,
  }) : _store = store;

  final GlobalFoodReceiptAliasStore _store;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  Future<List<GlobalFoodReceiptAlias>> searchCandidates({
    required String normalizedStoreName,
    required String normalizedReceiptName,
    int limit = 5,
  }) async {
    if (normalizedStoreName.trim().isEmpty ||
        normalizedReceiptName.trim().isEmpty) {
      return const <GlobalFoodReceiptAlias>[];
    }

    try {
      final receiptSearchTokens = buildGlobalFoodReceiptAliasSearchTokens(
        normalizedReceiptName,
      );
      final documents = await _store.searchCandidates(
        normalizedStoreName: normalizedStoreName,
        lookupKey: buildGlobalFoodReceiptAliasLookupKey(
          normalizedStoreName: normalizedStoreName,
          normalizedReceiptName: normalizedReceiptName,
        ),
        compactReceiptName: compactGlobalFoodReceiptAliasText(
          normalizedReceiptName,
        ),
        receiptSearchTokens: receiptSearchTokens,
        limit: limit,
      );
      return _decodeDocuments(documents);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to search global food receipt aliases.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <GlobalFoodReceiptAlias>[];
    }
  }

  @override
  Future<bool> appendAll(List<GlobalFoodReceiptAlias> aliases) {
    if (aliases.isEmpty) {
      return Future<bool>.value(true);
    }

    return _runExclusiveWrite(() {
      final documentsById = <String, Map<String, dynamic>>{
        for (final alias in aliases) alias.id: _normalizeAlias(alias).toJson(),
      };
      return _store.upsertAll(documentsById: documentsById);
    });
  }

  List<GlobalFoodReceiptAlias> _decodeDocuments(
    List<GlobalFoodReceiptAliasDocument> documents,
  ) {
    final aliases = <GlobalFoodReceiptAlias>[];
    for (var index = 0; index < documents.length; index++) {
      final json = Map<String, dynamic>.from(documents[index].data);
      if ((json['id'] as String?)?.trim().isEmpty ?? true) {
        json['id'] = documents[index].id;
      }
      try {
        aliases.add(_normalizeAlias(GlobalFoodReceiptAlias.fromJson(json)));
      } on Object catch (error, stackTrace) {
        log(
          'Skipping corrupted global food receipt alias at index $index.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    aliases.sort((left, right) {
      final byCount = right.selectionCount.compareTo(left.selectionCount);
      if (byCount != 0) {
        return byCount;
      }
      return right.updatedAt.compareTo(left.updatedAt);
    });
    return aliases;
  }

  GlobalFoodReceiptAlias _normalizeAlias(GlobalFoodReceiptAlias alias) {
    final storeName = normalizeStoreName(alias.storeName) ?? alias.storeName;
    final normalizedStoreName =
        normalizeGlobalFoodReceiptAliasStoreName(storeName) ??
        alias.normalizedStoreName;
    final receiptName = alias.receiptName.trim();
    final normalizedReceiptName =
        normalizeGlobalFoodReceiptObservedName(receiptName) ??
        alias.normalizedReceiptName;
    final globalFoodItem = alias.globalFoodItem.copyWith(
      id: alias.globalFoodItemId.trim(),
    );
    return alias.copyWith(
      id: buildGlobalFoodReceiptAliasId(
        normalizedStoreName: normalizedStoreName,
        normalizedReceiptName: normalizedReceiptName,
        globalFoodItemId: alias.globalFoodItemId,
      ),
      storeName: storeName,
      normalizedStoreName: normalizedStoreName,
      receiptName: receiptName,
      normalizedReceiptName: normalizedReceiptName,
      compactReceiptName: compactGlobalFoodReceiptAliasText(
        normalizedReceiptName,
      ),
      receiptSearchTokens: buildGlobalFoodReceiptAliasSearchTokens(receiptName),
      lookupKey: buildGlobalFoodReceiptAliasLookupKey(
        normalizedStoreName: normalizedStoreName,
        normalizedReceiptName: normalizedReceiptName,
      ),
      selectionCount: alias.selectionCount < 1 ? 1 : alias.selectionCount,
      globalFoodItem: globalFoodItem,
    );
  }

  Future<T> _runExclusiveWrite<T>(Future<T> Function() operation) {
    final queuedOperation = _writeBarrier.then((_) => operation());
    _writeBarrier = queuedOperation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return queuedOperation;
  }
}
