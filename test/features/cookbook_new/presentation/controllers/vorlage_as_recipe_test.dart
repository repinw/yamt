import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/vorlage_as_recipe.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

PreparedMealComponent _piece(String id, String name, int amount) {
  final item = InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.utc(2026, 10),
    storeName: 'Store',
    quantity: 4,
    initialQuantity: 4,
  );
  return PreparedMealComponent(
    inventoryItemId: id,
    name: name,
    brand: null,
    imageUrl: null,
    usedAmount: amount,
    usedUnit: InventoryAmountUnit.piece,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    sourceItemSnapshot: item,
  );
}

PreparedMeal _vorlage(List<PreparedMealComponent> components) {
  final now = DateTime.utc(2026, 10, 9);
  return PreparedMeal(
    id: 'v',
    name: 'Pfanne',
    totalPortions: 1,
    remainingPortions: 1,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: now,
    updatedAt: now,
    components: components,
  );
}

void main() {
  const parser = TemplateIngredientParser();

  test('a piece food whose name starts with a number word keeps its whole '
      'name', () {
    final foods = vorlageFoods(
      _vorlage([_piece('crowns', 'Drei Kronen Spaghetti', 2)]),
      parser,
    );

    expect(foods.single.food.name, 'Drei Kronen Spaghetti');
    expect(foods.single.line, contains('Drei Kronen Spaghetti'));
  });

  test('a pack size in the name of a piece food is no amount', () {
    final foods = vorlageFoods(
      _vorlage([_piece('mozzarella', 'Mozzarella 125 g', 2)]),
      parser,
    );

    expect(foods.single.food.name, 'Mozzarella');
  });
}
