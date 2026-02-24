import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';

/// Orchestrates shopping-list actions used by other features.
final shoppingListFacadeProvider = Provider<ShoppingListFacade>(
  (ref) => ShoppingListFacade(ref),
);

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
}
