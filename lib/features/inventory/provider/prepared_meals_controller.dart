import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/household/provider/'
    'household_access_recovery_utils.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/application/'
    'recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
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

/// Defines prepared meal creation failure reason.
enum PreparedMealCreationFailureReason {
  /// Documented member.
  invalidInput,

  /// Documented member.
  itemUnavailable,

  /// Documented member.
  insufficientAmount,

  /// Documented member.
  missingNutrition,

  /// Documented member.
  inventorySaveFailed,

  /// Documented member.
  mealSaveFailed,
}

/// Defines prepared meal creation result.
class PreparedMealCreationResult {
  const PreparedMealCreationResult._({
    required this.isSuccess,
    this.preparedMealId,
    this.failureReason,
  });

  /// Creates a [PreparedMealCreationResult] for success.
  const PreparedMealCreationResult.success(String preparedMealId)
    : this._(isSuccess: true, preparedMealId: preparedMealId);

  /// Creates a [PreparedMealCreationResult] for failure.
  const PreparedMealCreationResult.failure(
    PreparedMealCreationFailureReason reason,
  ) : this._(isSuccess: false, failureReason: reason);

  /// Whether success.
  final bool isSuccess;

  /// The prepared meal id.
  final String? preparedMealId;

  /// The failure reason.
  final PreparedMealCreationFailureReason? failureReason;
}

class _PreparedMealCreationException implements Exception {
  const _PreparedMealCreationException(this.reason);

  final PreparedMealCreationFailureReason reason;
}

/// Defines prepared meal item input.
class PreparedMealItemInput {
  /// The prepared meal item input.
  const PreparedMealItemInput({
    required this.itemId,
    required this.usedAmount,
    this.manualNutrition,
  });

  /// The item id.
  final String itemId;

  /// The used amount.
  final int usedAmount;

  /// The manual nutrition.
  final GlobalFoodNutrition? manualNutrition;
}

extension _PreparedMealComponentNutritionTotals
    on Iterable<PreparedMealComponent> {
  ({double totalCarbs, double totalFat, double totalKcal, double totalProtein})
  get nutritionTotals {
    return fold(
      (totalCarbs: 0.0, totalFat: 0.0, totalKcal: 0.0, totalProtein: 0.0),
      (totals, component) => (
        totalCarbs: totals.totalCarbs + component.totalCarbs,
        totalFat: totals.totalFat + component.totalFat,
        totalKcal: totals.totalKcal + component.totalKcal,
        totalProtein: totals.totalProtein + component.totalProtein,
      ),
    );
  }
}

/// Defines prepared meals controller.
@riverpod
class PreparedMealsController extends _$PreparedMealsController {
  static const _uuid = Uuid();

  StreamSubscription<List<PreparedMeal>>? _mealsSubscription;
  int _subscriptionGeneration = 0;
  final _mutationQueue = SerializedMutationQueue();
  String? _currentDataOwnerUserId;
  bool _isRecoveringHouseholdAccess = false;

