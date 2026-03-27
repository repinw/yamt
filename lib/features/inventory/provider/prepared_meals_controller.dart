import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'prepared_meals_controller.g.dart';

const _preparedMealsControllerLogName = 'PreparedMealsController';

class PreparedMealItemInput {
  const PreparedMealItemInput({
    required this.itemId,
    required this.usedAmount,
    this.manualNutrition,
  });

  final String itemId;
  final int usedAmount;
  final GlobalFoodNutrition? manualNutrition;
}

@riverpod
class PreparedMealsController extends _$PreparedMealsController {
  static const _uuid = Uuid();

  StreamSubscription<List<PreparedMeal>>? _mealsSubscription;
  final _mutationQueue = SerializedMutationQueue();

  @override
  FutureOr<List<PreparedMeal>> build() {
    ref.watch(preparedMealRepositoryProvider);
    ref.onDispose(_disposeSubscription);
    return _restartSubscription();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_restartSubscription);
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  Future<bool> createPreparedMeal({
    required String name,
    String? imageBase64,
    required int totalPortions,
    required List<PreparedMealItemInput> items,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || totalPortions < 1 || items.isEmpty) {
      return Future<bool>.value(false);
    }

    return _runSerializedMutation(() async {
      final currentMeals = await _currentMeals();
      final inventoryRepository = ref.read(inventoryItemRepositoryProvider);
      final currentItems = await inventoryRepository.readAll();
      final creationResult = _buildMealCreationResult(
        currentItems: currentItems,
        name: trimmedName,
        imageBase64: imageBase64,
        totalPortions: totalPortions,
        inputs: items,
      );
      if (creationResult == null) {
        return false;
      }

      final inventorySaved = await inventoryRepository.saveAll(
        creationResult.nextItems,
      );
      if (!inventorySaved) {
        return false;
      }

      final nextMeals = List<PreparedMeal>.from(currentMeals)
        ..add(creationResult.preparedMeal);
      final mealsSaved = await _saveMeals(
        previousMeals: currentMeals,
        nextMeals: nextMeals,
      );
      if (mealsSaved) {
        return true;
      }

      await _restoreInventory(
        inventoryRepository: inventoryRepository,
        previousItems: currentItems,
      );
      return false;
    });
  }

  Future<bool> updatePreparedMealDetails({
    required String mealId,
    required String name,
    String? imageBase64,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return Future<bool>.value(false);
    }

    return _runSerializedMutation(() async {
      final currentMeals = await _currentMeals();
      final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
      if (mealIndex < 0) {
        return false;
      }

      final currentMeal = currentMeals[mealIndex];
      final normalizedImageBase64 = _normalizeOptionalImageBase64(imageBase64);
      final isUnchanged =
          currentMeal.name == trimmedName &&
          currentMeal.imageBase64 == normalizedImageBase64;
      if (isUnchanged) {
        return true;
      }

      final nextMeals = List<PreparedMeal>.from(currentMeals);
      nextMeals[mealIndex] = currentMeal.copyWith(
        name: trimmedName,
        imageBase64: normalizedImageBase64,
        updatedAt: DateTime.now(),
      );
      return _saveMeals(previousMeals: currentMeals, nextMeals: nextMeals);
    });
  }

