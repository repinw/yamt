import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

void main() {
  group('template ingredient domain', () {
    test('unit codes stay stable for cross-feature labels', () {
      expect(TemplateIngredientUnit.gram.code, 'g');
      expect(TemplateIngredientUnit.milliliter.code, 'ml');
      expect(TemplateIngredientUnit.piece.code, 'pc');
    });

    test('requirement keeps parsed ingredient metadata', () {
      const requirement = TemplateIngredientRequirement(
        amount: 2,
        unit: TemplateIngredientUnit.piece,
        name: 'egg',
        countMeasureLabel: 'pcs',
        packageCountLabel: '1x',
        allowsDirectPieceInventoryMatch: false,
      );

      expect(requirement.amount, 2);
      expect(requirement.unit, TemplateIngredientUnit.piece);
      expect(requirement.name, 'egg');
      expect(requirement.countMeasureLabel, 'pcs');
      expect(requirement.packageCountLabel, '1x');
      expect(requirement.allowsDirectPieceInventoryMatch, isFalse);
    });
  });
}
