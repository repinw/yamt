import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

void main() {
  test('maps recipe ingredient units to inventory amount units', () {
    expect(
      TemplateIngredientUnit.gram.toInventoryAmountUnit(),
      InventoryAmountUnit.gram,
    );
    expect(
      TemplateIngredientUnit.milliliter.toInventoryAmountUnit(),
      InventoryAmountUnit.milliliter,
    );
    expect(
      TemplateIngredientUnit.piece.toInventoryAmountUnit(),
      InventoryAmountUnit.piece,
    );
  });

  test('maps inventory amount units back to recipe ingredient units', () {
    expect(
      InventoryAmountUnit.gram.toTemplateIngredientUnit(),
      TemplateIngredientUnit.gram,
    );
    expect(
      InventoryAmountUnit.milliliter.toTemplateIngredientUnit(),
      TemplateIngredientUnit.milliliter,
    );
    expect(
      InventoryAmountUnit.piece.toTemplateIngredientUnit(),
      TemplateIngredientUnit.piece,
    );
  });

  test('maps recipe ingredient requirement to inventory unit', () {
    const requirement = TemplateIngredientRequirement(
      amount: 500,
      unit: TemplateIngredientUnit.gram,
      name: 'Rice',
    );

    expect(requirement.inventoryUnit, InventoryAmountUnit.gram);
  });
}
