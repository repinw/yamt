import 'package:yamt/features/inventory/application/'
    'prepared_meal_edit.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_writer.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

/// Handles prepared meal editing and inventory reconciliation workflows.
class PreparedMealEditing {
  /// Creates editing workflows.
  const new({required this._writer});

  final PreparedMealWriter _writer;

  /// Updates a prepared meal's editable details.
  Future<bool> updatePreparedMealDetails({
    required String mealId,
    required String name,
    required bool imageChanged,
    required String? imageAssetId,
    int? totalPortions,
    List<PreparedMealItemInput>? items,
    InventoryItemRepository? inventoryRepository,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return false;
    }

    final currentMeals = await _writer.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }

    final currentMeal = currentMeals[mealIndex];
    if (totalPortions != null || items != null) {
      if (totalPortions == currentMeal.totalPortions &&
          items != null &&
          _hasSameComponentInputs(currentMeal.components, items)) {
        return await _updatePreparedMealMetadata(
          currentMeals: currentMeals,
          mealIndex: mealIndex,
          name: trimmedName,
          imageChanged: imageChanged,
          imageAssetId: imageAssetId,
        );
      }
      return await _updatePreparedMealContent(
        currentMeals: currentMeals,
        mealIndex: mealIndex,
        name: trimmedName,
        imageChanged: imageChanged,
        imageAssetId: imageAssetId,
        totalPortions: totalPortions,
        items: items,
        inventoryRepository: inventoryRepository,
      );
    }

    return await _updatePreparedMealMetadata(
      currentMeals: currentMeals,
      mealIndex: mealIndex,
      name: trimmedName,
      imageChanged: imageChanged,
      imageAssetId: imageAssetId,
    );
  }

  Future<bool> _updatePreparedMealMetadata({
    required List<PreparedMeal> currentMeals,
    required int mealIndex,
    required String name,
    required bool imageChanged,
    required String? imageAssetId,
  }) {
    final currentMeal = currentMeals[mealIndex];
    final normalizedImageAssetId = imageChanged
        ? normalizeOptionalImageAssetId(imageAssetId)
        : currentMeal.imageAssetId;
    final isUnchanged =
        currentMeal.name == name &&
        (!imageChanged || currentMeal.imageAssetId == normalizedImageAssetId);
    if (isUnchanged) {
      return Future<bool>.value(true);
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals);
    final updatedAt = _writer.buildNow();
    nextMeals[mealIndex] = imageChanged
        ? currentMeal.copyWith(
            name: name,
            imageAssetId: normalizedImageAssetId,
            updatedAt: updatedAt,
          )
        : currentMeal.copyWith(name: name, updatedAt: updatedAt);
    return _writer.saveMeals(previousMeals: currentMeals, nextMeals: nextMeals);
  }

  Future<bool> _updatePreparedMealContent({
    required List<PreparedMeal> currentMeals,
    required int mealIndex,
    required String name,
    required bool imageChanged,
    required String? imageAssetId,
    required int? totalPortions,
    required List<PreparedMealItemInput>? items,
    required InventoryItemRepository? inventoryRepository,
  }) async {
    if (totalPortions == null || items == null || inventoryRepository == null) {
      return false;
    }

    final currentMeal = currentMeals[mealIndex];
    if (_isPreparedMealContentUnchanged(
      meal: currentMeal,
      name: name,
      imageChanged: imageChanged,
      imageAssetId: imageAssetId,
      totalPortions: totalPortions,
      items: items,
    )) {
      return true;
    }

    final currentItems = await inventoryRepository.readAllForChange();
    final buildResult = _tryBuildPreparedMealEdit(
      currentMeal: currentMeal,
      currentItems: currentItems,
      name: name,
      imageChanged: imageChanged,
      imageAssetId: imageAssetId,
      totalPortions: totalPortions,
      items: items,
    );
    if (buildResult == null) {
      return false;
    }

    final inventorySaved = await inventoryRepository.saveChanges(
      previous: currentItems,
      next: buildResult.nextItems,
    );
    if (!inventorySaved) {
      return false;
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = buildResult.preparedMeal;
    final mealsSaved = await _writer.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (mealsSaved) {
      return true;
    }

    await _writer.restoreInventory(
      inventoryRepository: inventoryRepository,
      writtenItems: buildResult.nextItems,
      previousItems: currentItems,
    );
    return false;
  }

  PreparedMealBuildResult? _tryBuildPreparedMealEdit({
    required PreparedMeal currentMeal,
    required List<InventoryItem> currentItems,
    required String name,
    required bool imageChanged,
    required String? imageAssetId,
    required int totalPortions,
    required List<PreparedMealItemInput> items,
  }) {
    try {
      return buildPreparedMealEditResult(
        currentMeal: currentMeal,
        currentItems: currentItems,
        now: _writer.buildNow(),
        name: name,
        imageChanged: imageChanged,
        imageAssetId: imageAssetId,
        totalPortions: totalPortions,
        inputs: items,
      );
    } on PreparedMealBuildException {
      return null;
    }
  }

  bool _isPreparedMealContentUnchanged({
    required PreparedMeal meal,
    required String name,
    required bool imageChanged,
    required String? imageAssetId,
    required int totalPortions,
    required List<PreparedMealItemInput> items,
  }) {
    final normalizedImageAssetId = imageChanged
        ? normalizeOptionalImageAssetId(imageAssetId)
        : meal.imageAssetId;
    return meal.name == name &&
        meal.imageAssetId == normalizedImageAssetId &&
        meal.totalPortions == totalPortions &&
        _hasSameComponentInputs(meal.components, items);
  }

  bool _hasSameComponentInputs(
    List<PreparedMealComponent> components,
    List<PreparedMealItemInput> inputs,
  ) {
    if (components.length != inputs.length) {
      return false;
    }
    for (var index = 0; index < components.length; index += 1) {
      final component = components[index];
      final input = inputs[index];
      if (component.inventoryItemId != input.itemId ||
          component.usedAmount != input.usedAmount ||
          input.manualNutrition != null) {
        return false;
      }
    }
    return true;
  }

  /// Restores all remaining ingredients from a prepared meal back to inventory.
  Future<bool> unbundlePreparedMeal({
    required String mealId,
    required InventoryItemRepository inventoryRepository,
    Set<String> deletedItemIds = const <String>{},
  }) async {
    final currentMeals = await _writer.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }

    final meal = currentMeals[mealIndex];
    final currentItems = await inventoryRepository.readAllForChange();
    final restoredItems = [
      for (final item in restoreItemsFromPreparedMeal(
        currentItems: currentItems,
        meal: meal,
      ))
        if (!deletedItemIds.contains(item.id)) item,
    ];

    final inventorySaved = await inventoryRepository.saveChanges(
      previous: currentItems,
      next: restoredItems,
    );
    if (!inventorySaved) {
      return false;
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals)
      ..removeAt(mealIndex);
    final mealsSaved = await _writer.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (mealsSaved) {
      return true;
    }

    await _writer.restoreInventory(
      inventoryRepository: inventoryRepository,
      writtenItems: restoredItems,
      previousItems: currentItems,
    );
    return false;
  }
}
