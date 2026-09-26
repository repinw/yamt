import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';

part 'inventory_item_combine_controller.g.dart';

/// Foods picked on the item hub of [hubItemId] to log together with it.
@riverpod
class InventoryItemCombineController extends _$InventoryItemCombineController {
  @override
  List<InventoryCombinePick> build(String hubItemId) {
    return const <InventoryCombinePick>[];
  }

  /// Stock items that can join the list: counted in grams or milliliters,
  /// with nutrition values and stock, and neither the hub's item nor
  /// already picked. Sorted by name.
  List<InventoryItem> candidatesFrom(List<InventoryItem> items) {
    final taken = {hubItemId, ...state.map((pick) => pick.item.id)};
    return items
        .where(
          (item) =>
              !taken.contains(item.id) &&
              consumableInventoryAmount(item) != null &&
              defaultMealFoodAmount(item) != null &&
              InventoryCombinedEatService.canCombine(item),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Adds [request] of [item] to the list. A food found by search passes
  /// its [searchResult], and [item] is its draft.
  void add(
    InventoryItem item,
    InventoryItemEatRequest request, {
    InventoryReceiptManualProductResult? searchResult,
  }) {
    state = [
      ...state,
      (
        item: item,
        request: request,
        component: InventoryCombinedEatService.componentFor(item, request),
        searchResult: searchResult,
      ),
    ];
  }

  /// Adds [item] with its default amount, so it joins without an eat page.
  /// Returns false when [item] needs its amount entered on the eat page.
  bool addWithDefaultAmount(
    InventoryItem item, {
    InventoryReceiptManualProductResult? searchResult,
  }) {
    final amount = defaultMealFoodAmount(
      item,
      hasOpenStock: searchResult != null,
    );
    if (amount == null || amount < 1) {
      return false;
    }
    final loggedAt = ref.read(clockProvider)();
    add(
      item,
      InventoryItemEatRequest(
        inventoryAmount: amount,
        loggedAt: loggedAt,
        mealType: MealType.defaultForDateTime(loggedAt),
      ),
      searchResult: searchResult,
    );
    return true;
  }

  /// Sets the amount of the food of [itemId].
  void setAmount(String itemId, int amount) {
    state = [
      for (final pick in state)
        if (pick.item.id != itemId || amount < 1)
          pick
        else
          _withAmount(pick, amount),
    ];
  }

  static InventoryCombinePick _withAmount(
    InventoryCombinePick pick,
    int amount,
  ) {
    final request = InventoryItemEatRequest(
      inventoryAmount: amount,
      loggedAt: pick.request.loggedAt,
      mealType: pick.request.mealType,
    );
    return (
      item: pick.item,
      request: request,
      component: InventoryCombinedEatService.componentFor(pick.item, request),
      searchResult: pick.searchResult,
    );
  }

  /// Removes the food of [itemId].
  void remove(String itemId) {
    state = [
      for (final pick in state)
        if (pick.item.id != itemId) pick,
    ];
  }
}
