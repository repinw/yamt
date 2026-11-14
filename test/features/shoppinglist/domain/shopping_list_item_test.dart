import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

void main() {
  test('toJson/fromJson roundtrip preserves values', () {
    const item = ShoppingListItem(
      id: 'item-1',
      name: 'Milk',
      brand: 'Acme',
      normalizedName: 'milk',
      normalizedBrand: 'acme',
      quantity: 2,
      estimatedUnitPrice: 1.49,
      isDone: true,
    );

    final decoded = ShoppingListItem.fromJson(item.toJson());

    expect(decoded.id, item.id);
    expect(decoded.name, item.name);
    expect(decoded.brand, item.brand);
    expect(decoded.normalizedName, item.normalizedName);
    expect(decoded.normalizedBrand, item.normalizedBrand);
    expect(decoded.quantity, item.quantity);
    expect(decoded.estimatedUnitPrice, item.estimatedUnitPrice);
    expect(decoded.isDone, isTrue);
  });

  test('fromJson throws without the done flag', () {
    const item = ShoppingListItem(
      id: 'item-1',
      name: 'Milk',
      normalizedName: 'milk',
      normalizedBrand: '',
      quantity: 1,
      estimatedUnitPrice: 0,
    );

    expect(
      () => ShoppingListItem.fromJson(item.toJson()..remove('is_done')),
      throwsFormatException,
    );
  });

  test('an entry is open, in the cart, or archived', () {
    const open = ShoppingListItem(
      id: 'item-1',
      name: 'Milk',
      normalizedName: 'milk',
      normalizedBrand: '',
      quantity: 2,
      estimatedUnitPrice: 0,
    );
    final inCart = open.copyWith(isDone: true);
    final archived = open.copyWith(quantity: 0, isArchived: true);

    expect((open.isOpen, open.isInCart), (true, false));
    expect((inCart.isOpen, inCart.isInCart), (false, true));
    expect((archived.isOpen, archived.isInCart), (false, false));
  });

  test('fromJson throws on invalid payload types', () {
    expect(
      () => ShoppingListItem.fromJson(<String, dynamic>{
        'id': 'item-1',
        'name': 'Milk',
        'brand': 'Acme',
        'normalized_name': 'milk',
        'normalized_brand': 'acme',
        'quantity': '1',
        'estimated_unit_price': 1.0,
      }),
      throwsFormatException,
    );
  });
}
