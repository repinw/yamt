import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_application.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'diary_quick_eat_inventory_provider.g.dart';

/// Inventory foods available to the diary quick-eat flow.
@immutable
class DiaryQuickEatInventoryData {
  /// Creates quick-eat inventory data.
  const new({required this.items, required this.meals});

  /// Inventory items that can be eaten from the diary.
  final List<InventoryItem> items;

  /// Prepared meals that can be eaten from the diary.
  final List<PreparedMeal> meals;
}

/// Provides selectable inventory foods for the diary quick-eat picker.
@riverpod
Future<DiaryQuickEatInventoryData> diaryQuickEatInventory(Ref ref) async {
  final inventory = await ref.watch(inventoryQuickEatInventoryProvider.future);
  return _filterDiaryQuickEatInventory(inventory);
}

DiaryQuickEatInventoryData _filterDiaryQuickEatInventory(
  InventoryQuickEatInventoryData inventory,
) {
  return DiaryQuickEatInventoryData(
    items: inventory.items
        .where(canDiaryQuickEatInventoryItem)
        .toList(growable: false),
    meals: inventory.meals
        .where((meal) => !meal.isDepleted)
        .toList(growable: false),
  );
}

/// Provides inventory mutations used by diary quick-eat.
@riverpod
DiaryQuickEatInventoryActions diaryQuickEatInventoryActions(Ref ref) {
  return _DiaryQuickEatInventoryActions(
    ref.watch(inventoryQuickEatActionsProvider),
  );
}

/// Inventory actions needed by the diary quick-eat flow.
abstract interface class DiaryQuickEatInventoryActions {
  /// Stages inventory consumption and returns the pending consumption id.
  Future<String?> stageInventoryItemConsumption({
    required InventoryItem item,
    required int amount,
  });

  /// Discards staged inventory consumption.
  Future<void> discardInventoryItemConsumption(String pendingConsumptionId);

  /// Consumes one prepared meal from the diary.
  Future<bool> consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  });
}

class _DiaryQuickEatInventoryActions implements DiaryQuickEatInventoryActions {
  /// Creates inventory actions.
  const new(this._actions);

  final InventoryQuickEatActions _actions;

  @override
  Future<String?> stageInventoryItemConsumption({
    required InventoryItem item,
    required int amount,
  }) async {
    return await _actions.stageInventoryItemConsumption(
      item: item,
      amount: amount,
    );
  }

  @override
  Future<void> discardInventoryItemConsumption(
    String pendingConsumptionId,
  ) async {
    await _actions.discardInventoryItemConsumption(pendingConsumptionId);
  }

  @override
  Future<bool> consumePreparedMeal({
    required PreparedMeal meal,
    required num consumedPortions,
    required MealType mealType,
    required DateTime loggedDay,
  }) {
    return _actions.consumePreparedMeal(
      meal: meal,
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