  Future<bool> consumePreparedMeal({
    required String mealId,
    required int consumedPortions,
    required MealType mealType,
  }) {
    log(
      'Consume prepared meal requested mealId=$mealId '
      'consumedPortions=$consumedPortions mealType=${mealType.name}.',
      name: _preparedMealsControllerLogName,
    );
    if (consumedPortions < 1) {
      log(
        'Rejecting consume request for mealId=$mealId: '
        'consumedPortions must be >= 1.',
        name: _preparedMealsControllerLogName,
      );
      return Future<bool>.value(false);
    }

    return _runSerializedMutation(() async {
      final currentMeals = await _currentMeals();
      log(
        'Loaded prepared meals for consume mutation '
        'mealId=$mealId meals=${currentMeals.length}.',
        name: _preparedMealsControllerLogName,
      );
      final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
      if (mealIndex < 0) {
        log(
          'Prepared meal not found for consume request mealId=$mealId.',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }

      final meal = currentMeals[mealIndex];
      if (consumedPortions > meal.remainingPortions) {
        log(
          'Rejecting consume request for mealId=$mealId: '
          'consumedPortions=$consumedPortions exceeds '
          'remainingPortions=${meal.remainingPortions}.',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }

      final nextMeals = _applyPortionReduction(
        currentMeals: currentMeals,
        mealIndex: mealIndex,
        consumedPortions: consumedPortions,
      );
      log(
        'Prepared meal portion reduction computed mealId=$mealId '
        'remainingBefore=${meal.remainingPortions} '
        'remainingAfter=${meal.remainingPortions - consumedPortions} '
        'nextMeals=${nextMeals.length}.',
        name: _preparedMealsControllerLogName,
      );
      final savedMeals = await _saveMeals(
        previousMeals: currentMeals,
        nextMeals: nextMeals,
      );
      if (!savedMeals) {
        log(
          'Failed to persist prepared meals before calorie entry save '
          'mealId=$mealId.',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }

      final entry = _buildBundleEntry(
        meal: meal,
        consumedPortions: consumedPortions,
        mealType: mealType,
      );
      log(
        'Built bundle calorie entry entryId=${entry.id} mealId=$mealId '
        'components=${entry.bundleComponents.length} '
        'loggedAt=${entry.loggedAt.toIso8601String()} '
        'totalKcal=${entry.totalKcal.toStringAsFixed(1)}.',
        name: _preparedMealsControllerLogName,
      );
      final calorieSaved = await ref
          .read(calorieLogRepositoryProvider)
          .saveEntry(entry);
      log(
        'Bundle calorie entry save completed entryId=${entry.id} '
        'mealId=$mealId saved=$calorieSaved.',
        name: _preparedMealsControllerLogName,
      );
      if (calorieSaved) {
        return true;
      }

      final rollbackSaved = await _saveMeals(
        previousMeals: nextMeals,
        nextMeals: currentMeals,
      );
      log(
        'Rolled back prepared meal consume mutation mealId=$mealId '
        'rollbackSaved=$rollbackSaved.',
        name: _preparedMealsControllerLogName,
      );
      return false;
    });
  }

  Future<bool> throwAwayPreparedMeal({
    required String mealId,
    required int discardedPortions,
  }) {
    if (discardedPortions < 1) {
      return Future<bool>.value(false);
    }

    return _runSerializedMutation(() async {
      final currentMeals = await _currentMeals();
      final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
      if (mealIndex < 0) {
        return false;
      }

      final meal = currentMeals[mealIndex];
      if (discardedPortions > meal.remainingPortions) {
        return false;
      }

      final nextMeals = _applyPortionReduction(
        currentMeals: currentMeals,
        mealIndex: mealIndex,
        consumedPortions: discardedPortions,
      );
      return _saveMeals(previousMeals: currentMeals, nextMeals: nextMeals);
    });
  }

  Future<bool> unbundlePreparedMeal(String mealId) {
    return _runSerializedMutation(() async {
      final currentMeals = await _currentMeals();
      final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
      if (mealIndex < 0) {
        return false;
      }

      final meal = currentMeals[mealIndex];
      final inventoryRepository = ref.read(inventoryItemRepositoryProvider);
      final currentItems = await inventoryRepository.readAll();
      final restoredItems = _restoreItemsFromMeal(
        currentItems: currentItems,
        meal: meal,
      );

      final inventorySaved = await inventoryRepository.saveAll(restoredItems);
      if (!inventorySaved) {
        return false;
      }

      final nextMeals = List<PreparedMeal>.from(currentMeals)
        ..removeAt(mealIndex);
      final mealsSaved = await _saveMeals(
        previousMeals: currentMeals,
        nextMeals: nextMeals,
      );
      if (mealsSaved) {
        return true;
      }

      await _restoreInventory(
        inventoryRepository: inventoryRepository,
        previousItems: currentItems,
      );
      return false;
    });
  }

  Future<List<PreparedMeal>> _restartSubscription() {
    final initialMeals = Completer<List<PreparedMeal>>();
    final repository = ref.read(preparedMealRepositoryProvider);
    _disposeSubscription();

    _mealsSubscription = repository.watchAll().listen(
      (meals) {
        if (!initialMeals.isCompleted) {
          initialMeals.complete(meals);
          return;
        }
        _onRealtimeMeals(meals);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!initialMeals.isCompleted) {
          initialMeals.completeError(error, stackTrace);
          return;
        }
        _onRealtimeError(error, stackTrace);
      },
    );

    return initialMeals.future;
  }

  void _disposeSubscription() {
    final currentSubscription = _mealsSubscription;
    _mealsSubscription = null;
    if (currentSubscription != null) {
      unawaited(currentSubscription.cancel());
    }
  }

  void _onRealtimeMeals(List<PreparedMeal> meals) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(meals);
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }

  Future<List<PreparedMeal>> _currentMeals() async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }
    return future;
  }

  Future<bool> _saveMeals({
    required List<PreparedMeal> previousMeals,
    required List<PreparedMeal> nextMeals,
  }) async {
    if (ref.mounted) {
      state = AsyncData(nextMeals);
    }

    try {
      log(
        'Persisting prepared meals previous=${previousMeals.length} '
        'next=${nextMeals.length}.',
        name: _preparedMealsControllerLogName,
      );
      final saved = await ref
          .read(preparedMealRepositoryProvider)
          .saveAll(nextMeals);
      log(
        'Prepared meal persistence completed saved=$saved '
        'next=${nextMeals.length}.',
        name: _preparedMealsControllerLogName,
      );
      if (!saved && ref.mounted) {
        state = AsyncData(previousMeals);
      }
      return saved;
    } catch (error, stackTrace) {
      log(
        'Failed to persist prepared meal mutation.',
        name: _preparedMealsControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = AsyncData(previousMeals);
      }
      return false;
    }
  }

  Future<void> _restoreInventory({
    required InventoryItemRepository inventoryRepository,
    required List<InventoryItem> previousItems,
  }) async {
    try {
      await inventoryRepository.saveAll(previousItems);
    } catch (error, stackTrace) {
      log(
        'Failed to restore inventory after prepared meal rollback.',
        name: _preparedMealsControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _runSerializedMutation(Future<bool> Function() mutation) {
    return _mutationQueue.run<bool>(
      operation: mutation,
      fallbackValue: false,
      onError: (error, stackTrace) {
        log(
          'Unexpected prepared meal mutation error.',
          name: _preparedMealsControllerLogName,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }
}

class _PreparedMealCreationResult {
  const _PreparedMealCreationResult({
    required this.nextItems,
    required this.preparedMeal,
  });

  final List<InventoryItem> nextItems;
  final PreparedMeal preparedMeal;
}

_PreparedMealCreationResult? _buildMealCreationResult({
  required List<InventoryItem> currentItems,
  required String name,
  required String? imageBase64,
  required int totalPortions,
  required List<PreparedMealItemInput> inputs,
}) {
  final now = DateTime.now();
  final nextItems = List<InventoryItem>.from(currentItems);
  final components = <PreparedMealComponent>[];

  for (final input in inputs) {
    if (input.usedAmount < 1) {
      return null;
    }

    final itemIndex = nextItems.indexWhere((item) => item.id == input.itemId);
    if (itemIndex < 0) {
      return null;
    }

    final currentItem = nextItems[itemIndex];
    final availableAmount = _availableAmount(currentItem);
    if (input.usedAmount > availableAmount) {
      return null;
    }

    final resolvedNutrition = input.manualNutrition ?? currentItem.nutrition;
    if (!_hasCompleteNutrition(resolvedNutrition)) {
      return null;
    }

    final sourceItemSnapshot = input.manualNutrition == null
        ? currentItem
        : currentItem.copyWith(nutrition: input.manualNutrition);
    final usedUnit = _resolveUsedUnit(currentItem);
    final nextItem = _reduceInventoryItem(
      item: sourceItemSnapshot,
      amount: input.usedAmount,
    );
    if (nextItem == null) {
      return null;
    }

    nextItems[itemIndex] = nextItem;
    components.add(
      _buildPreparedMealComponent(
        item: sourceItemSnapshot,
        usedAmount: input.usedAmount,
        usedUnit: usedUnit,
        nutrition: resolvedNutrition!,
      ),
    );
  }

  final totalKcal = components.fold<double>(
    0,
    (sum, component) => sum + component.totalKcal,
  );
  final totalProtein = components.fold<double>(
    0,
    (sum, component) => sum + component.totalProtein,
  );
  final totalCarbs = components.fold<double>(
    0,
    (sum, component) => sum + component.totalCarbs,
  );
  final totalFat = components.fold<double>(
    0,
    (sum, component) => sum + component.totalFat,
  );

  return _PreparedMealCreationResult(
    nextItems: nextItems,
    preparedMeal: PreparedMeal(
      id: PreparedMealsController._uuid.v4(),
      name: name,
      imageBase64: _normalizeOptionalImageBase64(imageBase64),
      totalPortions: totalPortions,
      remainingPortions: totalPortions,
      totalKcal: totalKcal,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      createdAt: now,
      updatedAt: now,
      components: components,
    ),
  );
}

String? _normalizeOptionalImageBase64(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

PreparedMealComponent _buildPreparedMealComponent({
  required InventoryItem item,
  required int usedAmount,
  required InventoryAmountUnit usedUnit,
  required GlobalFoodNutrition nutrition,
}) {
  final multiplier = _nutritionMultiplier(amount: usedAmount, unit: usedUnit);
  return PreparedMealComponent(
    inventoryItemId: item.id,
    name: item.name,
    brand: item.brand,
    imageUrl: item.imageUrl,
    usedAmount: usedAmount,
    usedUnit: usedUnit,
    totalKcal: (nutrition.per100Kcal ?? 0) * multiplier,
    totalProtein: (nutrition.per100Protein ?? 0) * multiplier,
    totalCarbs: (nutrition.per100Carbs ?? 0) * multiplier,
    totalFat: (nutrition.per100Fat ?? 0) * multiplier,
    sourceItemSnapshot: item,
  );
}

InventoryAmountUnit _resolveUsedUnit(InventoryItem item) {
  if (item.usesAmountProgress) {
    return item.amountUnit ?? InventoryAmountUnit.piece;
  }
  return InventoryAmountUnit.piece;
}

double _nutritionMultiplier({
  required int amount,
  required InventoryAmountUnit unit,
}) {
  if (unit == InventoryAmountUnit.piece) {
    return amount.toDouble();
  }
  return amount / 100;
}

bool _hasCompleteNutrition(GlobalFoodNutrition? nutrition) {
  if (nutrition == null) {
    return false;
  }
  return nutrition.per100Kcal != null &&
      nutrition.per100Protein != null &&
      nutrition.per100Carbs != null &&
      nutrition.per100Fat != null;
}

int _availableAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    return item.currentAmount > 0 ? item.currentAmount : 0;
  }
  return item.quantity > 0 ? item.quantity : 0;
}

InventoryItem? _reduceInventoryItem({
  required InventoryItem item,
  required int amount,
}) {
  if (amount < 1) {
    return null;
  }
  if (item.usesAmountProgress) {
    final nextCurrentAmount = item.currentAmount - amount;
    if (nextCurrentAmount < 0) {
      return null;
    }
    return item.copyWith(
      currentAmount: nextCurrentAmount,
      quantity: _quantityForCurrentAmount(
        item: item,
        currentAmount: nextCurrentAmount,
      ),
    );
  }

  final nextQuantity = item.quantity - amount;
  if (nextQuantity < 0) {
    return null;
  }
  return item.copyWith(quantity: nextQuantity);
}

List<PreparedMeal> _applyPortionReduction({
  required List<PreparedMeal> currentMeals,
  required int mealIndex,
  required int consumedPortions,
}) {
  final currentMeal = currentMeals[mealIndex];
  final nextRemainingPortions =
      currentMeal.remainingPortions - consumedPortions;
  final nextMeals = List<PreparedMeal>.from(currentMeals);
  if (nextRemainingPortions <= 0) {
    nextMeals.removeAt(mealIndex);
    return nextMeals;
  }

  nextMeals[mealIndex] = currentMeal.copyWith(
    remainingPortions: nextRemainingPortions,
    updatedAt: DateTime.now(),
  );
  return nextMeals;
}

CalorieEntry _buildBundleEntry({
  required PreparedMeal meal,
  required int consumedPortions,
  required MealType mealType,
}) {
  final portionRatio = consumedPortions / meal.totalPortions;
  final components = meal.components
      .map(
        (component) => CalorieEntryBundleComponent(
          name: component.name,
          brand: component.brand,
          imageUrl: component.imageUrl,
          amountLabel: _formatMealComponentAmountLabel(
            amount: (component.usedAmount * portionRatio).toStringAsFixed(1),
            unit: component.usedUnit,
          ),
          totalKcal: component.totalKcal * portionRatio,
          totalProtein: component.totalProtein * portionRatio,
          totalCarbs: component.totalCarbs * portionRatio,
          totalFat: component.totalFat * portionRatio,
        ),
      )
      .toList(growable: false);

  return CalorieEntry.bundle(
    id: PreparedMealsController._uuid.v4(),
    userId: '',
    name: meal.name,
    imageBase64: meal.imageBase64,
    mealType: mealType,
    totalKcal: meal.totalKcal * portionRatio,
    totalProtein: meal.totalProtein * portionRatio,
    totalCarbs: meal.totalCarbs * portionRatio,
    totalFat: meal.totalFat * portionRatio,
    bundleSourcePreparedMealId: meal.id,
    bundleConsumedPortions: consumedPortions,
    bundleTotalPortions: meal.totalPortions,
    bundleComponents: components,
    loggedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

String _formatMealComponentAmountLabel({
  required String amount,
  required InventoryAmountUnit unit,
}) {
  final normalizedAmount = amount.endsWith('.0')
      ? amount.substring(0, amount.length - 2)
      : amount;
  return '$normalizedAmount ${_amountUnitCode(unit)}';
}

String _amountUnitCode(InventoryAmountUnit unit) {
  return switch (unit) {
    InventoryAmountUnit.gram => 'g',
    InventoryAmountUnit.milliliter => 'ml',
    InventoryAmountUnit.piece => 'pc',
  };
}

List<InventoryItem> _restoreItemsFromMeal({
  required List<InventoryItem> currentItems,
  required PreparedMeal meal,
}) {
  final nextItems = List<InventoryItem>.from(currentItems);
  for (final component in meal.components) {
    final amountToRestore = _restoreAmountForComponent(
      component: component,
      meal: meal,
    );
    if (amountToRestore < 1) {
      continue;
    }

    final itemIndex = nextItems.indexWhere(
      (item) => item.id == component.inventoryItemId,
    );
    if (itemIndex < 0) {
      nextItems.add(
        _buildRestoredSnapshotItem(
          sourceItem: component.sourceItemSnapshot,
          amountToRestore: amountToRestore,
        ),
      );
      continue;
    }

    nextItems[itemIndex] = _restoreInventoryItemAmount(
      item: nextItems[itemIndex],
      sourceItem: component.sourceItemSnapshot,
      amountToRestore: amountToRestore,
    );
  }
  return nextItems;
}

int _restoreAmountForComponent({
  required PreparedMealComponent component,
  required PreparedMeal meal,
}) {
  if (meal.remainingPortions < 1 || meal.totalPortions < 1) {
    return 0;
  }
  return ((component.usedAmount * meal.remainingPortions) / meal.totalPortions)
      .round();
}

InventoryItem _buildRestoredSnapshotItem({
  required InventoryItem sourceItem,
  required int amountToRestore,
}) {
  if (sourceItem.usesAmountProgress) {
    return sourceItem.copyWith(
      currentAmount: amountToRestore,
      quantity: _quantityForCurrentAmount(
        item: sourceItem,
        currentAmount: amountToRestore,
      ),
    );
  }
  return sourceItem.copyWith(quantity: amountToRestore);
}

InventoryItem _restoreInventoryItemAmount({
  required InventoryItem item,
  required InventoryItem sourceItem,
  required int amountToRestore,
}) {
  if (sourceItem.usesAmountProgress) {
    final nextCurrentAmount = item.currentAmount + amountToRestore;
    return item.copyWith(
      currentAmount: nextCurrentAmount,
      quantity: _quantityForCurrentAmount(
        item: sourceItem,
        currentAmount: nextCurrentAmount,
      ),
      nutrition: sourceItem.nutrition,
    );
  }
  return item.copyWith(
    quantity: item.quantity + amountToRestore,
    nutrition: sourceItem.nutrition,
  );
}

int _quantityForCurrentAmount({
  required InventoryItem item,
  required int currentAmount,
}) {
  final initialAmount = item.initialAmount;
  final initialQuantity = item.initialQuantity;
  if (initialAmount < 1 || initialQuantity < 1) {
    return item.quantity;
  }

  final ratio = currentAmount / initialAmount;
  final projectedQuantity = (initialQuantity * ratio).ceil();
  if (projectedQuantity < 0) {
    return 0;
  }
  if (projectedQuantity > initialQuantity) {
    return initialQuantity;
  }
  return projectedQuantity;
}
