import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';

typedef ShoppingListAddItem =
    Future<bool> Function({
      required String name,
      String? brand,
      int quantity,
      double estimatedUnitPrice,
    });

typedef ShoppingListItemMatchKey = ({
  String normalizedName,
  String normalizedBrand,
});

final shoppingListFacadeProvider = Provider<ShoppingListFacade>((ref) {
  final controller = ref.read(shoppingListControllerProvider.notifier);
  return ShoppingListFacade(
    addItem:
        ({
          required String name,
          String? brand,
          int quantity = 1,
          double estimatedUnitPrice = 0.0,
        }) {
          return controller.addItem(
            name: name,
            brand: brand,
            quantity: quantity,
            estimatedUnitPrice: estimatedUnitPrice,
          );
        },
  );
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

class ShoppingListFacade {
  const ShoppingListFacade({required ShoppingListAddItem addItem})
    : _addItem = addItem;

  final ShoppingListAddItem _addItem;

  Future<bool> addInventoryItem(InventoryItem item) {
    final quantity = _normalizeInventoryQuantityForShopping(
      item.initialQuantity,
    );
    return _addItem(
      name: item.name,
      brand: item.brand,
      quantity: quantity,
      estimatedUnitPrice: item.unitPrice,
    );
  }

  bool isInventoryItemInActiveList({
    required InventoryItem item,
    required Set<ShoppingListItemMatchKey> activeItemKeys,
  }) {
    return isInventoryItemInActiveShoppingList(
      item: item,
      activeItemKeys: activeItemKeys,
    );
  }
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
