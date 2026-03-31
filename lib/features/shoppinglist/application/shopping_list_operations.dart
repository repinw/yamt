import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';

typedef ShoppingListItemMatchKey = ({
  String normalizedName,
  String normalizedBrand,
});

typedef ShoppingListAddItem =
    Future<bool> Function({
      required String name,
      String? brand,
      int quantity,
      double estimatedUnitPrice,
    });

final activeShoppingListItemKeysProvider =
    Provider<Set<ShoppingListItemMatchKey>>((ref) {
      final items = ref.watch(shoppingListControllerProvider).asData?.value;
      if (items == null) {
        return const <ShoppingListItemMatchKey>{};
      }
      return computeActiveShoppingListItemKeys(items);
    });

final isInventoryItemInActiveShoppingListProvider =
    Provider.family<bool, InventoryItem>((ref, item) {
      return ref.watch(
        activeShoppingListItemKeysProvider.select(
          (keys) => isInventoryItemInActiveShoppingList(
            item: item,
            activeItemKeys: keys,
          ),
        ),
      );
    });

Future<bool> addInventoryItemToShoppingList({
  required InventoryItem item,
  required ShoppingListAddItem addItem,
}) {
  final quantity = _normalizeInventoryQuantityForShopping(item.initialQuantity);
  return addItem(
    name: item.name,
    brand: item.brand,
    quantity: quantity,
    estimatedUnitPrice: item.unitPrice,
  );
}

int _normalizeInventoryQuantityForShopping(int initialQuantity) {
  return initialQuantity > 0 ? initialQuantity : 1;
}

String normalizeShoppingListValue(String value) {
  return value.trim().toLowerCase();
}

Set<ShoppingListItemMatchKey> computeActiveShoppingListItemKeys(
  List<ShoppingListItem> items,
) {
  return items
      .where((item) => item.quantity > 0)
      .map(
        (item) => (
          normalizedName: normalizeShoppingListValue(item.normalizedName),
          normalizedBrand: normalizeShoppingListValue(item.normalizedBrand),
        ),
      )
      .toSet();
}

ShoppingListItemMatchKey? _inventoryItemMatchKey(InventoryItem item) {
  final normalizedName = normalizeShoppingListValue(item.name);
  if (normalizedName.isEmpty) {
    return null;
  }
  final normalizedBrand = normalizeShoppingListValue(item.brand ?? '');
  return (normalizedName: normalizedName, normalizedBrand: normalizedBrand);
}

bool isInventoryItemInActiveShoppingList({
  required InventoryItem item,
  required Set<ShoppingListItemMatchKey> activeItemKeys,
}) {
  if (!item.isFullyConsumed) {
    return false;
  }

  final key = _inventoryItemMatchKey(item);
  if (key == null) {
    return false;
  }

  return activeItemKeys.contains(key);
}
