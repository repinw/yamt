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

  group('a count of packs of a size', () {
    TemplateIngredientRequirement read(
      String ingredient, {
      int selected = 1,
      int base = 1,
    }) => parser.parseRequirement(
      ingredient: ingredient,
      selectedPortions: selected,
      basePortions: base,
    )!;

    for (final ingredient in [
      '2 Dosen Tomaten (à 400 g)',
      '2 Dose/n Tomaten (à 400 g)',
      '2 Dosen Tomaten à 400 g',
      '2 Dosen Tomaten (je 400 g)',
      '2 Dosen Tomaten je 400 g',
      '2 Dosen Tomaten, je 400 g',
      '2 Dosen Tomaten (à ca. 400 g)',
      '2 Dosen Tomaten (á 400 g)',
      '2 Dosen Tomaten a 400 g',
    ]) {
      test('"$ingredient" needs the count times the size', () {
        final requirement = read(ingredient);
        expect(requirement.amount, 800);
        expect(requirement.unit, TemplateIngredientUnit.gram);
        expect(requirement.name, 'Tomaten');
      });
    }

    test('scales with the portions', () {
      expect(
        read('2 Dosen Tomaten (à 400 g)', selected: 4, base: 2).amount,
        1600,
      );
      expect(read('2 Dosen Tomaten (à 400 g)', base: 2).amount, 400);
    });

    test('counts pieces of a size too', () {
      final requirement = read('2 Zwiebeln (à 80 g)');
      expect(requirement.amount, 160);
      expect(requirement.name, 'Zwiebeln');
      expect(read('3 Stück Hähnchenbrust je 150 g').amount, 450);
    });

    test('its label says the total, not the count of a total', () {
      expect(
        parser.pendingIngredientLabel(
          originalIngredient: '2 Dosen Tomaten (à 400 g)',
          requirement: read('2 Dosen Tomaten (à 400 g)'),
        ),
        '800 g Tomaten',
      );
    });

    test('a bare size stays a total', () {
      final requirement = read('2 Dosen Tomaten (800 g)');
      expect(requirement.amount, 800);
      expect(requirement.packageCountLabel, '2x');
    });

    test('"a" inside a word is no "à"', () {
      expect(read('2 Dosen Pasta 400 g').amount, 400);
    });

    test('an amount that is already a weight stays that weight', () {
      expect(read('2 kg Kartoffeln à 100 g').amount, 2000);
    });

    test('without a count "je" reads the size alone', () {
      final requirement = read('Zwiebeln je 80 g');
      expect(requirement.amount, 80);
      expect(requirement.name, 'Zwiebeln');
      expect(requirement.packageCountLabel, isNull);
    });
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

  group('reads the normalized line for every caller', () {
    const g = TemplateIngredientUnit.gram;
    const ml = TemplateIngredientUnit.milliliter;
    const pc = TemplateIngredientUnit.piece;

    // Line, amount, unit and name.
    const lines = <(String, int, TemplateIngredientUnit, String)>[
      ('½ Zitrone', 1, pc, 'Zitrone'),
      ('eine halbe Zitrone', 1, pc, 'Zitrone'),
      ('1,250 kg Mehl', 1250, g, 'Mehl'),
      ('zwei Zwiebeln', 2, pc, 'Zwiebeln'),
      ('drei Eier', 3, pc, 'Eier'),
      ('anderthalb Liter Brühe', 1500, ml, 'Brühe'),
      ('Öl, 30', 30, g, 'Öl'),
      ('Butter, 2 EL', 2, pc, 'Butter'),
      ('1 Pfund Hack', 500, g, 'Hack'),
      ('eine 400 g Dose Tomaten', 400, g, 'Tomaten'),
      // Lines that read as before the change.
      ('2 EL Olivenöl', 2, pc, 'Olivenöl'),
      ('1 Dose (400 g) Tomaten', 400, g, 'Tomaten'),
      ('3 Eier (M)', 3, pc, 'Eier (M)'),
      ('500 g Mehl', 500, g, 'Mehl'),
      ('1,5 kg Kartoffeln', 1500, g, 'Kartoffeln'),
      ('2 Tassen Reis', 2, pc, 'Tassen Reis'),
      ('250 g Mehl (Type 405)', 250, g, 'Mehl (Type 405)'),
      ('1 Packung (500 g) Spaghetti', 500, g, 'Spaghetti'),
      ('2 Dosen à 400 g Tomaten', 800, g, 'Tomaten'),
      ('250g Mehl', 250, g, 'Mehl'),
    ];
    for (final (line, amount, unit, name) in lines) {
      test('"$line" needs $amount ${unit.code} "$name"', () {
        final requirement = parser.parseRequirement(
          ingredient: line,
          selectedPortions: 1,
          basePortions: 1,
        );

        expect(requirement, isNotNull);
        expect(requirement!.amount, amount);
        expect(requirement.unit, unit);
        expect(requirement.name, name);
      });
    }

    test('"2 EL Olivenöl" keeps its spoon label, "1 Dose (400 g) Tomaten" '
        'its pack count', () {
      TemplateIngredientRequirement read(String line) =>
          parser.parseRequirement(
            ingredient: line,
            selectedPortions: 1,
            basePortions: 1,
          )!;

      expect(read('2 EL Olivenöl').countMeasureLabel, 'EL');
      expect(read('1 Dose (400 g) Tomaten').packageCountLabel, '1x');
    });

    test('"400-g-Dose Tomaten" needs 400 g', () {
      final requirement = parser.parseRequirement(
        ingredient: '400-g-Dose Tomaten',
        selectedPortions: 1,
        basePortions: 1,
      );

      expect(requirement!.amount, 400);
      expect(requirement.unit, g);
    });

    test('"1,250 kg Mehl" scales with the portions', () {
      final requirement = parser.parseRequirement(
        ingredient: '1,250 kg Mehl',
        selectedPortions: 2,
        basePortions: 4,
      );

      expect(requirement!.amount, 625);
      expect(requirement.unit, g);
    });
  });

  group('parseName reads a food name as written', () {
    test('a number word names no amount, the line itself does', () {
      expect(parser.parseName('Drei Kronen Spaghetti'), isNull);
      final line = parser.parseRequirement(
        ingredient: 'Drei Kronen Spaghetti',
        selectedPortions: 1,
        basePortions: 1,
      );
      expect(line!.amount, 3);
      expect(line.unit, TemplateIngredientUnit.piece);
    });

    test('a pack size in the name is its amount', () {
      final requirement = parser.parseName('Mozzarella 125 g');

      expect(requirement!.amount, 125);
      expect(requirement.unit, TemplateIngredientUnit.gram);
      expect(requirement.name, 'Mozzarella');
    });
  });
}
