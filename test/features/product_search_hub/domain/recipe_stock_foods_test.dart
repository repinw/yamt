import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/recipe_stock_foods.dart';

InventoryItem _food(String id, String name, {int quantity = 1}) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime(2026, 11, 12),
      storeName: 'Store',
      quantity: quantity,
      weight: '1 kg',
    ).withDerivedAmount();

List<String> _ids(List<InventoryItem> items) => [
  for (final item in items) item.id,
];

void main() {
  final flour = _food('flour', 'Mehl');
  final sugar = _food('sugar', 'Zucker');
  final rice = _food('rice', 'Reis');

  test('offers every food with something left, sorted by name', () {
    expect(_ids(recipeStockFoods([sugar, flour, rice], '')), [
      'flour',
      'rice',
      'sugar',
    ]);
  });

  test('leaves out the held foods, which have nothing left for the line', () {
    expect(_ids(recipeStockFoods([sugar, flour, rice], '', held: {'rice'})), [
      'flour',
      'sugar',
    ]);
  });

  test('leaves out a held food that matches the query too', () {
    expect(recipeStockFoods([rice], 'reis', held: {'rice'}), isEmpty);
    expect(_ids(recipeStockFoods([rice], 'reis')), ['rice']);
  });

  test('without held foods the whole Vorrat stays', () {
    expect(_ids(recipeStockFoods([flour, rice], '')), ['flour', 'rice']);
  });
}
