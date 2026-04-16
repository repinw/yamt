import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion_repository_contract.dart';
import 'package:yamt/features/inventory/domain/inventory_parsing_utils.dart';

const String _repositoryLogName =
    'FirestoreGlobalFoodServingSuggestionRepository';
const String _globalSuggestionsCollection = 'global_food_item_serving_sizes';
const String _prefsCollection = 'global_food_item_serving_prefs';
const String _votesCollection = 'global_food_item_serving_votes';

/// Defines firestore global food serving suggestion repository.
class FirestoreGlobalFoodServingSuggestionRepository
    implements GlobalFoodServingSuggestionRepository {
  /// The firestore global food serving suggestion repository.
  const FirestoreGlobalFoodServingSuggestionRepository({
    required FirebaseFirestore firestore,
    required String? currentUserId,
  }) : _firestore = firestore,
       _currentUserId = currentUserId;

  final FirebaseFirestore _firestore;
  final String? _currentUserId;

  @override
  Future<GlobalFoodServingSuggestionSet> readSuggestions({
    required String foodFingerprint,
    String? globalFoodItemId,
    int limit = 5,
  }) async {
    final fingerprintKey = buildFingerprintServingItemKey(foodFingerprint);
    final globalKey = buildGlobalServingItemKey(globalFoodItemId);
    if (fingerprintKey == null && globalKey == null) {
      return const GlobalFoodServingSuggestionSet.empty();
    }

    try {
      final safeLimit = limit < 1 ? 1 : limit;
      final personalFuture = _readPersonalSuggestion(
        fingerprintKey: fingerprintKey,
        globalKey: globalKey,
      );
      final globalFuture = globalKey == null
          ? Future<List<GlobalFoodServingSuggestion>>.value(
              const <GlobalFoodServingSuggestion>[],
            )
          : _readGlobalSuggestions(itemKey: globalKey, limit: safeLimit);
      final results = await Future.wait<Object?>(<Future<Object?>>[
        personalFuture,
        globalFuture,
      ]);

      return GlobalFoodServingSuggestionSet(
        personalSuggestion: results[0] as ServingSizeSuggestion?,
        globalSuggestions: results[1]! as List<GlobalFoodServingSuggestion>,
      );
    } catch (error, stackTrace) {
      log(
        'Failed to read serving suggestions.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const GlobalFoodServingSuggestionSet.empty();
    }
  }

  @override
  Future<void> recordSelection({
    required String foodFingerprint,
    required double amount, required ConsumedUnit unit, required DateTime selectedAt, String? globalFoodItemId,
  }) async {
    final currentUserId = _currentUserId?.trim();
    if (currentUserId == null || currentUserId.isEmpty || amount <= 0) {
      return;
    }

    final normalizedAmount = normalizeServingSuggestionAmount(amount);
    if (normalizedAmount <= 0) {
      return;
    }

    final fingerprintKey = buildFingerprintServingItemKey(foodFingerprint);
    final globalKey = buildGlobalServingItemKey(globalFoodItemId);
    if (fingerprintKey == null && globalKey == null) {
      return;
    }

    final nowText = selectedAt.toIso8601String();
    final preferenceDocuments =
        <DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>{
          if (fingerprintKey != null)
            _userDocument(
              userId: currentUserId,
              collectionName: _prefsCollection,
              documentId: fingerprintKey,
            ): _buildPreferenceData(
              itemKey: fingerprintKey,
              globalFoodItemId: globalKey == null ? null : globalFoodItemId,
              foodFingerprint: foodFingerprint,
              amount: normalizedAmount,
              unit: unit,
              updatedAtText: nowText,
            ),
          if (globalKey != null)
            _userDocument(
              userId: currentUserId,
              collectionName: _prefsCollection,
              documentId: globalKey,
            ): _buildPreferenceData(
              itemKey: globalKey,
              globalFoodItemId: globalFoodItemId,
              foodFingerprint: foodFingerprint,
              amount: normalizedAmount,
              unit: unit,
              updatedAtText: nowText,
            ),
        };

    if (globalKey == null) {
      for (final entry in preferenceDocuments.entries) {
        await entry.key.set(entry.value);
      }
      return;
    }

    final suggestionId = buildServingSuggestionDocumentId(
      itemKey: globalKey,
      amount: normalizedAmount,
      unit: unit,
    );
    final suggestionRef = _globalCollection().doc(suggestionId);
    final voteRef = _userDocument(
      userId: currentUserId,
      collectionName: _votesCollection,
      documentId: suggestionId,
    );

    await _firestore.runTransaction((transaction) async {
      final suggestionSnapshot = await transaction.get(suggestionRef);
      final voteSnapshot = await transaction.get(voteRef);
      final currentData =
          suggestionSnapshot.data() ?? const <String, dynamic>{};
      final selectionCount = _readPositiveInt(currentData['selection_count']);
      final uniqueUserCount = _readPositiveInt(
        currentData['unique_user_count'],
      );
      final nextSelectionCount = (selectionCount ?? 0) + 1;
      final nextUniqueUserCount =
          (uniqueUserCount ?? 0) + (voteSnapshot.exists ? 0 : 1);
      final globalId = globalFoodItemId?.trim();

      for (final entry in preferenceDocuments.entries) {
        transaction.set(entry.key, entry.value);
      }

      transaction.set(suggestionRef, <String, dynamic>{
        'id': suggestionId,
        'item_key': globalKey,
        'global_food_item_id': globalId,
        'amount': normalizedAmount,
        'unit': unit.jsonValue,
        'selection_count': nextSelectionCount,
        'unique_user_count': nextUniqueUserCount,
        'created_at': currentData['created_at'] ?? nowText,
        'updated_at': nowText,
      });
      transaction.set(voteRef, <String, dynamic>{
        'item_key': globalKey,
        'suggestion_id': suggestionId,
        'global_food_item_id': globalId,
        'amount': normalizedAmount,
        'unit': unit.jsonValue,
        'created_at': voteSnapshot.data()?['created_at'] ?? nowText,
        'updated_at': nowText,
      });
    });
  }

  Future<ServingSizeSuggestion?> _readPersonalSuggestion({
    required String? fingerprintKey,
    required String? globalKey,
  }) async {
    final currentUserId = _currentUserId?.trim();
    if (currentUserId == null || currentUserId.isEmpty) {
      return null;
    }

    final futures = <Future<DocumentSnapshot<Map<String, dynamic>>>>[
      if (globalKey != null)
        _userDocument(
          userId: currentUserId,
          collectionName: _prefsCollection,
          documentId: globalKey,
        ).get(),
      if (fingerprintKey != null && fingerprintKey != globalKey)
        _userDocument(
          userId: currentUserId,
          collectionName: _prefsCollection,
          documentId: fingerprintKey,
        ).get(),
    ];
    if (futures.isEmpty) {
      return null;
    }

    final snapshots = await Future.wait(futures);
    Map<String, dynamic>? newestData;
    DateTime? newestUpdatedAt;
    for (final snapshot in snapshots) {
      final data = snapshot.data();
      if (data == null) {
        continue;
      }
      final updatedAt = _readDateTime(data['updated_at']) ?? DateTime(0);
      if (newestUpdatedAt == null || updatedAt.isAfter(newestUpdatedAt)) {
        newestUpdatedAt = updatedAt;
        newestData = data;
      }
    }
    if (newestData == null) {
      return null;
    }

    final amount = _readPositiveDouble(newestData['amount']);
    if (amount == null) {
      return null;
    }
    return ServingSizeSuggestion(
      amount: amount,
      unit: ConsumedUnit.fromJsonValue(newestData['unit'] as String?),
    );
  }

  Future<List<GlobalFoodServingSuggestion>> _readGlobalSuggestions({
    required String itemKey,
    required int limit,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _globalCollection()
          .where('item_key', isEqualTo: itemKey)
          .orderBy('unique_user_count', descending: true)
          .orderBy('selection_count', descending: true)
          .orderBy('updated_at', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (error, stackTrace) {
      log(
        'Serving suggestion index missing, falling back to client-side sort.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      snapshot = await _globalCollection()
          .where('item_key', isEqualTo: itemKey)
          .get();
    }

    final suggestions = <GlobalFoodServingSuggestion>[];
    for (var index = 0; index < snapshot.docs.length; index++) {
      final document = snapshot.docs[index];
      final data = Map<String, dynamic>.from(document.data());
      if ((data['id'] as String?)?.trim().isEmpty ?? true) {
        data['id'] = document.id;
      }
      try {
        suggestions.add(GlobalFoodServingSuggestion.fromJson(data));
      } catch (error, stackTrace) {
        log(
          'Skipping corrupted serving suggestion at index $index.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    suggestions.sort(compareServingSuggestions);
    if (suggestions.length <= limit) {
      return suggestions;
    }
    return suggestions.take(limit).toList(growable: false);
  }

  CollectionReference<Map<String, dynamic>> _globalCollection() {
    return _firestore.collection(_globalSuggestionsCollection);
  }

  DocumentReference<Map<String, dynamic>> _userDocument({
    required String userId,
    required String collectionName,
    required String documentId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .doc(documentId);
  }

  Map<String, dynamic> _buildPreferenceData({
    required String itemKey,
    required String foodFingerprint,
    required double amount,
    required ConsumedUnit unit,
    required String updatedAtText,
    String? globalFoodItemId,
  }) {
    return <String, dynamic>{
      'item_key': itemKey,
      'global_food_item_id': globalFoodItemId?.trim(),
      'food_fingerprint': foodFingerprint.trim(),
      'amount': amount,
      'unit': unit.jsonValue,
      'updated_at': updatedAtText,
    };
  }
}

int? _readPositiveInt(Object? value) {
  return readPositiveInt(value);
}

double? _readPositiveDouble(Object? value) {
  final parsed = readPositiveDouble(value);
  if (parsed == null) {
    return null;
  }
  return normalizeServingSuggestionAmount(parsed);
}

DateTime? _readDateTime(Object? value) {
  return readDateTime(value);
}
