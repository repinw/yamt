import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_item_patch.dart';

const String _storeLogName = 'FirestoreGlobalFoodItemStore';
const String _globalFoodItemsCollection = 'global_food_items';
const List<String> _patchableGlobalFoodItemFields = <String>[
  'brand',
  'category',
  'store_name',
  'barcode',
  'image_url',
  'package_weight',
  'serving_size',
  'serving_quantity',
  'serving_quantity_unit',
  'normalized_brand',
  'normalized_store_name',
];
const List<String> _patchableNutritionFields = <String>[
  'quality_status',
  'per_100_kcal',
  'per_100_protein',
  'per_100_carbs',
  'per_100_fat',
  'per_100_salt',
  'per_100_saturated_fat',
  'per_100_polyunsaturated_fat',
  'per_100_sugar',
  'per_100_fiber',
];
final Object _omittedValue = Object();

/// Defines global food item document.
class GlobalFoodItemDocument {
  /// The global food item document.
  const GlobalFoodItemDocument({required this.id, required this.data});

  /// The id.
  final String id;

  /// The data.
  final Map<String, dynamic> data;
}

/// Defines global food item store.
abstract interface class GlobalFoodItemStore {
  /// Read all.
  Future<List<GlobalFoodItemDocument>> readAll();

  /// Search candidates.
  Future<List<GlobalFoodItemDocument>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  });

  /// Watch all.
  Stream<List<GlobalFoodItemDocument>> watchAll();

  /// Replace all.
  Future<bool> replaceAll({
    required Map<String, Map<String, dynamic>> documentsById,
  });

  /// Upsert all.
  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

