import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';

/// Orchestrates shopping-list actions used by other features.
final shoppingListFacadeProvider = Provider<ShoppingListFacade>(
  (ref) => ShoppingListFacade(ref),
);

final activeShoppingListItemKeysProvider = Provider<Set<String>>((ref) {
  final items = ref.watch(shoppingListControllerProvider).asData?.value;
  if (items == null) {
    return const <String>{};
  }
  return _activeItemKeys(items);
});

/// Application-layer bridge for shopping list mutations.
class ShoppingListFacade {
  const ShoppingListFacade(this._ref);

  final Ref _ref;

  Future<bool> addInventoryItem(FridgeItem item) {
    final quantity = item.initialQuantity > 0 ? item.initialQuantity : 1;
    return _ref
        .read(shoppingListControllerProvider.notifier)
        .addItem(
          name: item.name,
          brand: item.brand,
          quantity: quantity,
          estimatedUnitPrice: item.unitPrice,
        );
  }

  bool isInventoryItemInActiveList({
    required FridgeItem item,
    required Set<String> activeItemKeys,
  }) {
    final normalizedName = _normalize(item.name);
    if (normalizedName.isEmpty) {
      return false;
    }
    final normalizedBrand = _normalize(item.brand ?? '');
    final itemKey = _shoppingItemKey(
      normalizedName: normalizedName,
      normalizedBrand: normalizedBrand,
    );
    return activeItemKeys.contains(itemKey);
  }
}

Set<String> _activeItemKeys(List<ShoppingListItem> items) {
  return items.where((item) => item.quantity > 0).map((item) {
    return _shoppingItemKey(
      normalizedName: item.normalizedName,
      normalizedBrand: item.normalizedBrand,
    );
  }).toSet();
}

String _shoppingItemKey({
  required String normalizedName,
  required String normalizedBrand,
}) {
  return '$normalizedName::$normalizedBrand';
}

String _normalize(String value) {
  return value.trim().toLowerCase();
}
