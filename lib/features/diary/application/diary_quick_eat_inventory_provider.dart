import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';

part 'diary_quick_eat_inventory_provider.g.dart';

/// Inventory foods available to the diary quick-eat flow.
@immutable
class DiaryQuickEatInventoryData {
  /// Creates quick-eat inventory data.
  const DiaryQuickEatInventoryData({
    required this.items,
    required this.meals,
  });

  /// Inventory items that can be eaten from the diary.
  final List<InventoryItem> items;

  /// Prepared meals that can be eaten from the diary.
  final List<PreparedMeal> meals;
}

/// Provides selectable inventory foods for the diary quick-eat picker.
@Riverpod(dependencies: [InventoryItemsController, PreparedMealsController])
Future<DiaryQuickEatInventoryData> diaryQuickEatInventory(Ref ref) async {
  final itemsFuture = ref.watch(inventoryItemsControllerProvider.future);
  final mealsFuture = ref.watch(preparedMealsControllerProvider.future);
  final items = await itemsFuture;
  final meals = await mealsFuture;

  return DiaryQuickEatInventoryData(
    items: items.where(canDiaryQuickEatInventoryItem).toList(growable: false),
    meals: meals.where((meal) => !meal.isDepleted).toList(growable: false),
  );
}

/// Provides inventory mutations used by diary quick-eat.
@Riverpod(dependencies: [InventoryItemsController, PreparedMealsController])
DiaryQuickEatInventoryActions diaryQuickEatInventoryActions(Ref ref) {
  return DiaryQuickEatInventoryActions(
    inventoryController: ref.read(inventoryItemsControllerProvider.notifier),
    preparedMealsController: ref.read(
      preparedMealsControllerProvider.notifier,
    ),
  );
}

/// Inventory actions needed by the diary quick-eat flow.
class DiaryQuickEatInventoryActions {
  /// Creates inventory actions.
  const DiaryQuickEatInventoryActions({
    required InventoryItemsController inventoryController,
    required PreparedMealsController preparedMealsController,
  }) : _inventoryController = inventoryController,
       _preparedMealsController = preparedMealsController;

  final InventoryItemsController _inventoryController;
  final PreparedMealsController _preparedMealsController;

  /// Stages inventory consumption and returns the pending consumption id.
  Future<String?> stageInventoryItemConsumption({
    required String itemId,
    required int amount,
  }) async {
    final pendingConsumption = await _inventoryController
        .stagePendingConsumption(itemId, amount);
    return pendingConsumption?.id;
  }

  /// Discards staged inventory consumption.
  Future<void> discardInventoryItemConsumption(
    String pendingConsumptionId,
  ) async {
    await _inventoryController.discardPendingConsumption(pendingConsumptionId);
  }

  /// Consumes one prepared meal from the diary.
  Future<bool> consumePreparedMeal({
    required String mealId,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  }) {
    return _preparedMealsController.consumePreparedMeal(
      mealId: mealId,
      consumedPortions: consumedPortions,
      mealType: mealType,
      loggedDay: loggedDay,
    );
  }
}

/// Whether an inventory item can be selected for diary quick eat.
@visibleForTesting
bool canDiaryQuickEatInventoryItem(InventoryItem item) {
  return maxDiaryQuickEatInventoryAmount(item) != null;
}

/// Maximum consumable inventory amount for diary quick eat.
int? maxDiaryQuickEatInventoryAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    if (item.amountUnit == null || item.currentAmount < 1) {
      return null;
    }
    return item.currentAmount;
  }
  if (item.quantity < 1) {
    return null;
  }
  return item.quantity;
}
