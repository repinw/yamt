import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
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

  test('the planned meal is stored as a day and a meal, without words', () {
    final item = ShoppingListItem(
      id: 'item-1',
      name: 'Milk',
      normalizedName: 'milk',
      normalizedBrand: '',
      quantity: 1,
      estimatedUnitPrice: 0,
      plannedFor: (day: DateTime(2026, 11, 19), mealType: MealType.breakfast),
    );

    final json = item.toJson();
    final decoded = ShoppingListItem.fromJson(json);

    expect(json['planned_for'], {
      'day': '2026-11-19',
      'meal_type': 'breakfast',
    });
    expect(decoded.plannedFor, (
      day: DateTime(2026, 11, 19),
      mealType: MealType.breakfast,
    ));
  });

  test('fromJson throws on a planned meal it cannot read', () {
    final json = {
      ...const ShoppingListItem(
        id: 'item-1',
        name: 'Milk',
        normalizedName: 'milk',
        normalizedBrand: '',
        quantity: 1,
        estimatedUnitPrice: 0,
      ).toJson(),
      'planned_for': {'day': '2026-11-19', 'meal_type': 'brunch'},
    };

    expect(() => ShoppingListItem.fromJson(json), throwsFormatException);
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
