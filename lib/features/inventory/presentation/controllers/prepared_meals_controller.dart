import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/application/'
    'household_scoped_list_feed.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_service.dart';
import 'package:yamt/features/inventory/application/prepared_meal_pending_ingredients.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
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
  late final _feed = HouseholdScopedListFeed<PreparedMeal>(
    ref: () => ref,
    watch: () => ref.read(preparedMealRepositoryProvider).watchAll(),
    setState: (next) => state = next,
    logName: _preparedMealsControllerLogName,
    recoveryMessage:
        'Rebuilding prepared meal stream after household access changed.',
  );

  @override
  FutureOr<List<PreparedMeal>> build() async {
    ref
      ..watch(householdDataOwnerUserIdProvider)
      ..watch(preparedMealRepositoryProvider)
      ..onDispose(() {
        unawaited(_feed.close());
      });
    await waitForHouseholdDataOwnerProfile(ref);
    if (!ref.mounted) {
      return const <PreparedMeal>[];
    }
    ref.watch(activeHouseholdIdProvider);
    return await _feed.start();
  }

  /// Refresh.
  Future<void> refresh() => _feed.refresh();

  /// Creates a meal from explicit Vorrat selections.
  Future<PreparedMealCreationResult> createPreparedMeal({
    required String name,
    required int totalPortions,
    required List<PreparedMealItemInput> items,
    String? imageAssetId,
    bool startInPot = false,
  }) => _keptAlive(
    (service) => service.createPreparedMeal(
      name: name,
      totalPortions: totalPortions,
      items: items,
      imageAssetId: imageAssetId,
      startInPot: startInPot,
    ),
    failed: const PreparedMealCreationResult.failure(
      PreparedMealCreationFailureReason.mealSaveFailed,
    ),
  );

  /// Changes a meal's name, image, portions or ingredients. A food that
  /// [items] leaves out opens its row again; [deletedRows] leave the meal.
  Future<bool> updatePreparedMealDetails({
    required String mealId,
    required String name,
    bool imageChanged = false,
    String? imageAssetId,
    int? totalPortions,
    List<PreparedMealItemInput>? items,
    List<String> deletedRows = const <String>[],
  }) => _keptAlive(
    (service) => service.updatePreparedMealDetails(
      mealId: mealId,
      name: name,
      imageChanged: imageChanged,
      imageAssetId: imageAssetId,
      totalPortions: totalPortions,
      items: items,
      deletedRows: deletedRows,
    ),
    failed: false,
  );

  /// Puts the meal back as [previous] was before an edit.
  Future<bool> restorePreparedMeal(PreparedMeal previous) => _keptAlive(
    (service) => service.restorePreparedMeal(previous),
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

  /// Opens the ignored row [ingredient] again.
  Future<bool> unignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) => _keptAlive(
    (service) => service.unignorePreparedMealPendingIngredient(
      mealId: mealId,
      ingredient: ingredient,
    ),
    failed: false,
  );

  /// Takes [component] out of the meal [mealId]: its row opens again and its
  /// stock goes back to the Vorrat.
  Future<bool> unassignPreparedMealComponent({
    required String mealId,
    required PreparedMealComponent component,
  }) => _keptAlive(
    (service) => service.unassignPreparedMealComponent(
      mealId: mealId,
      component: component,
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

  /// Stores that [netWeight] grams of the cooked [meal] are left, with the
  /// portions [meal] has. Returns whether it worked.
  Future<bool> changePreparedMealWeight({
    required PreparedMeal meal,
    required int netWeight,
  }) => _keptAlive((service) async {
    await service.changeWeight(meal: meal, netWeight: netWeight);
    return true;
  }, failed: false);

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
}
