import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

void main() {
  test('auto assignment maps recipe gram unit to inventory gram unit', () {
    const requirement = TemplateIngredientRequirement(
      amount: 500,
      unit: TemplateIngredientUnit.gram,
      name: 'Rice',
    );
    final rice = _measuredItem(
      id: 'rice',
      name: 'Rice',
      unit: InventoryAmountUnit.gram,
    );

    expect(
      canAutoAssignInventoryItem(requirement: requirement, item: rice),
      isTrue,
    );
  });

  test('effective requirement keeps inventory unit at assignment boundary', () {
    const requirement = TemplateIngredientRequirement(
      amount: 2,
      unit: TemplateIngredientUnit.piece,
      name: 'Carrots',
    );
    final carrots = _measuredItem(
      id: 'carrots',
      name: 'Carrots',
      unit: InventoryAmountUnit.gram,
    );

    final effectiveRequirement = resolveEffectiveRequirementForItems(
      requirement: requirement,
      assignedItems: <InventoryItem>[carrots],
      amountConversion: const RecipeIngredientAmountConversion(
        amountPerPiece: 100,
        unit: InventoryAmountUnit.gram,
      ),
    );

    expect(effectiveRequirement, isNotNull);
    expect(effectiveRequirement!.amount, 200);
    expect(effectiveRequirement.unit, InventoryAmountUnit.gram);
  });

  test('selection rejects mismatched mapped inventory units', () {
    const requirement = TemplateIngredientRequirement(
      amount: 500,
      unit: TemplateIngredientUnit.gram,
      name: 'Rice',
    );
    final milk = _measuredItem(
      id: 'milk',
      name: 'Milk',
      unit: InventoryAmountUnit.milliliter,
    );

    expect(
      canSelectInventoryItemForRequirement(
        requirement: requirement,
        selectedItems: const <InventoryItem>[],
        candidate: milk,
      ),
      isFalse,
    );
  });
}

InventoryItem _measuredItem({
  required String id,
  required String name,
  required InventoryAmountUnit unit,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 4, 19),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: unit,
  );
}
