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
      final globalFuture = _readSharedSuggestions(
        fingerprintKey: fingerprintKey,
        globalKey: globalKey,
        limit: safeLimit,
      );
      final results = await Future.wait<Object?>(<Future<Object?>>[
        personalFuture,
        globalFuture,
      ]);

      return GlobalFoodServingSuggestionSet(
        personalSuggestion: results[0] as ServingSizeSuggestion?,
        globalSuggestions: results[1]! as List<GlobalFoodServingSuggestion>,
      );
    } on Object catch (error, stackTrace) {
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
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
    String? globalFoodItemId,
    String? label,
  }) async {
    final currentUserId = _currentUserId?.trim();
    if (currentUserId == null || currentUserId.isEmpty || amount <= 0) {
      return;
    }

    final normalizedAmount = normalizeServingSuggestionAmount(amount);
    if (normalizedAmount <= 0) {
      return;
    }
    final normalizedLabel = _readOptionalString(label);

    final fingerprintKey = buildFingerprintServingItemKey(foodFingerprint);
    final globalKey = buildGlobalServingItemKey(globalFoodItemId);
    if (fingerprintKey == null && globalKey == null) {
      return;
    }

    final nowText = selectedAt.toIso8601String();
    final preferenceTargets = <_PreferenceWriteTarget>[
      if (fingerprintKey != null)
        _PreferenceWriteTarget(
          document: _userDocument(
            userId: currentUserId,
            collectionName: _prefsCollection,
            documentId: fingerprintKey,
          ),
          itemKey: fingerprintKey,
          globalFoodItemId: globalKey == null ? null : globalFoodItemId,
          foodFingerprint: foodFingerprint,
        ),
      if (globalKey != null)
        _PreferenceWriteTarget(
          document: _userDocument(
            userId: currentUserId,
            collectionName: _prefsCollection,
            documentId: globalKey,
          ),
          itemKey: globalKey,
          globalFoodItemId: globalFoodItemId,
          foodFingerprint: foodFingerprint,
        ),
    ];

    final sharedKey = globalKey ?? fingerprintKey;
    if (sharedKey == null) {
      await _writePreferenceTargetsSafely(
        targets: preferenceTargets,
        amount: normalizedAmount,
        unit: unit,
        label: normalizedLabel,
        updatedAtText: nowText,
      );
      return;
    }

    final suggestionId = buildServingSuggestionDocumentId(
      itemKey: sharedKey,
      amount: normalizedAmount,
      unit: unit,
    );
    final suggestionRef = _globalCollection().doc(suggestionId);
    final voteRef = _userDocument(
      userId: currentUserId,
      collectionName: _votesCollection,
      documentId: suggestionId,
    );

    try {
      await _firestore.runTransaction((transaction) async {
        final suggestionSnapshot = await transaction.get(suggestionRef);
        final voteSnapshot = await transaction.get(voteRef);
        final currentData =
            suggestionSnapshot.data() ?? const <String, dynamic>{};
        final preferenceDataByDocument =
            <DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>{};
        for (final target in preferenceTargets) {
          final preferenceSnapshot = normalizedLabel == null
              ? await transaction.get(target.document)
              : null;
          final label = _resolvePreferenceLabelFromData(
            data: preferenceSnapshot?.data(),
            amount: normalizedAmount,
            unit: unit,
            newLabel: normalizedLabel,
          );
          preferenceDataByDocument[target.document] = _buildPreferenceData(
            itemKey: target.itemKey,
            globalFoodItemId: target.globalFoodItemId,
            foodFingerprint: target.foodFingerprint,
            amount: normalizedAmount,
            unit: unit,
            label: label,
            updatedAtText: nowText,
          );
        }
        final selectionCount = _readPositiveInt(
          currentData['selection_count'],
        );
        final uniqueUserCount = _readPositiveInt(
          currentData['unique_user_count'],
        );
        final nextSelectionCount = (selectionCount ?? 0) + 1;
        final nextUniqueUserCount =
            (uniqueUserCount ?? 0) + (voteSnapshot.exists ? 0 : 1);
        final globalId = globalKey == null ? null : globalFoodItemId?.trim();
        final sharedLabel = _resolveSharedLabelFromData(
          data: currentData,
          newLabel: normalizedLabel,
        );

        for (final entry in preferenceDataByDocument.entries) {
          transaction.set(entry.key, entry.value);
        }

        transaction
          ..set(suggestionRef, <String, dynamic>{
            'id': suggestionId,
            'item_key': sharedKey,
            'global_food_item_id': globalId,
            'food_fingerprint': foodFingerprint.trim(),
            'amount': normalizedAmount,
            'unit': unit.jsonValue,
            'label': sharedLabel,
            'selection_count': nextSelectionCount,
            'unique_user_count': nextUniqueUserCount,
            'created_at': currentData['created_at'] ?? nowText,
            'updated_at': nowText,
          })
          ..set(voteRef, <String, dynamic>{
            'item_key': sharedKey,
            'suggestion_id': suggestionId,
            'global_food_item_id': globalId,
            'food_fingerprint': foodFingerprint.trim(),
            'amount': normalizedAmount,
            'unit': unit.jsonValue,
            'created_at': voteSnapshot.data()?['created_at'] ?? nowText,
            'updated_at': nowText,
          });
      });
    } on FirebaseException catch (error, stackTrace) {
      if (_isPermissionDenied(error)) {
        await _writePreferenceTargetsSafely(
          targets: preferenceTargets,
          amount: normalizedAmount,
          unit: unit,
          label: normalizedLabel,
          updatedAtText: nowText,
        );
        return;
      }
      log(
        'Failed to record serving suggestion.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _writePreferenceTargetsSafely({
    required List<_PreferenceWriteTarget> targets,
    required double amount,
    required ConsumedUnit unit,
    required String? label,
    required String updatedAtText,
  }) async {
    try {
      await _writePreferenceTargets(
        targets: targets,
        amount: amount,
        unit: unit,
        label: label,
        updatedAtText: updatedAtText,
      );
    } on FirebaseException catch (error, stackTrace) {
      if (_isPermissionDenied(error)) {
        return;
      }
      log(
        'Failed to record personal serving suggestion.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _writePreferenceTargets({
    required List<_PreferenceWriteTarget> targets,
    required double amount,
    required ConsumedUnit unit,
    required String? label,
    required String updatedAtText,
  }) async {
    for (final target in targets) {
      final resolvedLabel = await _resolvePreferenceLabel(
        document: target.document,
        amount: amount,
        unit: unit,
        newLabel: label,
      );
      await target.document.set(
        _buildPreferenceData(
          itemKey: target.itemKey,
          globalFoodItemId: target.globalFoodItemId,
          foodFingerprint: target.foodFingerprint,
          amount: amount,
          unit: unit,
          label: resolvedLabel,
          updatedAtText: updatedAtText,
        ),
      );
    }
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
      label: _readOptionalString(newestData['label']),
    );
  }

  bool _isPermissionDenied(FirebaseException error) {
    return error.code == 'permission-denied';
  }

  Future<List<GlobalFoodServingSuggestion>> _readSharedSuggestions({
    required String? fingerprintKey,
    required String? globalKey,
    required int limit,
  }) async {
    final itemKeys = <String>[
      ?globalKey,
      if (fingerprintKey != globalKey) ?fingerprintKey,
    ];
    if (itemKeys.isEmpty) {
      return const <GlobalFoodServingSuggestion>[];
    }

    final results = await Future.wait(
      itemKeys.map((itemKey) {
        return _readGlobalSuggestions(itemKey: itemKey, limit: limit);
      }),
    );
    final suggestions = <GlobalFoodServingSuggestion>[
      for (final result in results) ...result,
    ];
    return _dedupeSharedSuggestions(suggestions, limit);
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
      } on Object catch (error, stackTrace) {
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

  List<GlobalFoodServingSuggestion> _dedupeSharedSuggestions(
    List<GlobalFoodServingSuggestion> suggestions,
    int limit,
  ) {
    suggestions.sort(compareServingSuggestions);
    final indexByValue = <String, int>{};
    final deduped = <GlobalFoodServingSuggestion>[];
    for (final suggestion in suggestions) {
      final key = _suggestionValueKey(suggestion);
      final existingIndex = indexByValue[key];
      if (existingIndex != null) {
        final existing = deduped[existingIndex];
        if (existing.label == null && suggestion.label != null) {
          deduped[existingIndex] = existing.copyWith(
            label: suggestion.label,
          );
        }
        continue;
      }
      if (deduped.length == limit) {
        continue;
      }
      indexByValue[key] = deduped.length;
      deduped.add(suggestion);
    }
    return deduped;
  }

  String _suggestionValueKey(GlobalFoodServingSuggestion suggestion) {
    return '${suggestion.unit.jsonValue}:'
        '${buildServingSuggestionAmountKey(suggestion.amount)}';
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
    String? label,
  }) {
    return <String, dynamic>{
      'item_key': itemKey,
      'global_food_item_id': globalFoodItemId?.trim(),
      'food_fingerprint': foodFingerprint.trim(),
      'amount': amount,
      'unit': unit.jsonValue,
      'label': label,
      'updated_at': updatedAtText,
    };
  }

  Future<String?> _resolvePreferenceLabel({
    required DocumentReference<Map<String, dynamic>> document,
    required double amount,
    required ConsumedUnit unit,
    required String? newLabel,
  }) async {
    if (newLabel != null) {
      return newLabel;
    }
    final snapshot = await document.get();
    return _resolvePreferenceLabelFromData(
      data: snapshot.data(),
      amount: amount,
      unit: unit,
      newLabel: newLabel,
    );
  }
}

class _PreferenceWriteTarget {
  const _PreferenceWriteTarget({
    required this.document,
    required this.itemKey,
    required this.foodFingerprint,
    required this.globalFoodItemId,
  });

  final DocumentReference<Map<String, dynamic>> document;
  final String itemKey;
  final String foodFingerprint;
  final String? globalFoodItemId;
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

String? _readOptionalString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String? _resolvePreferenceLabelFromData({
  required Map<String, dynamic>? data,
  required double amount,
  required ConsumedUnit unit,
  required String? newLabel,
}) {
  if (newLabel != null) {
    return newLabel;
  }
  if (data == null) {
    return null;
  }
  final existingAmount = _readPositiveDouble(data['amount']);
  if (existingAmount == null || existingAmount != amount) {
    return null;
  }
  final existingUnit = ConsumedUnit.fromJsonValue(data['unit'] as String?);
  if (existingUnit != unit) {
    return null;
  }
  return _readOptionalString(data['label']);
}

String? _resolveSharedLabelFromData({
  required Map<String, dynamic>? data,
  required String? newLabel,
}) {
  return newLabel ?? _readOptionalString(data?['label']);
}
