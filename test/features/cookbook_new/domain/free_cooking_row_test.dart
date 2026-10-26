import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

FreeCookingRow _row(String food, {int? grams, String? stockName}) {
  return FreeCookingRow(
    text: grams == null ? food : '$grams g $food',
    requirement: grams == null
        ? null
        : TemplateIngredientRequirement(
            amount: grams,
            unit: TemplateIngredientUnit.gram,
            name: food,
          ),
    stockItems: [
      if (stockName != null)
        InventoryItem.create(
          id: stockName,
          name: stockName,
          entryDate: DateTime.utc(2026, 10, 26),
          storeName: 'Store',
          quantity: 1,
        ),
    ],
  );
}

void main() {
  test('suggestedName lists three different foods, amounts first', () {
    final rows = [
      _row('Salz'),
      _row('reis', grams: 200, stockName: 'Reis'),
      _row('Reis', grams: 100),
      _row(' '),
      _row('hähnchen', grams: 500),
      _row('Pfeffer'),
      _row('Brokkoli', grams: 300),
    ];

    expect(rows.suggestedName, 'Reis, hähnchen, Brokkoli');
    expect([_row('Salz'), _row('Pfeffer')].suggestedName, 'Salz, Pfeffer');
  });

  test('suggestedName is null without rows', () {
    expect(const <FreeCookingRow>[].suggestedName, isNull);
  });
}