/// Defines firestore global food item store.
class FirestoreGlobalFoodItemStore implements GlobalFoodItemStore {
  /// The firestore global food item store.
  const FirestoreGlobalFoodItemStore({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  FirestoreAtomicReplaceService get _atomicReplaceService {
    return FirestoreAtomicReplaceService(firestore: _firestore);
  }

  @override
  Future<List<GlobalFoodItemDocument>> readAll() async {
    final snapshot = await _collection().get();
    return _mapSnapshot(snapshot);
  }

  @override
  Future<List<GlobalFoodItemDocument>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    final safeLimit = limit < 1 ? 1 : limit;
    final queries = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    final normalizedSearchTokens = _normalizeSearchTokens(searchTokens);
    final normalizedNormalizedName = _normalizeQueryValue(normalizedName);
    final normalizedNormalizedStoreName = _normalizeQueryValue(
      normalizedStoreName,
    );
    final normalizedBarcode = _normalizeQueryValue(barcode);
    final normalizedFingerprint = _normalizeQueryValue(foodFingerprint);

    if (normalizedNormalizedName != null) {
      queries.add(
        _collection()
            .where('normalized_name', isEqualTo: normalizedNormalizedName)
            .limit(safeLimit)
            .get(),
      );
    }

    if (normalizedNormalizedStoreName != null) {
      queries.add(
        _collection()
            .where(
              'normalized_store_name',
              isEqualTo: normalizedNormalizedStoreName,
            )
            .limit(safeLimit)
            .get(),
      );
    }

    if (normalizedBarcode != null) {
      queries.add(
        _collection()
            .where('barcode', isEqualTo: normalizedBarcode)
            .limit(safeLimit)
            .get(),
      );
    }

    if (normalizedFingerprint != null) {
      queries.add(
        _collection()
            .where('food_fingerprint', isEqualTo: normalizedFingerprint)
            .limit(safeLimit)
            .get(),
      );
    }

    if (normalizedSearchTokens.isNotEmpty) {
      queries.add(
        _collection()
            .where('search_tokens', arrayContainsAny: normalizedSearchTokens)
            .limit(safeLimit)
            .get(),
      );
    }

    if (queries.isEmpty) {
      return const <GlobalFoodItemDocument>[];
    }

    final snapshots = await Future.wait(queries);
    final documentsById = <String, GlobalFoodItemDocument>{};
    for (final snapshot in snapshots) {
      for (final document in _mapSnapshot(snapshot)) {
        documentsById[document.id] = document;
      }
    }
    return documentsById.values.toList(growable: false);
  }

  @override
  Stream<List<GlobalFoodItemDocument>> watchAll() {
    return _collection().snapshots().map(_mapSnapshot);
  }

  @override
  Future<bool> replaceAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _atomicReplaceService.replaceAll(
        collection: _collection(),
        documentsById: documentsById,
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to replace global food items.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _upsertDocuments(documentsById);
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to upsert global food items.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> _collection() {
    return _firestore.collection(_globalFoodItemsCollection);
  }

  Future<void> _upsertDocuments(
    Map<String, Map<String, dynamic>> documentsById,
  ) async {
    for (final entry in documentsById.entries) {
      await _firestore.runTransaction((transaction) async {
        final reference = _collection().doc(entry.key);
        final nextDocument = _compactMap(entry.value);
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) {
          transaction.set(reference, nextDocument);
          return;
        }

        final currentData = snapshot.data() ?? const <String, dynamic>{};
        final currentItem = GlobalFoodItem.fromJson(currentData);
        final patchItem = GlobalFoodItem.fromJson(nextDocument);
        final mergedItem = mergeGlobalFoodItemPatch(
          currentItem: currentItem,
          patchItem: patchItem,
          updatedAt:
              DateTime.tryParse(nextDocument['updated_at'] as String? ?? '') ??
              patchItem.updatedAt,
        );
        final updateData = _buildUpdateData(
          currentData: currentData,
          mergedData: _compactMap(mergedItem.toJson()),
        );
        transaction.update(reference, updateData);
      });
    }
  }

  Map<String, dynamic> _buildUpdateData({
    required Map<String, dynamic> currentData,
    required Map<String, dynamic> mergedData,
  }) {
    final updateData = <String, dynamic>{
      'updated_at': mergedData['updated_at'],
    };

    for (final key in _patchableGlobalFoodItemFields) {
      if (!mergedData.containsKey(key)) {
        continue;
      }
      if (currentData[key] == mergedData[key]) {
        continue;
      }
      updateData[key] = mergedData[key];
    }

    final currentNutrition = _readMap(currentData['nutrition']);
    final mergedNutrition = _readMap(mergedData['nutrition']);
    if (mergedNutrition == null) {
      return updateData;
    }
    if (currentNutrition == null) {
      updateData['nutrition'] = mergedNutrition;
      return updateData;
    }

    for (final key in _patchableNutritionFields) {
      if (!mergedNutrition.containsKey(key)) {
        continue;
      }
      if (currentNutrition[key] == mergedNutrition[key]) {
        continue;
      }
      updateData['nutrition.$key'] = mergedNutrition[key];
    }

    return updateData;
  }

  Map<String, dynamic>? _readMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(key.toString(), nestedValue),
      );
    }
    return null;
  }

  // `null` in upsert payload means "do not patch this field". Deletions are
  // intentionally not supported here because Firestore rules only allow
  // fill-missing updates for global food items.
  Map<String, dynamic> _compactMap(Map<String, dynamic> input) {
    final compacted = <String, dynamic>{};
    for (final entry in input.entries) {
      final compactedValue = _compactValue(entry.value);
      if (identical(compactedValue, _omittedValue)) {
        continue;
      }
      compacted[entry.key] = compactedValue;
    }
    return compacted;
  }

  dynamic _compactValue(Object? value) {
    if (value == null) {
      return _omittedValue;
    }
    if (value is Map<String, dynamic>) {
      return _compactMap(value);
    }
    if (value is Map) {
      return _compactMap(
        value.map(
          (key, nestedValue) => MapEntry(key.toString(), nestedValue),
        ),
      );
    }
    if (value is Iterable) {
      return value
          .map(_compactValue)
          .where((item) => !identical(item, _omittedValue))
          .toList(growable: false);
    }
    return value;
  }

  List<GlobalFoodItemDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => GlobalFoodItemDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }

  List<String> _normalizeSearchTokens(List<String> tokens) {
    final normalized = <String>{};
    for (final token in tokens) {
      final trimmed = _normalizeQueryValue(token);
      if (trimmed == null) {
        continue;
      }
      normalized.add(trimmed);
      if (normalized.length == 10) {
        break;
      }
    }
    return normalized.toList(growable: false);
  }

  String? _normalizeQueryValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
