import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_facade.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

InventoryItem _inventoryItem({
  required String id,
  required String name,
  String? brand,
  int quantity = 0,
  int initialQuantity = 1,
  double unitPrice = 1.0,
}) {
  return InventoryItem.create(
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
    final activeKeys = <ShoppingListItemMatchKey>{
      (normalizedName: 'milk', normalizedBrand: 'acme'),
    };

    final same = isInventoryItemInActiveShoppingList(
      item: _inventoryItem(id: 'i1', name: ' Milk ', brand: ' ACME '),
      activeItemKeys: activeKeys,
    );
    final differentBrand = isInventoryItemInActiveShoppingList(
      item: _inventoryItem(id: 'i2', name: 'milk', brand: 'other'),
      activeItemKeys: activeKeys,
    );
    final emptyName = isInventoryItemInActiveShoppingList(
      item: _inventoryItem(id: 'i3', name: '   ', brand: 'acme'),
      activeItemKeys: activeKeys,
    );

    expect(same, isTrue);
    expect(differentBrand, isFalse);
    expect(emptyName, isFalse);
  });

  test(
    'isInventoryItemInActiveShoppingList returns true for consumed match',
    () {
      final activeKeys = <ShoppingListItemMatchKey>{
        (normalizedName: 'milk', normalizedBrand: 'acme'),
      };

      final result = isInventoryItemInActiveShoppingList(
        item: _inventoryItem(
          id: 'i1',
          name: 'Milk',
          brand: 'Acme',
          quantity: 0,
        ),
        activeItemKeys: activeKeys,
      );

      expect(result, isTrue);
    },
  );

  test(
    'isInventoryItemInActiveShoppingList returns false for missing match',
    () {
      final activeKeys = <ShoppingListItemMatchKey>{
        (normalizedName: 'milk', normalizedBrand: 'acme'),
      };

      final result = isInventoryItemInActiveShoppingList(
        item: _inventoryItem(
          id: 'i2',
          name: 'Bread',
          brand: 'Acme',
          quantity: 0,
        ),
        activeItemKeys: activeKeys,
      );

      expect(result, isFalse);
    },
  );

  test(
    'isInventoryItemInActiveShoppingList returns false for unconsumed items',
    () {
      final activeKeys = <ShoppingListItemMatchKey>{
        (normalizedName: 'milk', normalizedBrand: 'acme'),
      };

      final result = isInventoryItemInActiveShoppingList(
        item: _inventoryItem(
          id: 'i3',
          name: 'Milk',
          brand: 'Acme',
          quantity: 1,
          initialQuantity: 2,
        ),
        activeItemKeys: activeKeys,
      );

      expect(result, isFalse);
    },
  );

  test(
    'isInventoryItemInActiveShoppingList returns false without a match key',
    () {
      final activeKeys = <ShoppingListItemMatchKey>{
        (normalizedName: 'milk', normalizedBrand: 'acme'),
      };

      final result = isInventoryItemInActiveShoppingList(
        item: _inventoryItem(id: 'i4', name: '   ', brand: 'Acme'),
        activeItemKeys: activeKeys,
      );

      expect(result, isFalse);
    },
  );

  test(
    'addInventoryItem uses fallback quantity one for non-positive values',
    () async {
      ({String name, String? brand, int quantity, double estimatedUnitPrice})?
      captured;

      final result = await addInventoryItemToShoppingList(
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
        item: _inventoryItem(
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
