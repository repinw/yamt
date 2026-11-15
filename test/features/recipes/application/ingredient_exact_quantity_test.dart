import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/recipes/application/ingredient_exact_quantity.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

const _parser = TemplateIngredientParser();

TemplateIngredientRequirement? _read(
  String text, {
  int portions = 2,
  int base = 2,
}) => parseIngredientExactly(
  _parser,
  text,
  selectedPortions: portions,
  basePortions: base,
);

String? _quantity(String text, {int portions = 2, int base = 2}) {
  final read = _read(text, portions: portions, base: base);
  return read == null ? null : ingredientQuantityText(read);
}

void main() {
  group('parseIngredientExactly', () {
    test('keeps the exact quantity of spoons at scaled portions', () {
      final read = _read('1 TL Salz', portions: 5)!;

      expect(read.exactQuantity, 2.5);
      expect(read.amount, 3);
      expect(read.unit, TemplateIngredientUnit.piece);
    });

    test('keeps a part of a piece', () {
      final read = _read('1/2 Zitrone')!;

      expect(read.exactQuantity, 0.5);
      expect(read.amount, 1);
    });

    test('rounds grams once and keeps no exact quantity', () {
      final read = _read('100 g Mehl', portions: 3)!;

      expect(read.amount, 150);
      expect(read.unit, TemplateIngredientUnit.gram);
      expect(read.exactQuantity, isNull);
    });

    test('is null for a line without an amount', () {
      expect(_read('Salz'), isNull);
    });

    test('reads a half in a sign and in words as half a piece', () {
      for (final text in ['½ Zitrone', 'eine halbe Zitrone']) {
        final read = _read(text)!;

        expect(read.exactQuantity, 0.5, reason: text);
        expect(read.amount, 1, reason: text);
        expect(read.unit, TemplateIngredientUnit.piece, reason: text);
        expect(read.name, 'Zitrone', reason: text);
      }
    });

    test('reads a number in words', () {
      final read = _read('zwei Zwiebeln')!;

      expect(read.amount, 2);
      expect(read.unit, TemplateIngredientUnit.piece);
      expect(read.name, 'Zwiebeln');
    });

    test('reads a scale reading in kg as grams', () {
      final read = _read('1,250 kg Mehl')!;

      expect(read.amount, 1250);
      expect(read.unit, TemplateIngredientUnit.gram);
      expect(read.name, 'Mehl');
    });
  });

  group('cookNeedHasPart', () {
    test('is true for a part of a unit', () {
      expect(cookNeedHasPart(_read('1/2 Zitrone')), isTrue);
      expect(cookNeedHasPart(_read('1,5 EL Öl')), isTrue);
    });

    test('is false for a whole number and for no need', () {
      expect(cookNeedHasPart(_read('2 Zitronen')), isFalse);
      expect(cookNeedHasPart(_read('200 g Mehl')), isFalse);
      expect(cookNeedHasPart(null), isFalse);
    });

    test('is true for 0.5 and 1.5 and false for 2.0 and null', () {
      TemplateIngredientRequirement need(double? exact) =>
          TemplateIngredientRequirement(
            amount: 2,
            unit: TemplateIngredientUnit.piece,
            name: 'Zitrone',
            exactQuantity: exact,
          );

      expect(cookNeedHasPart(need(0.5)), isTrue);
      expect(cookNeedHasPart(need(1.5)), isTrue);
      expect(cookNeedHasPart(need(2)), isFalse);
      expect(cookNeedHasPart(need(null)), isFalse);
    });
  });

  group('ingredientQuantityText', () {
    test('says teaspoons with a decimal comma', () {
      expect(_quantity('1 TL Salz', portions: 5), '2,5');
    });

    test('says a half as a fraction, a part above 1 as a decimal', () {
      expect(_quantity('1/2 Zitrone'), '1/2');
      expect(_quantity('1/2 Zitrone', portions: 5), '1,25');
    });

    test('says whole spoons whole', () {
      expect(_quantity('2 EL Öl', portions: 5), '5');
      expect(_quantity('2 EL Öl'), '2');
    });

    test('says other fractions below 1', () {
      expect(_quantity('1/3 Zitrone'), '1/3');
      expect(_quantity('1/4 Zitrone'), '1/4');
    });

    test('keeps a small amount as written', () {
      expect(_quantity('0,1 g Safran'), '1');
      expect(
        ingredientQuantityText(
          const TemplateIngredientRequirement(
            amount: 1,
            unit: TemplateIngredientUnit.gram,
            name: 'Safran',
          ),
        ),
        '1',
      );
    });
  });
}
