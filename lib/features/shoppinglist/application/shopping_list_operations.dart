import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';

part 'shopping_list_operations.g.dart';

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

/// Active product keys for integrations that add shopping entries.
@riverpod
Set<ShoppingListItemMatchKey> activeShoppingListItemKeys(Ref ref) {
  final items = ref.watch(shoppingListControllerProvider).asData?.value;
  return computeActiveShoppingListItemKeys(items ?? []);
}

/// Whether an external product is already on the list.
@riverpod
bool sourceItemInActiveShoppingList(Ref ref, ShoppingListSourceItem item) =>
    isSourceItemInActiveShoppingList(
      item: item,
      activeItemKeys: ref.watch(activeShoppingListItemKeysProvider),
    );

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
      .where((item) => item.quantity > 0 && !item.isArchived)
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
