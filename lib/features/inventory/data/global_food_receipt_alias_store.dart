import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/features/inventory/data/global_catalog_created_by_field.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_store_values.dart';

const String _storeLogName = 'FirestoreGlobalFoodReceiptAliasStore';
const String _globalFoodReceiptAliasesCollection =
    'global_food_item_receipt_aliases';
const String _usersCollection = 'users';
const String _aliasVotesCollection = 'global_food_item_receipt_alias_votes';

/// Defines global food receipt alias document.
class GlobalFoodReceiptAliasDocument {
  /// The global food receipt alias document.
  const new({required this.id, required this.data});

  /// The id.
  final String id;

  /// The data.
  final Map<String, dynamic> data;
}

/// Defines global food receipt alias store.
abstract interface class GlobalFoodReceiptAliasStore {
  /// Search candidates.
  Future<List<GlobalFoodReceiptAliasDocument>> searchCandidates({
    required String normalizedStoreName,
    required String lookupKey,
    required String compactReceiptName,
    List<String> receiptSearchTokens = const <String>[],
    int limit = 5,
  });

  /// Records that the current user saved each alias: creates missing
  /// aliases and adds the user's vote (one per user and alias).
  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  });

  /// Ids of the aliases with [lookupKey] that the current user saved before.
  Future<Set<String>> readOwnAliasIds({required String lookupKey});

  /// The signed-in user, if any.
  String? get currentUserId;
}

/// Defines firestore global food receipt alias store.
class FirestoreGlobalFoodReceiptAliasStore
    implements GlobalFoodReceiptAliasStore {
  /// The firestore global food receipt alias store.
  const new({required this._firestore, required this._currentUserId});

  final FirebaseFirestore _firestore;

  /// The author of new aliases.
  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;

  @override
  Future<Set<String>> readOwnAliasIds({required String lookupKey}) async {
    final userId = _currentUserId?.trim();
    final safeLookupKey = lookupKey.trim();
    if (userId == null || userId.isEmpty || safeLookupKey.isEmpty) {
      return const <String>{};
    }
    try {
      final snapshot = await _voteCollection(userId)
          .where('lookup_key', isEqualTo: safeLookupKey)
          .get();
      return snapshot.docs.map((document) => document.id).toSet();
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read own receipt alias votes.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <String>{};
    }
  }

  @override
  Future<List<GlobalFoodReceiptAliasDocument>> searchCandidates({
    required String normalizedStoreName,
    required String lookupKey,
    required String compactReceiptName,
    List<String> receiptSearchTokens = const <String>[],
    int limit = 5,
  }) async {
    final safeStoreName = normalizedStoreName.trim();
    final safeLookupKey = lookupKey.trim();
    final safeCompactReceiptName = compactReceiptName.trim();
    final safeReceiptSearchTokens = normalizeReceiptAliasQueryTokens(
      receiptSearchTokens,
    );
    if (safeStoreName.isEmpty ||
        (safeLookupKey.isEmpty &&
            safeCompactReceiptName.isEmpty &&
            safeReceiptSearchTokens.isEmpty)) {
      return const <GlobalFoodReceiptAliasDocument>[];
    }

    final safeLimit = limit < 1 ? 1 : limit;
    final queries = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    if (safeLookupKey.isNotEmpty) {
      queries.add(
        _collection()
            .where('lookup_key', isEqualTo: safeLookupKey)
            .limit(safeLimit)
            .get(),
      );
    }
    if (safeCompactReceiptName.isNotEmpty) {
      queries.add(
        _collection()
            .where('normalized_store_name', isEqualTo: safeStoreName)
            .where('compact_receipt_name', isEqualTo: safeCompactReceiptName)
            .limit(safeLimit)
            .get(),
      );
    }
    if (safeReceiptSearchTokens.isNotEmpty) {
      queries.add(
        _collection()
            .where('normalized_store_name', isEqualTo: safeStoreName)
            .where(
              'receipt_search_tokens',
              arrayContainsAny: safeReceiptSearchTokens,
            )
            .limit(safeLimit)
            .get(),
      );
    }

    final snapshots = await Future.wait(queries);
    final documentsById = <String, GlobalFoodReceiptAliasDocument>{};
    for (final snapshot in snapshots) {
      for (final document in _mapSnapshot(snapshot)) {
        documentsById[document.id] = document;
      }
    }
    return documentsById.values.toList(growable: false);
  }

  @override
  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _createMissingDocuments(documentsById);
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to upsert global food receipt aliases.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> _collection() {
    return _firestore.collection(_globalFoodReceiptAliasesCollection);
  }

  CollectionReference<Map<String, dynamic>> _voteCollection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_aliasVotesCollection);
  }

  Future<void> _createMissingDocuments(
    Map<String, Map<String, dynamic>> documentsById,
  ) async {
    final userId = _currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Saving receipt aliases needs a signed-in user.');
    }
    final entries = documentsById.entries.toList(growable: false);
    for (final chunk in chunkReceiptAliasEntries(entries)) {
      await _firestore.runTransaction((transaction) async {
        final aliasSnapshots =
            <String, DocumentSnapshot<Map<String, dynamic>>>{};
        final voteSnapshots =
            <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final entry in chunk) {
          aliasSnapshots[entry.key] = await transaction.get(
            _collection().doc(entry.key),
          );
          voteSnapshots[entry.key] = await transaction.get(
            _voteCollection(userId).doc(entry.key),
          );
        }

        for (final entry in chunk) {
          final aliasRef = _collection().doc(entry.key);
          final aliasSnapshot = aliasSnapshots[entry.key]!;
          final voteSnapshot = voteSnapshots[entry.key]!;
          final updatedAt = entry.value['updated_at'];
          if (!aliasSnapshot.exists) {
            transaction.set(aliasRef, <String, dynamic>{
              ...entry.value,
              'selection_count': 1,
              'unique_user_count': 1,
              ...globalCatalogCreatedBy(userId),
            });
          } else {
            final currentData =
                aliasSnapshot.data() ?? const <String, dynamic>{};
            // Older aliases have no user count and no votes; their author
            // counts as their one user.
            final currentUserCount = readReceiptAliasCount(
              currentData['unique_user_count'],
            );
            final alreadyCounted =
                voteSnapshot.exists ||
                currentData[globalCatalogCreatedByField] == userId;
            // Only the counters and the time: the rules keep a saved
            // alias's product and text fixed.
            transaction.update(aliasRef, <String, dynamic>{
              'selection_count':
                  readReceiptAliasCount(currentData['selection_count']) + 1,
              'unique_user_count': currentUserCount + (alreadyCounted ? 0 : 1),
              'updated_at': updatedAt,
            });
          }
          transaction.set(
            _voteCollection(userId).doc(entry.key),
            <String, dynamic>{
              'alias_id': entry.key,
              'lookup_key': entry.value['lookup_key'],
              'global_food_item_id': entry.value['global_food_item_id'],
              'created_at':
                  voteSnapshot.data()?['created_at'] ??
                  entry.value['created_at'],
              'updated_at': updatedAt,
            },
          );
        }
      });
    }
  }

  List<GlobalFoodReceiptAliasDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => GlobalFoodReceiptAliasDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }
}
