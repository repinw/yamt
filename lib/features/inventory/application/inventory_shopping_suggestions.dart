import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_replenishment.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

part 'inventory_shopping_suggestions.g.dart';

/// Live stock input owned by inventory.
@Riverpod(dependencies: [inventoryItemRepository])
Stream<List<InventoryItem>> inventoryShoppingStock(Ref ref) =>
    ref.watch(inventoryItemRepositoryProvider).watchAll();

/// Adapts inventory facts to the shopping feature's public suggestion model.
@Riverpod(dependencies: [inventoryShoppingStock])
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
