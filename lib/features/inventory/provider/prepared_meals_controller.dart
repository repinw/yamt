import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
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
    String? imageAssetId,
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
            final inventoryRepository = ref.read(
              inventoryItemRepositoryProvider,
            );
            final currentMeals = await _currentMeals();
            final currentItems = await inventoryRepository.readAll();

            try {
              final creationResult = _buildMealCreationResult(
                currentItems: currentItems,
                name: trimmedName,
                imageAssetId: imageAssetId,
                totalPortions: totalPortions,
                inputs: items,
              );
              return _persistCreatedMeal(
                inventoryRepository: inventoryRepository,
                currentMeals: currentMeals,
                currentItems: currentItems,
                creationResult: creationResult,
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

  Future<PreparedMealCreationResult> createPreparedMealFromTemplate({
    required PreparedMeal template,
    required int totalPortions,
    required Map<String, List<String>> recipeIngredientAssignments,
  }) {
    if (totalPortions < 1 || template.name.trim().isEmpty) {
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
            final inventoryRepository = ref.read(
              inventoryItemRepositoryProvider,
            );
            final currentMeals = await _currentMeals();
            final currentItems = await inventoryRepository.readAll();

            try {
              final creationResult = _buildMealCreationFromTemplateResult(
                currentItems: currentItems,
                template: template,
                totalPortions: totalPortions,
                recipeIngredientAssignments: recipeIngredientAssignments,
              );
              return _persistCreatedMeal(
                inventoryRepository: inventoryRepository,
                currentMeals: currentMeals,
                currentItems: currentItems,
                creationResult: creationResult,
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
              'Unexpected template meal creation error.',
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
    String? imageAssetId,
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
      final normalizedImageAssetId = imageChanged
          ? _normalizeOptionalImageAssetId(imageAssetId)
          : currentMeal.imageAssetId;
      final isUnchanged =
          currentMeal.name == trimmedName &&
          (!imageChanged || currentMeal.imageAssetId == normalizedImageAssetId);
      if (isUnchanged) {
        return true;
      }

      final nextMeals = List<PreparedMeal>.from(currentMeals);
      nextMeals[mealIndex] = imageChanged
          ? currentMeal.copyWith(
              name: trimmedName,
              imageAssetId: normalizedImageAssetId,
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
    if (consumedPortions < 1) {
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
      if (meal.hasPendingRecipeIngredients) {
        return false;
      }
      if (consumedPortions > meal.remainingPortions) {
        return false;
      }

      final nextMeals = _applyPortionReduction(
        currentMeals: currentMeals,
        mealIndex: mealIndex,
        consumedPortions: consumedPortions,
      );
      final savedMeals = await _saveMeals(
        previousMeals: currentMeals,
        nextMeals: nextMeals,
      );
      if (!savedMeals) {
        return false;
      }

      final calorieSaved = await ref
          .read(preparedMealCalorieLogBridgeProvider)
          .logConsumedPreparedMeal(
            meal: meal,
            consumedPortions: consumedPortions,
            mealType: mealType,
          );
      if (calorieSaved) {
        return true;
      }

      return _saveMeals(previousMeals: nextMeals, nextMeals: currentMeals);
    }).whenComplete(keepAliveLink.close);
  }

  Future<bool> throwAwayPreparedMeal({
    required String mealId,
    required int discardedPortions,
    required InventoryDiscardReason reason,
  }) {
    if (discardedPortions < 1) {
      log(
        'throwAwayPreparedMeal(): invalid discardedPortions=$discardedPortions',
        name: _preparedMealsControllerLogName,
      );
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(() async {
      log(
        'throwAwayPreparedMeal(): starting '
        '(mealId=$mealId, discardedPortions=$discardedPortions, '
        'reason=${reason.name})',
        name: _preparedMealsControllerLogName,
      );
      final currentMeals = await _currentMeals();
      final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
      if (mealIndex < 0) {
        log(
          'throwAwayPreparedMeal(): meal not found ($mealId)',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }

      final meal = currentMeals[mealIndex];
      if (discardedPortions > meal.remainingPortions) {
        log(
          'throwAwayPreparedMeal(): discardedPortions exceed remaining '
          '($discardedPortions > ${meal.remainingPortions})',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }

      final nextMeals = _applyPortionReduction(
        currentMeals: currentMeals,
        mealIndex: mealIndex,
        consumedPortions: discardedPortions,
      );
      final savedMeals = await _saveMeals(
        previousMeals: currentMeals,
        nextMeals: nextMeals,
      );
      if (!savedMeals) {
        log(
          'throwAwayPreparedMeal(): _saveMeals returned false',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }
      log(
        'throwAwayPreparedMeal(): prepared meals saved, persisting discard event',
        name: _preparedMealsControllerLogName,
      );

      final discardEvent = InventoryDiscardEvent.fromPreparedMeal(
        id: _uuid.v4(),
        meal: meal,
        discardedPortions: discardedPortions,
        reason: reason,
      );
      final eventSaved = await ref
          .read(inventoryDiscardEventRepositoryProvider)
          .saveEvent(discardEvent);
      if (eventSaved) {
        log(
          'throwAwayPreparedMeal(): discard event saved (${discardEvent.id})',
          name: _preparedMealsControllerLogName,
        );
        return true;
      }

      log(
        'throwAwayPreparedMeal(): discard event save failed, '
        'restoring previous meal state',
        name: _preparedMealsControllerLogName,
      );
      await _saveMeals(previousMeals: nextMeals, nextMeals: currentMeals);
      return false;
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
      final saved = await ref
          .read(preparedMealRepositoryProvider)
          .saveAll(nextMeals);
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

  Future<PreparedMealCreationResult> _persistCreatedMeal({
    required InventoryItemRepository inventoryRepository,
    required List<PreparedMeal> currentMeals,
    required List<InventoryItem> currentItems,
    required _PreparedMealCreationResult creationResult,
  }) async {
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
      return PreparedMealCreationResult.success(creationResult.preparedMeal.id);
    }

    await _restoreInventory(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
    );
    return const PreparedMealCreationResult.failure(
      PreparedMealCreationFailureReason.mealSaveFailed,
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

_PreparedMealCreationResult _buildMealCreationResult({
  required List<InventoryItem> currentItems,
  required String name,
  required String? imageAssetId,
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
      imageAssetId: _normalizeOptionalImageAssetId(imageAssetId),
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

_PreparedMealCreationResult _buildMealCreationFromTemplateResult({
  required List<InventoryItem> currentItems,
  required PreparedMeal template,
  required int totalPortions,
  required Map<String, List<String>> recipeIngredientAssignments,
}) {
  final activeIngredients = template.recipeIngredients
      .where(
        (ingredient) => !template.ignoredRecipeIngredients.contains(ingredient),
      )
      .toList(growable: false);
  if (activeIngredients.isEmpty) {
    throw const _PreparedMealCreationException(
      PreparedMealCreationFailureReason.invalidInput,
    );
  }

  final now = DateTime.now();
  final nextItems = List<InventoryItem>.from(currentItems);
  final components = <PreparedMealComponent>[];
  final pendingIngredients = <String>[];

  for (final ingredient in activeIngredients) {
    final assignedItemIds =
        recipeIngredientAssignments[ingredient] ?? const <String>[];
    if (assignedItemIds.isEmpty) {
      pendingIngredients.add(ingredient);
      continue;
    }

    final requirement = _parseTemplateIngredientRequirement(
      ingredient: ingredient,
      selectedPortions: totalPortions,
      basePortions: template.totalPortions,
    );
    if (requirement == null) {
      pendingIngredients.add(ingredient);
      continue;
    }

    var remainingAmount = requirement.amount;
    var consumedAnyAmount = false;
    var ingredientNeedsAttention = false;
    for (final itemId in assignedItemIds) {
      if (remainingAmount <= 0) {
        break;
      }

      final itemIndex = nextItems.indexWhere((item) => item.id == itemId);
      if (itemIndex < 0) {
        continue;
      }

      final currentItem = nextItems[itemIndex];
      if (!_hasCompatibleTemplateRequirement(
        item: currentItem,
        requiredUnit: requirement.unit,
      )) {
        continue;
      }

      final resolvedNutrition =
          currentItem.nutrition ??
          const GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.missing,
          );
      final hasCompleteNutrition = _hasCompleteNutrition(currentItem.nutrition);
      final consumableAmount = _consumableAmountForRequirement(
        item: currentItem,
        requiredUnit: requirement.unit,
        remainingAmount: remainingAmount,
      );
      if (consumableAmount < 1) {
        continue;
      }

      final nextItem = _reduceInventoryItem(
        item: currentItem,
        amount: consumableAmount,
      );
      if (nextItem == null) {
        continue;
      }

      final usedUnit = _resolveTemplateUsedUnit(
        item: currentItem,
        requiredUnit: requirement.unit,
      );
      nextItems[itemIndex] = nextItem;
      components.add(
        _buildPreparedMealComponent(
          item: currentItem,
          usedAmount: consumableAmount,
          usedUnit: usedUnit,
          nutrition: resolvedNutrition,
        ),
      );
      remainingAmount = _remainingRequirementAfterConsumption(
        item: currentItem,
        requiredUnit: requirement.unit,
        remainingAmount: remainingAmount,
        consumedAmount: consumableAmount,
      );
      consumedAnyAmount = true;
      if (!hasCompleteNutrition) {
        ingredientNeedsAttention = true;
      }
    }

    if (!consumedAnyAmount || remainingAmount > 0 || ingredientNeedsAttention) {
      pendingIngredients.add(ingredient);
    }
  }

  if (components.isEmpty) {
    throw const _PreparedMealCreationException(
      PreparedMealCreationFailureReason.invalidInput,
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
      name: template.name,
      imageAssetId: _normalizeOptionalImageAssetId(template.imageAssetId),
      imageUrl: template.imageUrl,
      recipeUrl: template.recipeUrl,
      recipeIngredients: template.recipeIngredients,
      ignoredRecipeIngredients: template.ignoredRecipeIngredients,
      recipeIngredientAssignments: recipeIngredientAssignments,
      pendingRecipeIngredients: pendingIngredients,
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

class _TemplateIngredientRequirement {
  const _TemplateIngredientRequirement({
    required this.amount,
    required this.unit,
  });

  final int amount;
  final InventoryAmountUnit unit;
}

_TemplateIngredientRequirement? _parseTemplateIngredientRequirement({
  required String ingredient,
  required int selectedPortions,
  required int basePortions,
}) {
  if (selectedPortions < 1 || basePortions < 1) {
    return null;
  }

  final trimmed = ingredient.trim();
  final match = RegExp(
    r'^(\d+(?:[.,]\d+)?|\d+/\d+)\s+(.+)$',
  ).firstMatch(trimmed);
  if (match == null) {
    return null;
  }

  final rawQuantity = match.group(1);
  final rawTail = match.group(2);
  if (rawQuantity == null || rawTail == null) {
    return null;
  }

  final parsedQuantity = _parseIngredientQuantity(rawQuantity);
  if (parsedQuantity == null || parsedQuantity <= 0) {
    return null;
  }

  final conversion = _resolveTemplateIngredientUnitConversion(rawTail);
  final scaledQuantity =
      parsedQuantity * conversion.multiplier * selectedPortions / basePortions;
  final roundedAmount = scaledQuantity.round();
  if (roundedAmount < 1) {
    return null;
  }

  return _TemplateIngredientRequirement(
    amount: roundedAmount,
    unit: conversion.unit,
  );
}

double? _parseIngredientQuantity(String rawValue) {
  final normalized = rawValue.trim().replaceAll(',', '.');
  if (normalized.contains('/')) {
    final parts = normalized.split('/');
    if (parts.length != 2) {
      return null;
    }
    final numerator = double.tryParse(parts[0]);
    final denominator = double.tryParse(parts[1]);
    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }
    return numerator / denominator;
  }
  return double.tryParse(normalized);
}

({InventoryAmountUnit unit, double multiplier})
_resolveTemplateIngredientUnitConversion(String rawTail) {
  final tokens = rawTail.split(RegExp(r'\s+'));
  final normalizedToken = tokens.isEmpty
      ? null
      : tokens.first.trim().toLowerCase();
  const unitConversions =
      <String, ({InventoryAmountUnit unit, double multiplier})>{
        'g': (unit: InventoryAmountUnit.gram, multiplier: 1),
        'gr': (unit: InventoryAmountUnit.gram, multiplier: 1),
        'gramm': (unit: InventoryAmountUnit.gram, multiplier: 1),
        'gram': (unit: InventoryAmountUnit.gram, multiplier: 1),
        'kg': (unit: InventoryAmountUnit.gram, multiplier: 1000),
        'kilogramm': (unit: InventoryAmountUnit.gram, multiplier: 1000),
        'kilogram': (unit: InventoryAmountUnit.gram, multiplier: 1000),
        'ml': (unit: InventoryAmountUnit.milliliter, multiplier: 1),
        'cl': (unit: InventoryAmountUnit.milliliter, multiplier: 10),
        'dl': (unit: InventoryAmountUnit.milliliter, multiplier: 100),
        'l': (unit: InventoryAmountUnit.milliliter, multiplier: 1000),
        'liter': (unit: InventoryAmountUnit.milliliter, multiplier: 1000),
        'litre': (unit: InventoryAmountUnit.milliliter, multiplier: 1000),
      };

  if (normalizedToken != null) {
    final conversion = unitConversions[normalizedToken];
    if (conversion != null) {
      return conversion;
    }
  }

  return (unit: InventoryAmountUnit.piece, multiplier: 1);
}

bool _hasCompatibleAmountUnit({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
}) {
  if (requiredUnit == InventoryAmountUnit.piece) {
    return !item.usesAmountProgress;
  }
  return item.usesAmountProgress && item.amountUnit == requiredUnit;
}

bool _hasCompatibleTemplateRequirement({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
}) {
  if (requiredUnit == InventoryAmountUnit.piece) {
    return _availableAmount(item) > 0;
  }
  return _hasCompatibleAmountUnit(item: item, requiredUnit: requiredUnit);
}

int _consumableAmountForRequirement({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
  required int remainingAmount,
}) {
  if (remainingAmount < 1) {
    return 0;
  }

  final availableAmount = _availableAmount(item);
  if (availableAmount < 1) {
    return 0;
  }

  if (requiredUnit == InventoryAmountUnit.piece && item.usesAmountProgress) {
    return availableAmount;
  }
  if (requiredUnit != InventoryAmountUnit.piece &&
      item.amountUnit != requiredUnit) {
    return 0;
  }
  return remainingAmount < availableAmount ? remainingAmount : availableAmount;
}

InventoryAmountUnit _resolveTemplateUsedUnit({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
}) {
  if (requiredUnit == InventoryAmountUnit.piece && item.usesAmountProgress) {
    return item.amountUnit ?? InventoryAmountUnit.piece;
  }
  return requiredUnit;
}

int _remainingRequirementAfterConsumption({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
  required int remainingAmount,
  required int consumedAmount,
}) {
  if (requiredUnit == InventoryAmountUnit.piece && item.usesAmountProgress) {
    return remainingAmount - 1;
  }
  return remainingAmount - consumedAmount;
}

String? _normalizeOptionalImageAssetId(String? value) {
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
