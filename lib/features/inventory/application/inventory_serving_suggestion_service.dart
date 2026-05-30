import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_serving_suggestion_repository.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'inventory_serving_suggestion_service.g.dart';

/// Coordinates serving suggestion reads and writes for inventory items.
class InventoryServingSuggestionService {
  /// The inventory serving suggestion service.
  const InventoryServingSuggestionService(this._repository);

  final GlobalFoodServingSuggestionRepository _repository;

  /// Reads learned suggestions for [item].
  Future<GlobalFoodServingSuggestionSet> readSuggestions(
    InventoryItem item, {
    int limit = 5,
  }) {
    return _repository.readSuggestions(
      foodFingerprint: item.resolvedFoodFingerprint,
      globalFoodItemId: item.globalFoodItemId,
      limit: limit,
    );
  }

  /// Persists a user-created portion for [item].
  Future<void> recordCreatedPortion({
    required InventoryItem item,
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
    String? label,
  }) {
    return recordSelection(
      foodFingerprint: item.resolvedFoodFingerprint,
      globalFoodItemId: item.globalFoodItemId,
      amount: amount,
      unit: unit,
      label: label,
      selectedAt: selectedAt,
    );
  }

  /// Records a learned serving selection.
  Future<void> recordSelection({
    required String foodFingerprint,
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
    String? globalFoodItemId,
    String? label,
  }) async {
    try {
      await _repository.recordSelection(
        foodFingerprint: foodFingerprint,
        globalFoodItemId: globalFoodItemId,
        amount: amount,
        unit: unit,
        label: label,
        selectedAt: selectedAt,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to record inventory serving suggestion.',
        name: 'InventoryServingSuggestionService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// The inventory serving suggestion service provider.
@riverpod
InventoryServingSuggestionService inventoryServingSuggestionService(Ref ref) {
  final repository = ref.watch(globalFoodServingSuggestionRepositoryProvider);
  return InventoryServingSuggestionService(repository);
}
