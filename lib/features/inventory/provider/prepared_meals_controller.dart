import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_refs.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'prepared_meals_controller.g.dart';

const _preparedMealsControllerLogName = 'PreparedMealsController';

enum PreparedMealCreationFailureReason {
  invalidInput,
  itemUnavailable,
  insufficientAmount,
  missingNutrition,
  inventorySaveFailed,
  mealSaveFailed,
}

class PreparedMealCreationResult {
  const PreparedMealCreationResult._({
    required this.isSuccess,
    this.preparedMealId,
    this.failureReason,
  });

  const PreparedMealCreationResult.success(String preparedMealId)
    : this._(isSuccess: true, preparedMealId: preparedMealId);

  const PreparedMealCreationResult.failure(
    PreparedMealCreationFailureReason reason,
  ) : this._(isSuccess: false, failureReason: reason);

  final bool isSuccess;
  final String? preparedMealId;
  final PreparedMealCreationFailureReason? failureReason;
}

class _PreparedMealCreationException implements Exception {
  const _PreparedMealCreationException(this.reason);

  final PreparedMealCreationFailureReason reason;
}

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

  Future<PreparedMealCreationResult> createPreparedMeal({
    required String name,
    String? imageBase64,
    required int totalPortions,
    required List<PreparedMealItemInput> items,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || totalPortions < 1 || items.isEmpty) {
      return Future<PreparedMealCreationResult>.value(
        const PreparedMealCreationResult.failure(
          PreparedMealCreationFailureReason.invalidInput,
        ),
      );
    }

    final keepAliveLink = ref.keepAlive();
    return _mutationQueue
        .run<PreparedMealCreationResult>(
          operation: () async {
            final currentMeals = await _currentMeals();
            final inventoryRepository = ref.read(
              inventoryItemRepositoryProvider,
            );
            final currentItems = await inventoryRepository.readAll();

            try {
              final creationResult = _buildMealCreationResult(
                currentItems: currentItems,
                name: trimmedName,
                imageBase64: imageBase64,
                totalPortions: totalPortions,
                inputs: items,
              );

              final inventorySaved = await inventoryRepository.saveAll(
                creationResult.nextItems,
              );
              if (!inventorySaved) {
                return const PreparedMealCreationResult.failure(
                  PreparedMealCreationFailureReason.inventorySaveFailed,
                );
              }

              final nextMeals = List<PreparedMeal>.from(currentMeals)
                ..add(creationResult.preparedMeal);
              final mealsSaved = await _saveMeals(
                previousMeals: currentMeals,
                nextMeals: nextMeals,
              );
              if (mealsSaved) {
                return PreparedMealCreationResult.success(
                  creationResult.preparedMeal.id,
                );
              }

              await _restoreInventory(
                inventoryRepository: inventoryRepository,
                previousItems: currentItems,
              );
              return const PreparedMealCreationResult.failure(
                PreparedMealCreationFailureReason.mealSaveFailed,
              );
            } on _PreparedMealCreationException catch (error) {
              return PreparedMealCreationResult.failure(error.reason);
            }
          },
          fallbackValue: const PreparedMealCreationResult.failure(
            PreparedMealCreationFailureReason.mealSaveFailed,
          ),
          onError: (error, stackTrace) {
            log(
              'Unexpected prepared meal creation error.',
              name: _preparedMealsControllerLogName,
              error: error,
              stackTrace: stackTrace,
            );
          },
        )
        .whenComplete(keepAliveLink.close);
  }

  Future<bool> updatePreparedMealDetails({
    required String mealId,
    required String name,
    bool imageChanged = false,
    String? imageBase64,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(() async {
      final currentMeals = await _currentMeals();
      final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
      if (mealIndex < 0) {
        return false;
      }

      final currentMeal = currentMeals[mealIndex];
      final normalizedImageBase64 = imageChanged
          ? _normalizeOptionalImageBase64(imageBase64)
          : currentMeal.imageBase64;
      final isUnchanged =
          currentMeal.name == trimmedName &&
          (!imageChanged || currentMeal.imageBase64 == normalizedImageBase64);
      if (isUnchanged) {
        return true;
      }

      final nextMeals = List<PreparedMeal>.from(currentMeals);
      nextMeals[mealIndex] = imageChanged
          ? currentMeal.copyWith(
              name: trimmedName,
              imageBase64: normalizedImageBase64,
              updatedAt: DateTime.now(),
            )
          : currentMeal.copyWith(name: trimmedName, updatedAt: DateTime.now());
      return _saveMeals(previousMeals: currentMeals, nextMeals: nextMeals);
    }).whenComplete(keepAliveLink.close);
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

    final keepAliveLink = ref.keepAlive();
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

      final calorieSaved = await ref
          .read(preparedMealCalorieLogBridgeProvider)
          .logConsumedPreparedMeal(
            meal: meal,
            consumedPortions: consumedPortions,
            mealType: mealType,
          );
      log(
        'Bundle calorie entry save completed mealId=$mealId '
        'saved=$calorieSaved consumedPortions=$consumedPortions.',
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
    }).whenComplete(keepAliveLink.close);
  }

  Future<bool> throwAwayPreparedMeal({
    required String mealId,
    required int discardedPortions,
  }) {
    if (discardedPortions < 1) {
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
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
    }).whenComplete(keepAliveLink.close);
  }

  Future<bool> restorePreparedMealPortions({
    required String mealId,
    required int portions,
  }) {
    if (portions < 1) {
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(() async {
      final currentMeals = await _currentMeals();
      final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
      if (mealIndex < 0) {
        return false;
      }

      final meal = currentMeals[mealIndex];
      final nextRemainingPortions = meal.remainingPortions + portions;
      if (nextRemainingPortions > meal.totalPortions) {
        return false;
      }

      final nextMeals = List<PreparedMeal>.from(currentMeals);
      nextMeals[mealIndex] = meal.copyWith(
        remainingPortions: nextRemainingPortions,
        updatedAt: DateTime.now(),
      );
      return _saveMeals(previousMeals: currentMeals, nextMeals: nextMeals);
    }).whenComplete(keepAliveLink.close);
  }

  Future<bool> unbundlePreparedMeal(String mealId) {
    final keepAliveLink = ref.keepAlive();
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
    }).whenComplete(keepAliveLink.close);
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
      if (saved) {
        await _deleteImagesForRemovedMeals(
          previousMeals: previousMeals,
          nextMeals: nextMeals,
        );
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

  Future<void> _deleteImagesForRemovedMeals({
    required List<PreparedMeal> previousMeals,
    required List<PreparedMeal> nextMeals,
  }) async {
    final nextIds = nextMeals.map((meal) => meal.id).toSet();
    final removedIds = previousMeals
        .map((meal) => meal.id)
        .where((mealId) => !nextIds.contains(mealId));
    final store = ref.read(localImageStoreProvider);

    for (final mealId in removedIds) {
      final imageRef = preparedMealImageRef(mealId);
      await store.deleteImage(imageRef);
      ref.invalidate(localImageBytesProvider(imageRef));
    }
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

_PreparedMealCreationResult _buildMealCreationResult({
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
      throw const _PreparedMealCreationException(
        PreparedMealCreationFailureReason.invalidInput,
      );
    }

    final itemIndex = nextItems.indexWhere((item) => item.id == input.itemId);
    if (itemIndex < 0) {
      throw const _PreparedMealCreationException(
        PreparedMealCreationFailureReason.itemUnavailable,
      );
    }

    final currentItem = nextItems[itemIndex];
    final availableAmount = _availableAmount(currentItem);
    if (input.usedAmount > availableAmount) {
      throw const _PreparedMealCreationException(
        PreparedMealCreationFailureReason.insufficientAmount,
      );
    }

    final resolvedNutrition = input.manualNutrition ?? currentItem.nutrition;
    if (!_hasCompleteNutrition(resolvedNutrition)) {
      throw const _PreparedMealCreationException(
        PreparedMealCreationFailureReason.missingNutrition,
      );
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
      throw const _PreparedMealCreationException(
        PreparedMealCreationFailureReason.insufficientAmount,
      );
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
