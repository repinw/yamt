import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

void main() {
  const parser = TemplateIngredientParser();

  test('provider exposes template ingredient parser', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(templateIngredientParserProvider),
      isA<TemplateIngredientParser>(),
    );
  });

  test('ingredient unit codes stay stable for cross-feature labels', () {
    expect(TemplateIngredientUnit.gram.code, 'g');
    expect(TemplateIngredientUnit.milliliter.code, 'ml');
    expect(TemplateIngredientUnit.piece.code, 'pc');
  });

  test('parses decimal gram requirements with scaling', () {
    final requirement = parser.parseRequirement(
      ingredient: '1,5 kg Kartoffeln',
      selectedPortions: 2,
      basePortions: 4,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 750);
    expect(requirement.unit, TemplateIngredientUnit.gram);
    expect(requirement.name, 'Kartoffeln');
  });

  test('parses German thousands and decimal separators', () {
    final requirement = parser.parseRequirement(
      ingredient: '1.000,50 g Mehl',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 1001);
    expect(requirement.unit, TemplateIngredientUnit.gram);
    expect(requirement.name, 'Mehl');
  });

  test('parses fractional milliliter requirements', () {
    final requirement = parser.parseRequirement(
      ingredient: '1/2 l Brühe',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 500);
    expect(requirement.unit, TemplateIngredientUnit.milliliter);
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
    expect(requirement.unit, TemplateIngredientUnit.gram);
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
    expect(requirement.unit, TemplateIngredientUnit.gram);
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
    expect(requirement.unit, TemplateIngredientUnit.gram);
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
    expect(requirement.unit, TemplateIngredientUnit.piece);
    expect(requirement.name, 'Zwiebeln');
  });

  test('parses tablespoon counts as conversion-based ingredient units', () {
    final requirement = parser.parseRequirement(
      ingredient: '4 EL Tomatenmark',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 4);
    expect(requirement.unit, TemplateIngredientUnit.piece);
    expect(requirement.name, 'Tomatenmark');
    expect(requirement.countMeasureLabel, 'EL');
    expect(requirement.allowsDirectPieceInventoryMatch, isFalse);
  });

  test(
    'parses embedded approximate gram amounts from imported package text',
    () {
      final requirement = parser.parseRequirement(
        ingredient: 'gr Dose/n Tomaten, stückig (ca 800g)',
        selectedPortions: 1,
        basePortions: 1,
      );

      expect(requirement, isNotNull);
      expect(requirement!.amount, 800);
      expect(requirement.unit, TemplateIngredientUnit.gram);
      expect(requirement.name, 'Tomaten, stückig');
    },
  );

  test('parses dotted approximate weights with spaces', () {
    final requirement = parser.parseRequirement(
      ingredient: 'Dose/n Tomaten, stückige (ca. 800 g)',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 800);
    expect(requirement.unit, TemplateIngredientUnit.gram);
    expect(requirement.name, 'Tomaten, stückige');
  });

  test('parses embedded weights with extra amount-unit spaces', () {
    final requirement = parser.parseRequirement(
      ingredient: 'Dose/n Tomaten, stückige (ca. 800  g)',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 800);
    expect(requirement.unit, TemplateIngredientUnit.gram);
    expect(requirement.name, 'Tomaten, stückige');
  });

  test('prefers embedded package weights over imported package counts', () {
    final requirement = parser.parseRequirement(
      ingredient: '1 Dose Tomaten, passiert (ca 800g)',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 800);
    expect(requirement.unit, TemplateIngredientUnit.gram);
    expect(requirement.name, 'Tomaten, passiert');
    expect(requirement.packageCountLabel, '1x');
  });

  test('treats dotted package size prefixes as labels not gram units', () {
    final requirement = parser.parseRequirement(
      ingredient: '1 gr. Dose/n Tomaten, stückige (ca. 800 g)',
      selectedPortions: 1,
      basePortions: 1,
    );

    expect(requirement, isNotNull);
    expect(requirement!.amount, 800);
    expect(requirement.unit, TemplateIngredientUnit.gram);
    expect(requirement.name, 'Tomaten, stückige');
    expect(requirement.packageCountLabel, '1x');
  });

  test('formats pending ingredient labels from requirements', () {
    final label = parser.pendingIngredientLabel(
      originalIngredient: '1 kg Kartoffeln',
      requirement: const TemplateIngredientRequirement(
        amount: 500,
        unit: TemplateIngredientUnit.gram,
        name: 'Kartoffeln',
      ),
    );

    expect(label, '500 g Kartoffeln');
  });

  test('formats pending ingredient labels with custom count measures', () {
    final label = parser.pendingIngredientLabel(
      originalIngredient: '4 EL Tomatenmark',
      requirement: const TemplateIngredientRequirement(
        amount: 4,
        unit: TemplateIngredientUnit.piece,
        name: 'Tomatenmark',
        countMeasureLabel: 'EL',
        allowsDirectPieceInventoryMatch: false,
      ),
    );

    expect(label, '4 EL Tomatenmark');
  });

  test('formats pending ingredient labels with package count and weight', () {
    final label = parser.pendingIngredientLabel(
      originalIngredient: '1 Dose Tomaten, passiert (ca 800g)',
      requirement: const TemplateIngredientRequirement(
        amount: 800,
        unit: TemplateIngredientUnit.gram,
        name: 'Tomaten, passiert',
        packageCountLabel: '1x',
      ),
    );

    expect(label, '1x 800g Tomaten, passiert');
  });
}
