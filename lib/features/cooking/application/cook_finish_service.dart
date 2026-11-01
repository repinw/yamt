import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cooking/domain/cook_recipe.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/inventory/application/prepared_meal_from_items.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'cook_finish_service.g.dart';

/// The service that ends a cooking with "In Vorrat".
@riverpod
CookFinishService cookFinishService(Ref ref) {
  return CookFinishService(
    inventory: ref.watch(inventoryItemRepositoryProvider),
    meals: ref.watch(cookedMealRepositoryProvider),
    clock: ref.watch(clockProvider),
  );
}

/// Puts a cooked meal into the Vorrat and takes its stock, in one write.
class CookFinishService {
  /// Creates the service.
  const new({
    required this._inventory,
    required this._meals,
    required this._clock,
  });

  final InventoryItemRepository _inventory;
  final CookedMealRepository _meals;
  final DateTime Function() _clock;

  /// Builds the meal of [session] from the Vorrat as it is now and writes
  /// it with its stock. Throws a [PreparedMealBuildException] when an item
  /// is gone, holds too little, or lacks nutrition, and rethrows a failed
  /// write; then nothing is written.
  Future<PreparedMeal> finish({
    required CookRecipe recipe,
    required CookSession session,
    required CookPortioning portioning,
  }) async {
    final items = await _inventory.readAllForChange();
    final now = _clock();
    final built = buildCookedMeal(
      items: items,
      recipe: recipe,
      session: session,
      portioning: portioning,
      id: const Uuid().v4(),
      now: now,
    );
    final before = {for (final item in items) item.id: item};
    await _meals.addCookedMeal(
      meal: built.preparedMeal,
      changes: [
        for (final after in built.nextItems)
          if (before[after.id] case final item? when item != after)
            (before: item, after: after),
      ],
      happenedAt: now,
    );
    return built.preparedMeal;
  }
}

/// The meal [session] makes from [items], and the items after it took
/// their stock. Lines that take nothing, such as "Salz", add no food.
/// Throws a [PreparedMealBuildException] like [CookFinishService.finish],
/// with `invalidInput` when no line takes anything.
PreparedMealBuildResult buildCookedMeal({
  required List<InventoryItem> items,
  required CookRecipe recipe,
  required CookSession session,
  required CookPortioning portioning,
  required String id,
  required DateTime now,
}) {
  // One food per item, however many lines it supplies.
  final amounts = <String, int>{};
  for (final line in recipe.lines) {
    if (session.lineOf(line.id) case LineAssigned(:final takes)) {
      for (final take in takes) {
        if (take.amount > 0) {
          amounts[take.itemId] = (amounts[take.itemId] ?? 0) + take.amount;
        }
      }
    }
  }
  // A meal of nothing, every line left out or taking nothing, has no food.
  if (amounts.isEmpty) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.invalidInput,
    );
  }
  final name = portioning.name.trim();
  final built = buildPreparedMealCreationResult(
    currentItems: items,
    preparedMealId: id,
    now: now,
    name: name.isEmpty ? recipe.name : name,
    imageAssetId: recipe.imageAssetId,
    totalPortions: portioning.count,
    inputs: [
      for (final MapEntry(:key, :value) in amounts.entries)
        PreparedMealItemInput(itemId: key, usedAmount: value),
    ],
  );
  final emptyWeight = switch (session.pot) {
    CookPotUtensil(:final emptyWeight) => emptyWeight,
    _ => null,
  };
  final gross = portioning.grossWeight;
  final net = emptyWeight == null || gross == null ? null : gross - emptyWeight;
  return PreparedMealBuildResult(
    nextItems: built.nextItems,
    preparedMeal: built.preparedMeal.copyWith(
      imageUrl: recipe.imageUrl,
      potTareWeight: net == null ? null : emptyWeight,
      finalNetWeight: net,
      servedInPieces: portioning.inPieces ? true : null,
    ),
  );
}
