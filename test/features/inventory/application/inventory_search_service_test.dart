import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_search_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

InventoryItem _item({
  required String id,
  required String name,
  String? brand,
  String? category,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    brand: brand,
    category: category,
    entryDate: DateTime.parse('2026-02-20T08:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    unitPrice: 1,
  );
}

PreparedMeal _meal({
  required String id,
  required String name,
  List<String> ingredients = const <String>[],
}) {
  return PreparedMeal(
    id: id,
    name: name,
    recipeIngredients: ingredients,
    totalPortions: 2,
    remainingPortions: 1,
    totalKcal: 500,
    totalProtein: 20,
    totalCarbs: 50,
    totalFat: 15,
    createdAt: DateTime.parse('2026-02-20T08:00:00Z'),
    updatedAt: DateTime.parse('2026-02-20T08:00:00Z'),
    components: const [],
  );
}

void main() {
  const service = InventorySearchService();

  test('empty query returns the original inventory items', () {
    final items = <InventoryItem>[
      _item(id: '1', name: 'Apple Juice'),
      _item(id: '2', name: 'Kidney Beans'),
    ];

    final result = service.filterItems(items: items, query: '   ');

    expect(result, same(items));
  });

  test('compact voice query matches spaced inventory item with typo', () {
    final items = <InventoryItem>[
      _item(id: '1', name: 'Eiweiß Bort'),
      _item(id: '2', name: 'Toastbrot'),
    ];

    final result = service.filterItems(items: items, query: 'eiweißbrot');

    expect(result.map((item) => item.name), <String>['Eiweiß Bort']);
  });

  test('prepared meals are matched against meal name and ingredients', () {
    final meals = <PreparedMeal>[
      _meal(
        id: 'meal-1',
        name: 'Pasta Bowl',
        ingredients: const <String>['Tomato', 'Basil'],
      ),
      _meal(
        id: 'meal-2',
        name: 'Rice Pan',
        ingredients: const <String>['Beans'],
      ),
    ];

    final result = service.filterPreparedMeals(meals: meals, query: 'basil');

    expect(result.map((meal) => meal.name), <String>['Pasta Bowl']);
  });

  test('filterItems handles very long strings without failing', () {
    final longName = '${List<String>.filled(200, 'hafer').join(' ')} brot';
    final items = <InventoryItem>[
      _item(id: '1', name: longName),
      _item(id: '2', name: 'Toastbrot'),
    ];

    final longQuery = '${List<String>.filled(50, 'hafer').join()}brot';
    final result = service.filterItems(items: items, query: longQuery);

    expect(result.map((item) => item.name), <String>[longName]);
  });

  group('isWithinEditDistanceOne', () {});

  group('hasApproximateCompactMatch', () {});
}