  @override
  FutureOr<List<PreparedMeal>> build() {
    ref.watch(householdDataOwnerUserIdProvider);
    _currentDataOwnerUserId = ref.watch(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
    ref.watch(preparedMealRepositoryProvider);
    ref.onDispose(() {
      unawaited(_disposeSubscription());
    });
    return _restartSubscription();
  }

  /// Refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_restartSubscription);
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// Create prepared meal.
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

  /// Create prepared meal from template.
  Future<PreparedMealCreationResult> createPreparedMealFromTemplate({
    required PreparedMeal template,
    required int totalPortions,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
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
            final ingredientParser = ref.read(templateIngredientParserProvider);
            final currentMeals = await _currentMeals();
            final currentItems = await inventoryRepository.readAll();

            try {
              final creationResult = _buildMealCreationFromTemplateResult(
                currentItems: currentItems,
                template: template,
                totalPortions: totalPortions,
                recipeIngredientAssignments: recipeIngredientAssignments,
                recipeIngredientAmountConversions:
                    recipeIngredientAmountConversions,
                ingredientParser: ingredientParser,
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

  /// Update prepared meal details.
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

  /// Fill prepared meal pending ingredient.
  Future<bool> fillPreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
    required List<String> inventoryItemIds,
  }) {
    final trimmedIngredient = ingredient.trim();
    final normalizedItemIds = inventoryItemIds
        .map((itemId) => itemId.trim())
        .where((itemId) => itemId.isNotEmpty)
        .toList(growable: false);
    if (trimmedIngredient.isEmpty || normalizedItemIds.isEmpty) {
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(() async {
      final ingredientParser = ref.read(templateIngredientParserProvider);
      final currentMeals = await _currentMeals();
      final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
      if (mealIndex < 0) {
        return false;
      }

      final currentMeal = currentMeals[mealIndex];
      final pendingIndex = currentMeal.pendingRecipeIngredients.indexWhere(
        (entry) => entry.trim() == trimmedIngredient,
      );
      if (pendingIndex < 0) {
        return false;
      }

      final inventoryRepository = ref.read(inventoryItemRepositoryProvider);
      final currentItems = await inventoryRepository.readAll();
      final fillResult = _buildPendingIngredientFillResult(
        currentItems: currentItems,
        ingredient: trimmedIngredient,
        inventoryItemIds: normalizedItemIds,
        ingredientParser: ingredientParser,
      );
      if (fillResult == null) {
        return false;
      }

      final inventorySaved = await inventoryRepository.saveAll(
        fillResult.nextItems,
      );
      if (!inventorySaved) {
        return false;
      }

      final nextPendingIngredients = List<String>.from(
        currentMeal.pendingRecipeIngredients,
      )..removeAt(pendingIndex);
      if (fillResult.remainingIngredient != null) {
        nextPendingIngredients.insert(
          pendingIndex,
          fillResult.remainingIngredient!,
        );
      }

      final nextComponents = <PreparedMealComponent>[
        ...currentMeal.components,
        ...fillResult.components,
      ];
      final nutritionTotals = nextComponents.nutritionTotals;
      final nextMeal = currentMeal.copyWith(
        components: nextComponents,
        pendingRecipeIngredients: nextPendingIngredients,
        totalKcal: nutritionTotals.totalKcal,
        totalProtein: nutritionTotals.totalProtein,
        totalCarbs: nutritionTotals.totalCarbs,
        totalFat: nutritionTotals.totalFat,
        updatedAt: DateTime.now(),
      );

      final nextMeals = List<PreparedMeal>.from(currentMeals);
      nextMeals[mealIndex] = nextMeal;
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

  /// Ignore prepared meal pending ingredient.
  Future<bool> ignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) {
    final trimmedIngredient = ingredient.trim();
    if (trimmedIngredient.isEmpty) {
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
      final nextPendingIngredients = currentMeal.pendingRecipeIngredients
          .where((entry) => entry.trim() != trimmedIngredient)
          .toList(growable: false);
      if (nextPendingIngredients.length ==
          currentMeal.pendingRecipeIngredients.length) {
        return false;
      }

      final nextMeals = List<PreparedMeal>.from(currentMeals);
      nextMeals[mealIndex] = currentMeal.copyWith(
        pendingRecipeIngredients: nextPendingIngredients,
        updatedAt: DateTime.now(),
      );
      return _saveMeals(previousMeals: currentMeals, nextMeals: nextMeals);
    }).whenComplete(keepAliveLink.close);
  }

  /// Consume prepared meal.
  Future<bool> consumePreparedMeal({
    required String mealId,
    required int consumedPortions,
    required MealType mealType,
    DateTime? loggedDay,
  }) {
    if (consumedPortions < 1) {
      log(
        'consumePreparedMeal(): invalid consumedPortions=$consumedPortions '
        '(mealId=$mealId)',
        name: _preparedMealsControllerLogName,
      );
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(() async {
      final currentMeals = await _currentMeals();
      final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
      if (mealIndex < 0) {
        log(
          'consumePreparedMeal(): meal not found ($mealId)',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }

      final meal = currentMeals[mealIndex];
      log(
        'consumePreparedMeal(): starting '
        '(mealId=$mealId, consumedPortions=$consumedPortions, '
        'remainingPortions=${meal.remainingPortions}, '
        'totalPortions=${meal.totalPortions}, '
        'mealType=${mealType.name}, '
        'loggedDay=${loggedDay?.toIso8601String()})',
        name: _preparedMealsControllerLogName,
      );
      if (meal.hasPendingRecipeIngredients) {
        log(
          'consumePreparedMeal(): meal has pending recipe ingredients '
          '(mealId=$mealId)',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }
      if (consumedPortions > meal.remainingPortions) {
        log(
          'consumePreparedMeal(): consumedPortions exceed remaining '
          '($consumedPortions > ${meal.remainingPortions}) '
          '(mealId=$mealId)',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }
      if (consumedPortions == meal.remainingPortions) {
        log(
          'consumePreparedMeal(): meal will be fully depleted and kept '
          'with zero remaining portions (mealId=$mealId)',
          name: _preparedMealsControllerLogName,
        );
      }

      final nextMeals = _applyPortionReduction(
        currentMeals: currentMeals,
        mealIndex: mealIndex,
        removedPortions: consumedPortions,
        keepDepletedMeal: true,
      );
      return ref
          .read(preparedMealCalorieLogBridgeProvider)
          .consumePreparedMeal(
            currentMeals: currentMeals,
            nextMeals: nextMeals,
            meal: meal,
            consumedPortions: consumedPortions,
            mealType: mealType,
            loggedDay: loggedDay,
            publishMeals: (meals) {
              if (!ref.mounted) {
                return;
              }
              state = AsyncData(meals);
            },
            saveMeals: (previousMeals, nextMeals) {
              return _saveMeals(
                previousMeals: previousMeals,
                nextMeals: nextMeals,
              );
            },
          );
    }).whenComplete(keepAliveLink.close);
  }

  /// Throw away prepared meal.
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
        removedPortions: discardedPortions,
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

  /// Restore prepared meal portions.
  Future<bool> restorePreparedMealPortions({
    required String mealId,
    required int portions,
  }) {
    if (portions < 1) {
      log(
        'restorePreparedMealPortions(): invalid portions=$portions '
        '(mealId=$mealId)',
        name: _preparedMealsControllerLogName,
      );
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(() async {
      log(
        'restorePreparedMealPortions(): starting '
        '(mealId=$mealId, portions=$portions)',
        name: _preparedMealsControllerLogName,
      );
      final currentMeals = await _currentMeals();
      final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
      if (mealIndex < 0) {
        log(
          'restorePreparedMealPortions(): meal not found '
          '(mealId=$mealId, portions=$portions, '
          'knownMeals=${currentMeals.length})',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }

      final meal = currentMeals[mealIndex];
      final nextRemainingPortions = meal.remainingPortions + portions;
      if (nextRemainingPortions > meal.totalPortions) {
        log(
          'restorePreparedMealPortions(): restore exceeds total portions '
          '(mealId=$mealId, nextRemaining=$nextRemainingPortions, '
          'totalPortions=${meal.totalPortions})',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }

      final nextMeals = List<PreparedMeal>.from(currentMeals);
      nextMeals[mealIndex] = meal.copyWith(
        remainingPortions: nextRemainingPortions,
        updatedAt: DateTime.now(),
      );
      final saved = await _saveMeals(
        previousMeals: currentMeals,
        nextMeals: nextMeals,
      );
      if (!saved) {
        log(
          'restorePreparedMealPortions(): failed to save restored '
          'portions (mealId=$mealId)',
          name: _preparedMealsControllerLogName,
        );
        return false;
      }

      log(
        'restorePreparedMealPortions(): succeeded '
        '(mealId=$mealId, remainingPortions=${meal.remainingPortions}, '
        'nextRemainingPortions=$nextRemainingPortions)',
        name: _preparedMealsControllerLogName,
      );
      return true;
    }).whenComplete(keepAliveLink.close);
  }

  /// Unbundle prepared meal.
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

  Future<List<PreparedMeal>> _restartSubscription() async {
    final initialMeals = Completer<List<PreparedMeal>>();
    _currentDataOwnerUserId = ref.read(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
    final repository = ref.read(preparedMealRepositoryProvider);
    final generation = ++_subscriptionGeneration;
    await _disposeSubscription();

    _mealsSubscription = repository.watchAll().listen(
      (meals) {
        if (generation != _subscriptionGeneration) {
          return;
        }
        if (!initialMeals.isCompleted) {
          initialMeals.complete(meals);
          return;
        }
        _onRealtimeMeals(meals);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (generation != _subscriptionGeneration) {
          return;
        }
        if (!initialMeals.isCompleted) {
          if (_shouldRecoverFromRevokedHouseholdAccess(error)) {
            initialMeals.complete(const <PreparedMeal>[]);
            unawaited(_recoverFromRevokedHouseholdAccess(showLoading: false));
            return;
          }
          initialMeals.completeError(error, stackTrace);
          return;
        }
        _onRealtimeError(error, stackTrace);
      },
    );

    return initialMeals.future;
  }

  Future<void> _disposeSubscription() async {
    final currentSubscription = _mealsSubscription;
    _mealsSubscription = null;
    if (currentSubscription != null) {
      await currentSubscription.cancel();
    }
  }

  void _onRealtimeMeals(List<PreparedMeal> meals) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(meals);
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    if (_shouldRecoverFromRevokedHouseholdAccess(error)) {
      unawaited(_recoverFromRevokedHouseholdAccess());
      return;
    }
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }

  bool _shouldRecoverFromRevokedHouseholdAccess(Object error) {
    return shouldRecoverControllerHouseholdAccess(
      ref: ref,
      error: error,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
    );
  }

  Future<void> _recoverFromRevokedHouseholdAccess({bool showLoading = true}) {
    return recoverControllerHouseholdAccess<PreparedMeal>(
      ref: ref,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      setIsRecoveringHouseholdAccess: (value) {
        _isRecoveringHouseholdAccess = value;
      },
      setState: (nextState) {
        state = nextState;
      },
      restartHouseholdScopedSubscription: _restartSubscription,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
      householdAccessRecoveryLogName: _preparedMealsControllerLogName,
      householdAccessRecoveryMessage:
          'Rebuilding prepared meal stream after household access changed.',
      showLoading: showLoading,
    );
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

class _PendingIngredientFillResult {
  const _PendingIngredientFillResult({
    required this.nextItems,
    required this.components,
    this.remainingIngredient,
  });

  final List<InventoryItem> nextItems;
  final List<PreparedMealComponent> components;
  final String? remainingIngredient;
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

  final nutritionTotals = components.nutritionTotals;

  return _PreparedMealCreationResult(
    nextItems: nextItems,
    preparedMeal: PreparedMeal(
      id: PreparedMealsController._uuid.v4(),
      name: name,
      imageAssetId: _normalizeOptionalImageAssetId(imageAssetId),
      totalPortions: totalPortions,
      remainingPortions: totalPortions,
      totalKcal: nutritionTotals.totalKcal,
      totalProtein: nutritionTotals.totalProtein,
      totalCarbs: nutritionTotals.totalCarbs,
      totalFat: nutritionTotals.totalFat,
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
  required Map<String, RecipeIngredientAmountConversion>
  recipeIngredientAmountConversions,
  required TemplateIngredientParser ingredientParser,
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
      pendingIngredients.add(
        ingredientParser.pendingIngredientLabel(
          originalIngredient: ingredient,
          requirement: ingredientParser.parseRequirement(
            ingredient: ingredient,
            selectedPortions: totalPortions,
            basePortions: template.totalPortions,
          ),
        ),
      );
      continue;
    }

    final requirement = ingredientParser.parseRequirement(
      ingredient: ingredient,
      selectedPortions: totalPortions,
      basePortions: template.totalPortions,
    );
    if (requirement == null) {
      pendingIngredients.add(ingredient.trim());
      continue;
    }

    final assignedItems = resolveInventoryItemsById(
      inventoryItemIds: assignedItemIds,
      inventoryItems: nextItems,
    );
    final effectiveRequirement = resolveEffectiveRequirementForItems(
      requirement: requirement,
      assignedItems: assignedItems,
      amountConversion: _assignmentAmountConversionForIngredient(
        recipeIngredientAmountConversions,
        ingredient,
      ),
    );
    if (effectiveRequirement == null) {
      pendingIngredients.add(
        ingredientParser.pendingIngredientLabel(
          originalIngredient: ingredient,
          requirement: requirement,
        ),
      );
      continue;
    }

    var remainingAmount = effectiveRequirement.amount;
    var consumedAnyAmount = false;
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
        requiredUnit: effectiveRequirement.unit,
      )) {
        continue;
      }

      final resolvedNutrition =
          currentItem.nutrition ??
          const GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.missing,
          );
      final consumableAmount = _consumableAmountForRequirement(
        item: currentItem,
        requiredUnit: effectiveRequirement.unit,
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
        requiredUnit: effectiveRequirement.unit,
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
        requiredUnit: effectiveRequirement.unit,
        remainingAmount: remainingAmount,
        consumedAmount: consumableAmount,
      );
      consumedAnyAmount = true;
    }

    if (!consumedAnyAmount) {
      pendingIngredients.add(
        ingredientParser.pendingIngredientLabel(
          originalIngredient: ingredient,
          requirement: requirement,
        ),
      );
      continue;
    }

    if (remainingAmount > 0) {
      pendingIngredients.add(
        ingredientParser.formatPendingIngredient(
          amount: remainingAmount,
          unit: effectiveRequirement.unit,
          name: effectiveRequirement.name,
        ),
      );
    }
  }

  final nutritionTotals = components.nutritionTotals;

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
      recipeIngredientAmountConversions: recipeIngredientAmountConversions,
      pendingRecipeIngredients: pendingIngredients,
      totalPortions: totalPortions,
      remainingPortions: totalPortions,
      totalKcal: nutritionTotals.totalKcal,
      totalProtein: nutritionTotals.totalProtein,
      totalCarbs: nutritionTotals.totalCarbs,
      totalFat: nutritionTotals.totalFat,
      createdAt: now,
      updatedAt: now,
      components: components,
    ),
  );
}

_PendingIngredientFillResult? _buildPendingIngredientFillResult({
  required List<InventoryItem> currentItems,
  required String ingredient,
  required List<String> inventoryItemIds,
  required TemplateIngredientParser ingredientParser,
}) {
  final requirement = ingredientParser.parseRequirement(
    ingredient: ingredient,
    selectedPortions: 1,
    basePortions: 1,
  );
  if (requirement == null) {
    return null;
  }

  final nextItems = List<InventoryItem>.from(currentItems);
  final components = <PreparedMealComponent>[];
  var remainingAmount = requirement.amount;
  var consumedAnyAmount = false;

  for (final itemId in inventoryItemIds) {
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

    final resolvedNutrition =
        currentItem.nutrition ??
        const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.missing,
        );
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
  }

  if (!consumedAnyAmount || components.isEmpty) {
    return null;
  }

  return _PendingIngredientFillResult(
    nextItems: nextItems,
    components: components,
    remainingIngredient: remainingAmount > 0
        ? ingredientParser.formatPendingIngredient(
            amount: remainingAmount,
            unit: requirement.unit,
            name: requirement.name,
          )
        : null,
  );
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

RecipeIngredientAmountConversion? _assignmentAmountConversionForIngredient(
  Map<String, RecipeIngredientAmountConversion> conversions,
  String ingredient,
) {
  final normalizedIngredient = ingredient.trim();
  if (normalizedIngredient.isEmpty) {
    return null;
  }
  return conversions[normalizedIngredient];
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
  required int removedPortions,
  bool keepDepletedMeal = false,
}) {
  final currentMeal = currentMeals[mealIndex];
  final nextRemainingPortions = currentMeal.remainingPortions - removedPortions;
  final nextMeals = List<PreparedMeal>.from(currentMeals);
  if (nextRemainingPortions <= 0 && !keepDepletedMeal) {
    nextMeals.removeAt(mealIndex);
    return nextMeals;
  }

  nextMeals[mealIndex] = currentMeal.copyWith(
    remainingPortions: nextRemainingPortions < 0 ? 0 : nextRemainingPortions,
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
