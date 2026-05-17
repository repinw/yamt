import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

ShoppingListSourceItem _sourceItem({
  required String name,
  String? brand,
  int initialQuantity = 1,
  double unitPrice = 1.0,
}) {
  return (
    name: name,
    brand: brand,
    initialQuantity: initialQuantity,
    unitPrice: unitPrice,
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
    estimatedUnitPrice: 1,
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

  test('isSourceItemInActiveList matches by normalized name and brand', () {
    final activeKeys = <ShoppingListItemMatchKey>{
      (normalizedName: 'milk', normalizedBrand: 'acme'),
    };

    final same = isSourceItemInActiveShoppingList(
      item: _sourceItem(name: ' Milk ', brand: ' ACME '),
      activeItemKeys: activeKeys,
    );
    final differentBrand = isSourceItemInActiveShoppingList(
      item: _sourceItem(name: 'milk', brand: 'other'),
      activeItemKeys: activeKeys,
    );
    final emptyName = isSourceItemInActiveShoppingList(
      item: _sourceItem(name: '   ', brand: 'acme'),
      activeItemKeys: activeKeys,
    );

    expect(same, isTrue);
    expect(differentBrand, isFalse);
    expect(emptyName, isFalse);
  });

  test('isSourceItemInActiveShoppingList returns true for matching items', () {
    final activeKeys = <ShoppingListItemMatchKey>{
      (normalizedName: 'milk', normalizedBrand: 'acme'),
    };

    final result = isSourceItemInActiveShoppingList(
      item: _sourceItem(
        name: 'Milk',
        brand: 'Acme',
      ),
      activeItemKeys: activeKeys,
    );

    expect(result, isTrue);
  });

  test('isSourceItemInActiveShoppingList returns false for missing match', () {
    final activeKeys = <ShoppingListItemMatchKey>{
      (normalizedName: 'milk', normalizedBrand: 'acme'),
    };

    final result = isSourceItemInActiveShoppingList(
      item: _sourceItem(
        name: 'Bread',
        brand: 'Acme',
      ),
      activeItemKeys: activeKeys,
    );

    expect(result, isFalse);
  });

  test('isSourceItemInActiveShoppingList returns true for partial items', () {
    final activeKeys = <ShoppingListItemMatchKey>{
      (normalizedName: 'milk', normalizedBrand: 'acme'),
    };

    final result = isSourceItemInActiveShoppingList(
      item: _sourceItem(
        name: 'Milk',
        brand: 'Acme',
        initialQuantity: 2,
      ),
      activeItemKeys: activeKeys,
    );

    expect(result, isTrue);
  });

  test(
    'isSourceItemInActiveShoppingList returns false without a match key',
    () {
      final activeKeys = <ShoppingListItemMatchKey>{
        (normalizedName: 'milk', normalizedBrand: 'acme'),
      };

      final result = isSourceItemInActiveShoppingList(
        item: _sourceItem(name: '   ', brand: 'Acme'),
        activeItemKeys: activeKeys,
      );

      expect(result, isFalse);
    },
  );

  test(
    'addSourceItem uses fallback quantity one for non-positive values',
    () async {
      ({String name, String? brand, int quantity, double estimatedUnitPrice})?
      captured;

      final result = await addSourceItemToShoppingList(
        addItem:
            ({
              required name,
              brand,
              quantity = 1,
              estimatedUnitPrice = 0.0,
            }) async {
              captured = (
                name: name,
                brand: brand,
                quantity: quantity,
                estimatedUnitPrice: estimatedUnitPrice,
              );
              return true;
            },
        item: _sourceItem(
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

  test('provider family matches source items against active keys', () {
    final item = _sourceItem(name: 'Milk', brand: 'Acme');
    final container = ProviderContainer(
      overrides: [
        activeShoppingListItemKeysProvider.overrideWith(
          (ref) => <ShoppingListItemMatchKey>{
            (normalizedName: 'milk', normalizedBrand: 'acme'),
          },
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = container.read(
      isSourceItemInActiveShoppingListProvider(item),
    );

    expect(result, isTrue);
  });
}
