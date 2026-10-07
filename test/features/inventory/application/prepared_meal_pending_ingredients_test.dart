import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_pending_ingredients.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

InventoryItem _milk({required String id, required InventoryAmountUnit unit}) {
  return InventoryItem.create(
    id: id,
    name: 'Milch',
    entryDate: DateTime.utc(2026, 9),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 1000,
    amountUnit: unit,
  );
}

InventoryItem? _match(String ingredient, List<InventoryItem> items) {
  return findPendingIngredientStockMatch(
    ingredient: ingredient,
    inventoryItems: items,
    ingredientParser: const TemplateIngredientParser(),
    localeCode: 'de',
  );
}

void main() {
  test('skips a match whose unit cannot supply the row', () {
    final items = [
      _milk(id: 'gram', unit: InventoryAmountUnit.gram),
      _milk(id: 'ml', unit: InventoryAmountUnit.milliliter),
    ];

    expect(_match('200 ml Milch', items)?.id, 'ml');
    expect(_match('200 ml Milch', [items.first]), isNull);
  });

  test('offers no match for a row without an amount', () {
    expect(
      _match('Milch', [_milk(id: 'ml', unit: InventoryAmountUnit.milliliter)]),
      isNull,
    );
  });
}
