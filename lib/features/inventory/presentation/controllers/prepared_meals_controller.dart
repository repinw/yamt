import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_household_recovery.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_service.dart';
import 'package:yamt/features/inventory/application/prepared_meal_pending_ingredient_support.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

export 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart'
    show
        PreparedMealContainerInput,
        PreparedMealCreationFailureReason,
        PreparedMealCreationResult,
        PreparedMealItemInput;

part 'prepared_meals_controller.g.dart';

const _preparedMealsControllerLogName = 'PreparedMealsController';

/// Defines prepared meals controller.
@riverpod
class PreparedMealsController extends _$PreparedMealsController {
  // Subscription is cancelled by `_disposeSubscription`.
  // ignore: cancel_subscriptions
  StreamSubscription<List<PreparedMeal>>? _mealsSubscription;
  int _subscriptionGeneration = 0;
  String? _currentDataOwnerUserId;
  bool _isRecoveringHouseholdAccess = false;

  @override
  FutureOr<List<PreparedMeal>> build() async {
    ref
      ..watch(householdDataOwnerUserIdProvider)
      ..watch(preparedMealRepositoryProvider)
      ..onDispose(() {
        unawaited(_disposeSubscription());
      });
    await waitForHouseholdDataOwnerProfile(ref);
    if (!ref.mounted) {
      return const <PreparedMeal>[];
    }
    _currentDataOwnerUserId = ref.watch(activeHouseholdIdProvider);
    return await _restartSubscription();
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

  /// Creates a meal from explicit Vorrat selections.
  Future<PreparedMealCreationResult> createPreparedMeal({
    required String name,
    required int totalPortions,
    required List<PreparedMealItemInput> items,
    String? imageAssetId,
  }) => _keptAlive(
    (service) => service.createPreparedMeal(
      name: name,
      totalPortions: totalPortions,
      items: items,
      imageAssetId: imageAssetId,
    ),
    failed: const PreparedMealCreationResult.failure(
      PreparedMealCreationFailureReason.mealSaveFailed,
    ),
  );

  /// Changes a meal's name, image, portions or ingredients.
  Future<bool> updatePreparedMealDetails({
    required String mealId,
    required String name,
    bool imageChanged = false,
    String? imageAssetId,
    int? totalPortions,
    List<PreparedMealItemInput>? items,
  }) => _keptAlive(
    (service) => service.updatePreparedMealDetails(
      mealId: mealId,
      name: name,
      imageChanged: imageChanged,
      imageAssetId: imageAssetId,
      totalPortions: totalPortions,
      items: items,
    ),
    failed: false,
  );

  /// Fills the open row [ingredient] with the Vorrat items [inventoryItemIds].
  Future<bool> fillPreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
    required List<String> inventoryItemIds,
  }) => _keptAlive(
    (service) => service.fillPreparedMealPendingIngredient(
      mealId: mealId,
      ingredient: ingredient,
      inventoryItemIds: inventoryItemIds,
    ),
    failed: false,
  );

  /// The best item of [inventoryItems] that can fill the open row
  /// [ingredient] with the row's own amount.
  InventoryItem? pendingIngredientStockMatch({
    required String ingredient,
    required List<InventoryItem> inventoryItems,
    required String localeCode,
  }) {
    return findPendingIngredientStockMatch(
      ingredient: ingredient,
      inventoryItems: inventoryItems,
      ingredientParser: ref.read(templateIngredientParserProvider),
      localeCode: localeCode,
    );
  }

  /// Fills the open row [ingredient] with [usedAmount] of the item [itemId].
  Future<bool> fillPreparedMealPendingIngredientWithItem({
    required String mealId,
    required String ingredient,
    required String itemId,
    required int usedAmount,
  }) => _keptAlive(
    (service) => service.fillPreparedMealPendingIngredientWithItem(
      mealId: mealId,
      ingredient: ingredient,
      itemId: itemId,
      usedAmount: usedAmount,
    ),
    failed: false,
  );

  /// Marks the open row [ingredient] as left out on purpose.
  Future<bool> ignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) => _keptAlive(
    (service) => service.ignorePreparedMealPendingIngredient(
      mealId: mealId,
      ingredient: ingredient,
    ),
    failed: false,
  );

  /// Throws away [discardedPortions] of a meal and records why.
  Future<bool> throwAwayPreparedMeal({
    required String mealId,
    required num discardedPortions,
    required InventoryDiscardReason reason,
  }) => _keptAlive(
    (service) => service.throwAwayPreparedMeal(
      mealId: mealId,
      discardedPortions: discardedPortions,
      reason: reason,
    ),
    failed: false,
  );

  /// Gives the remaining ingredients of a meal back to the Vorrat.
  Future<bool> unbundlePreparedMeal(String mealId) => _keptAlive(
    (service) => service.unbundlePreparedMeal(mealId),
    failed: false,
  );

  /// Runs [mutation] on the meal service and keeps this controller and the
  /// service alive until it completes. A thrown error is logged and ends as
  /// [failed].
  Future<T> _keptAlive<T>(
    Future<T> Function(PreparedMealMutationService service) mutation, {
    required T failed,
  }) async {
    final keepAliveLink = ref.keepAlive();
    final service = ref.listen(preparedMealMutationServiceProvider, (_, _) {});
    try {
      return await mutation(service.read());
    } on Object catch (error, stackTrace) {
      log(
        'Prepared meal change failed.',
        name: _preparedMealsControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return failed;
    } finally {
      service.close();
      keepAliveLink.close();
    }
  }

  Future<List<PreparedMeal>> _restartSubscription() async {
    final initialMeals = Completer<List<PreparedMeal>>();
    _currentDataOwnerUserId = ref.read(activeHouseholdIdProvider);
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

    return await initialMeals.future;
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
    return shouldRecoverPreparedMealHouseholdAccess(
      ref: ref,
      error: error,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
    );
  }

  Future<void> _recoverFromRevokedHouseholdAccess({bool showLoading = true}) {
    return recoverPreparedMealHouseholdAccess(
      ref: ref,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      setIsRecoveringHouseholdAccess: ({required value}) {
        _isRecoveringHouseholdAccess = value;
      },
      setState: (nextState) {
        state = nextState;
      },
      restartSubscription: _restartSubscription,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
      logName: _preparedMealsControllerLogName,
      showLoading: showLoading,
    );
  }
}
