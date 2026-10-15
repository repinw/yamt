import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

InventoryItem _item(String id, String name, InventoryAmountUnit unit) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime.utc(2026, 10),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: unit,
    );

void main() {
  final items = [
    _item('milk', 'Milch', InventoryAmountUnit.milliliter),
    _item('carrots-old', 'Karotten Bio', InventoryAmountUnit.gram),
    _item('carrots', 'Karotten', InventoryAmountUnit.gram),
    _item('rice', 'Reis', InventoryAmountUnit.gram),
  ];
  const text = '300 g Karotten';
  final requirement = const TemplateIngredientParser().parseRequirement(
    ingredient: text,
    selectedPortions: 1,
    basePortions: 1,
  );

  test('the first name match is the best match, and the others follow by '
      'name in a fitting unit', () {
    final (:matches, :others) = ingredientStockCandidates(
      text: text,
      requirement: requirement,
      items: items,
      localeCode: 'de',
    );

    expect(
      matches.first,
      bestIngredientStockMatch(
        text: text,
        requirement: requirement,
        items: items,
        localeCode: 'de',
      ),
    );
    expect(matches.map((item) => item.id), ['carrots', 'carrots-old']);
    expect(others.map((item) => item.id), ['rice']);
  });

  test('an ingredient without an amount has no candidates', () {
    final (:matches, :others) = ingredientStockCandidates(
      text: 'Salz',
      requirement: null,
      items: items,
      localeCode: 'de',
    );

    expect(matches, isEmpty);
    expect(others, isEmpty);
  });
}
