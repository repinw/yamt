import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_facade.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

FridgeItem _inventoryItem({
  required String id,
  required String name,
  String? brand,
  int quantity = 0,
  int initialQuantity = 1,
  double unitPrice = 1.0,
}) {
  return FridgeItem(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: unitPrice,
    brand: brand,
  );
}

ShoppingListItem _shoppingItem({
  required String id,
  required String normalizedName,
  required String normalizedBrand,
  int quantity = 1,
}) {
  return ShoppingListItem(
    id: id,
    name: normalizedName,
    normalizedName: normalizedName,
    normalizedBrand: normalizedBrand,
    quantity: quantity,
    estimatedUnitPrice: 1.0,
  );
}

void main() {
  test('normalizeShoppingListValue trims and lowercases input', () {
    expect(normalizeShoppingListValue(' MILK '), 'milk');
  });

  test('computeActiveShoppingListItemKeys ignores zero-quantity items', () {
    final keys = computeActiveShoppingListItemKeys(<ShoppingListItem>[
      _shoppingItem(
        id: 'a',
        normalizedName: 'milk',
        normalizedBrand: 'acme',
        quantity: 2,
      ),
      _shoppingItem(
        id: 'b',
        normalizedName: 'bread',
        normalizedBrand: '',
        quantity: 0,
      ),
    ]);

    expect(keys.length, 1);
    expect(
      keys.contains((normalizedName: 'milk', normalizedBrand: 'acme')),
      isTrue,
    );
    expect(
      keys.contains((normalizedName: 'bread', normalizedBrand: '')),
      isFalse,
    );
  });

  test('isInventoryItemInActiveList matches by normalized name and brand', () {
    final facade = ShoppingListFacade(
      addItem:
          ({
            required String name,
            String? brand,
            int quantity = 1,
            double estimatedUnitPrice = 0.0,
          }) async {
            return true;
          },
    );
    final activeKeys = <ShoppingListItemMatchKey>{
      (normalizedName: 'milk', normalizedBrand: 'acme'),
    };

    final same = facade.isInventoryItemInActiveList(
      item: _inventoryItem(id: 'i1', name: ' Milk ', brand: ' ACME '),
      activeItemKeys: activeKeys,
    );
    final differentBrand = facade.isInventoryItemInActiveList(
      item: _inventoryItem(id: 'i2', name: 'milk', brand: 'other'),
      activeItemKeys: activeKeys,
    );
    final emptyName = facade.isInventoryItemInActiveList(
      item: _inventoryItem(id: 'i3', name: '   ', brand: 'acme'),
      activeItemKeys: activeKeys,
    );

    expect(same, isTrue);
    expect(differentBrand, isFalse);
    expect(emptyName, isFalse);
  });

  test(
    'addInventoryItem uses fallback quantity one for non-positive values',
    () async {
      ({String name, String? brand, int quantity, double estimatedUnitPrice})?
      captured;
      final facade = ShoppingListFacade(
        addItem:
            ({
              required String name,
              String? brand,
              int quantity = 1,
              double estimatedUnitPrice = 0.0,
            }) async {
              captured = (
                name: name,
                brand: brand,
                quantity: quantity,
                estimatedUnitPrice: estimatedUnitPrice,
              );
              return true;
            },
      );

      final result = await facade.addInventoryItem(
        _inventoryItem(
          id: 'i4',
          name: 'Milk',
          brand: 'Acme',
          initialQuantity: 0,
          unitPrice: 2.5,
        ),
      );

      expect(result, isTrue);
      expect(captured, isNotNull);
      expect(captured!.name, 'Milk');
      expect(captured!.brand, 'Acme');
      expect(captured!.quantity, 1);
      expect(captured!.estimatedUnitPrice, 2.5);
    },
  );
}
