import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_builder.dart';

void main() {
  group('parseCookingFlowIngredient', () {
    test('keeps German piece units out of the ingredient name', () {
      final cases = <String>['2 stück Apfel', '2 stueck Apfel'];

      for (final value in cases) {
        final ingredient = parseCookingFlowIngredient(value);

        expect(ingredient?.name, 'Apfel');
      }
    });

    test('keeps English piece units out of the ingredient name', () {
      final ingredient = parseCookingFlowIngredient(
        '2 pieces apple',
        localeCode: 'en',
      );

      expect(ingredient?.name, 'apple');
    });
  });

  group('parseCookingFlowIngredientRequirement', () {
    test('normalizes German piece units', () {
      final cases = <String>['2 stück', '2 stueck'];

      for (final value in cases) {
        final requirement = parseCookingFlowIngredientRequirement(value);

        expect(requirement?.amount, 2);
        expect(requirement?.unitCode, cookingFlowPieceUnitCode);
      }
    });

    test('strips package count prefix without whitespace', () {
      final requirement = parseCookingFlowIngredientRequirement('2x500g');

      expect(requirement?.amount, 500);
      expect(requirement?.unitCode, 'g');
    });

    test('parses German thousands and decimal separators', () {
      final requirement = parseCookingFlowIngredientRequirement(
        '1.000,50 g',
      );

      expect(requirement?.amount, 1000.5);
      expect(requirement?.unitCode, 'g');
    });

    test('normalizes English piece units', () {
      final requirement = parseCookingFlowIngredientRequirement(
        '2 pieces',
        localeCode: 'en',
      );

      expect(requirement?.amount, 2);
      expect(requirement?.unitCode, cookingFlowPieceUnitCode);
    });
  });
}
