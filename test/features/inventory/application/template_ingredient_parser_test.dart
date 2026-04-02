import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

void main() {
  const parser = TemplateIngredientParser();

  test('parses decimal gram requirements with scaling', () {
    final requirement = parser.parseRequirement(
      ingredient: '1,5 kg Kartoffeln',
      selectedPortions: 2,
      basePortions: 4,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 750);
    expect(requirement.unit, InventoryAmountUnit.gram);
    expect(requirement.name, 'Kartoffeln');
  });

  test('parses fractional milliliter requirements', () {
    final requirement = parser.parseRequirement(
      ingredient: '1/2 l Brühe',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 500);
    expect(requirement.unit, InventoryAmountUnit.milliliter);
    expect(requirement.name, 'Brühe');
  });

  test('parses simple gram requirements', () {
    final requirement = parser.parseRequirement(
      ingredient: '500 g Nudeln',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 500);
    expect(requirement.unit, InventoryAmountUnit.gram);
    expect(requirement.name, 'Nudeln');
  });

  test('parses gram requirements without a space before the unit', () {
    final requirement = parser.parseRequirement(
      ingredient: '500g Nudeln',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 500);
    expect(requirement.unit, InventoryAmountUnit.gram);
    expect(requirement.name, 'Nudeln');
  });

  test('parses mixed fractional requirements', () {
    final requirement = parser.parseRequirement(
      ingredient: '1 1/2 kg Kartoffeln',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 1500);
    expect(requirement.unit, InventoryAmountUnit.gram);
    expect(requirement.name, 'Kartoffeln');
  });

  test('returns null for unsupported measure words', () {
    final requirement = parser.parseRequirement(
      ingredient: '2 cups Mehl',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNull);
  });

  test('returns null for pinch-style units', () {
    final requirement = parser.parseRequirement(
      ingredient: '1 Prise Salz',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNull);
  });

  test('returns null for ingredient text without a numeric prefix', () {
    final requirement = parser.parseRequirement(
      ingredient: 'etwas Pfeffer',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNull);
  });

  test('returns null for empty ingredient text', () {
    final requirement = parser.parseRequirement(
      ingredient: '',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNull);
  });

  test('returns null for invalid fractional quantities', () {
    final requirement = parser.parseRequirement(
      ingredient: '1/0 kg Mehl',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNull);
  });

  test('falls back to piece requirements for plain counts', () {
    final requirement = parser.parseRequirement(
      ingredient: '2 Zwiebeln',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 2);
    expect(requirement.unit, InventoryAmountUnit.piece);
    expect(requirement.name, 'Zwiebeln');
  });

  test('formats pending ingredient labels from requirements', () {
    final label = parser.pendingIngredientLabel(
      originalIngredient: '1 kg Kartoffeln',
      requirement: const TemplateIngredientRequirement(
        amount: 500,
        unit: InventoryAmountUnit.gram,
        name: 'Kartoffeln',
      ),
    );

    expect(label, '500 g Kartoffeln');
  });
}
