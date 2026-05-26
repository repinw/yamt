import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';

/// Defines shopping list item match key typedef.
typedef ShoppingListItemMatchKey = ({
  String normalizedName,
  String normalizedBrand,
});

/// Defines shopping list add item typedef.
typedef ShoppingListAddItem =
    Future<bool> Function({
      required String name,
      String? brand,
      int quantity,
      double estimatedUnitPrice,
    });

/// Defines item data needed by shopping-list operations.
typedef ShoppingListSourceItem = ({
  String name,
  String? brand,
  int initialQuantity,
  double unitPrice,
});

/// The active shopping list item keys provider.
final activeShoppingListItemKeysProvider =
    Provider<Set<ShoppingListItemMatchKey>>((ref) {
      final items = ref.watch(shoppingListControllerProvider).asData?.value;
      if (items == null) {
        return const <ShoppingListItemMatchKey>{};
      }
      return computeActiveShoppingListItemKeys(items);
    });

/// Whether source item in active shopping list provider.
final Provider<bool> Function(ShoppingListSourceItem)
isSourceItemInActiveShoppingListProvider =
    Provider.family<bool, ShoppingListSourceItem>((ref, item) {
      return ref.watch(
        activeShoppingListItemKeysProvider.select(
          (keys) => isSourceItemInActiveShoppingList(
            item: item,
            activeItemKeys: keys,
          ),
        ),
      );
    });

/// Add source item to shopping list.
Future<bool> addSourceItemToShoppingList({
  required ShoppingListSourceItem item,
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

/// Normalize shopping list value.
String normalizeShoppingListValue(String value) {
  return value.trim().toLowerCase();
}

/// Compute active shopping list item keys.
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

ShoppingListItemMatchKey? _sourceItemMatchKey(ShoppingListSourceItem item) {
  final normalizedName = normalizeShoppingListValue(item.name);
  if (normalizedName.isEmpty) {
    return null;
  }
  final normalizedBrand = normalizeShoppingListValue(item.brand ?? '');
  return (normalizedName: normalizedName, normalizedBrand: normalizedBrand);
}

/// Is source item in active shopping list.
bool isSourceItemInActiveShoppingList({
  required ShoppingListSourceItem item,
  required Set<ShoppingListItemMatchKey> activeItemKeys,
}) {
  final key = _sourceItemMatchKey(item);
  if (key == null) {
    return false;
  }

  return activeItemKeys.contains(key);
}
