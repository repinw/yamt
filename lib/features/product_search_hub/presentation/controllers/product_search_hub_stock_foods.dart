import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/recipe_stock_foods.dart';

part 'product_search_hub_stock_foods.g.dart';

/// The Vorrat foods a recipe line can take whose name or brand holds every
/// word of [query]; the whole Vorrat for an empty query
/// ([recipeStockFoods]). [held] joins with commas the ids of the items that
/// have nothing left for the line (`ProductSearchHubRouteArgs.heldItemIds`),
/// so the family compares by value.
@riverpod
AsyncValue<List<InventoryItem>> productSearchHubStockFoods(
  Ref ref,
  String query,
  String held,
) => ref
    .watch(inventoryQuickEatItemsProvider)
    .whenData(
      (items) =>
          recipeStockFoods(items, query.trim(), held: {...held.split(',')}),
    );
