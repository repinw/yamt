import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_edit_draft.dart';

import '../../../../support/prepared_meal_test_data.dart';

void main() {
  test('a row of a meal ingredient keeps every label value and scales it '
      'with the amount', () {
    final rice = labeledIngredientTestData(
      labeledFoodTestData(
        id: 'rice',
        name: 'Reis',
        grams: 1000,
        label: riceLabelTestData,
      ),
      200,
    );

    final row = PreparedMealEditRow.ofComponent(rice, available: 800);
    final doubled = row.withAmount(400);

    expect(row.eaten.kcal, 700);
    expect(row.eaten.sugar, 2);
    expect(row.eaten.salt, 0.5);
    expect(doubled.eaten.kcal, 1400);
    expect(doubled.eaten.sugar, 4);
    expect(doubled.eaten.fiber, 8);
  });

  test('a food added in pieces counts its label once per piece, as the '
      'meal stores it', () {
    final eggs = InventoryItem.create(
      id: 'eggs',
      name: 'Eier',
      entryDate: DateTime(2026, 10, 15),
      storeName: 'Store',
      quantity: 10,
      amountUnit: InventoryAmountUnit.piece,
      nutrition: riceLabelTestData,
    );

    final row = PreparedMealEditRow.ofItem(eggs, 2)!;
    final stored = PreparedMealEditRow.ofComponent(
      buildPreparedMealComponent(
        item: eggs,
        usedAmount: 2,
        usedUnit: InventoryAmountUnit.piece,
        nutrition: riceLabelTestData,
      ),
    );

    expect(row.eaten.kcal, stored.eaten.kcal);
    expect(row.eaten.salt, stored.eaten.salt);
  });
}
