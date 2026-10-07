import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_shopping.dart';
import 'package:yamt/features/inventory/domain/inventory_replenishment.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/application/shopping_plan_needs.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

part 'inventory_shopping_suggestions.g.dart';

/// Live stock input owned by inventory.
@riverpod
Stream<List<InventoryItem>> inventoryShoppingStock(Ref ref) =>
    ref.watch(inventoryItemRepositoryProvider).watchAll();

/// Adapts inventory facts to the shopping feature's public suggestion model.
@riverpod
AsyncValue<List<ShoppingSuggestion>> inventoryShoppingSuggestions(Ref ref) =>
    ref
        .watch(inventoryShoppingStockProvider)
        .whenData(
          (items) => inventoryReplenishment(items, DateTime.now())
              .map(
                (item) => ShoppingSuggestion(
                  name: item.name,
                  brand: item.brand,
                  purchaseCount: item.purchaseCount,
                  isLowStock: item.isLowStock,
                  isOutOfStock: item.isOutOfStock,
                ),
              )
              .toList(growable: false),
        );

/// What to buy for the open plans the Vorrat cannot cover, grouped by day
/// and meal, without the foods already on the shopping list.
// ponytail: plans of found foods and cooked meals are left out like in the
// demand; add them when the demand counts them.
@riverpod
Future<List<ShoppingPlanNeedGroup>> inventoryShoppingPlanNeedGroups(
  Ref ref,
) async {
  final listed = ref.watch(activeShoppingListItemKeysProvider);
  final plans = await ref.watch(openPlansProvider.future);
  final demand = await ref.watch(openPlanDemandProvider.future);
  return groupShoppingPlanNeeds(
    inventoryShoppingPlanNeeds(plans, demand.missingShareByPlanId),
    listed,
  );
}
