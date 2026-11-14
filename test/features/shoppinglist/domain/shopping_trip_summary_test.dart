import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_trip_summary.dart';

ShoppingListItem _item(
  String name, {
  bool isDone = false,
  bool isFavorite = false,
}) => ShoppingListItem(
  id: name,
  name: name,
  normalizedName: name.toLowerCase(),
  normalizedBrand: '',
  quantity: 1,
  estimatedUnitPrice: 0,
  isDone: isDone,
  isFavorite: isFavorite,
);

void main() {
  test('the cart leaves, open entries stay, saved ones stay saved', () {
    final trip = ShoppingTripSummary([
      _item('Milch', isDone: true),
      _item('Kaffee', isDone: true, isFavorite: true),
      _item('Brot'),
    ]);

    expect(trip.cart.map((item) => item.name), ['Milch', 'Kaffee']);
    expect(trip.openCount, 1);
    expect(trip.savedNames, ['Kaffee']);
  });
}
