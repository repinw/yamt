import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_texts.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations_de.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';

const _nbsp = ' ';
final _en = AppLocalizationsEn();
final _de = AppLocalizationsDe();

const _tenMl = CookLineConversion(
  amountPerPiece: 10,
  unit: TemplateIngredientUnit.milliliter,
);

// 400 ml of oil, of which another cooking holds 50 ml.
final InventoryItem _bottle = stockItem(
  'bottle',
  400,
  unit: InventoryAmountUnit.milliliter,
).copyWith(name: 'Olivenöl');

KochmodusView _view(
  String text, {
  Map<String, int> take = const {'bottle': 50},
}) => buildKochmodusView(
  run: buildCookRun(
    lines: [
      textLine('own', text, conversion: _tenMl, settlement: assigned(take)),
    ],
  ),
  saved: true,
  ended: false,
  busy: false,
  reopened: false,
  finished: null,
  tab: null,
  items: [_bottle],
  otherReservations: const {'bottle': 50},
  utensils: const [],
  parser: const TemplateIngredientParser(),
);

void main() {
  group('what is there for a line in spoons', () {
    test('is said in the unit of the food, for what the other run leaves', () {
      final line = _view('5 EL Olivenöl').lines.single;

      expect(kochmodusThereText(_en, line), '350${_nbsp}ml');
      expect(kochmodusThereText(_de, line), '350${_nbsp}ml');
    });

    test('is the same in the row word and on the card', () {
      final view = _view('5 EL Olivenöl');
      final line = view.lines.single;

      expect(
        kochmodusRowWord(_en, line, onCard: false),
        _en.kochmodusRowThere('350${_nbsp}ml'),
      );
      final hints = kochmodusCardHints(_en, line);
      expect(
        hints.map((hint) => hint.text),
        contains(
          _en.kochmodusAssignItemThere(
            _en.kochmodusAssignItems('Olivenöl', 0),
            '350${_nbsp}ml',
          ),
        ),
      );
    });

    test('never says an amount in spoons', () {
      final view = _view('5 EL Olivenöl');
      final line = view.lines.single;
      final texts = [
        kochmodusRowWord(_de, line, onCard: false),
        for (final hint in kochmodusCardHints(_de, line)) hint.text,
      ];

      for (final text in texts) {
        expect(text, isNot(contains('EL')), reason: text);
        expect(text, isNot(contains('35 ')), reason: text);
      }
      expect(texts.any((text) => text.contains('350${_nbsp}ml')), isTrue);
    });

    test('counts the whole bottle when the line takes nothing of it yet', () {
      final line = _view(
        '5 EL Olivenöl',
        take: const {'bottle': 0},
      ).lines.single;

      expect(kochmodusThereText(_en, line), '350${_nbsp}ml');
    });

    test('an open counted line has no hint, whatever the Vorrat holds', () {
      final view = buildKochmodusView(
        run: buildCookRun(lines: [textLine('own', '300 g Olivenöl')]),
        saved: true,
        ended: false,
        busy: false,
        reopened: false,
        finished: null,
        tab: null,
        items: [_bottle],
        otherReservations: const {},
        utensils: const [],
        parser: const TemplateIngredientParser(),
      );

      expect(kochmodusCardHints(_de, view.lines.single), isEmpty);
    });

    test('is null for a line that holds no food', () {
      final view = buildKochmodusView(
        run: buildCookRun(lines: [textLine('own', '5 EL Olivenöl')]),
        saved: true,
        ended: false,
        busy: false,
        reopened: false,
        finished: null,
        tab: null,
        items: [_bottle],
        otherReservations: const {},
        utensils: const [],
        parser: const TemplateIngredientParser(),
      );

      expect(kochmodusThereText(_en, view.lines.single), isNull);
    });
  });

  group('kochmodusItemAmountText', () {
    test('keeps number and unit together with a no-break space', () {
      expect(
        kochmodusItemAmountText(
          _en,
          400,
          InventoryAmountUnit.gram,
          stockItem('g', 400),
        ),
        '400${_nbsp}g',
      );
    });

    test('says pieces as "Stk." and "pcs"', () {
      final eggs = stockItem(
        'pc',
        3000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      );

      expect(
        kochmodusItemAmountText(_de, 3000, InventoryAmountUnit.piece, eggs),
        '3${_nbsp}Stk.',
      );
      expect(
        kochmodusItemAmountText(_en, 3000, InventoryAmountUnit.piece, eggs),
        '3${_nbsp}pcs',
      );
    });
  });

  group('the card hint of an estimated weight', () {
    test('is said in ml for a line that takes from a food kept in ml', () {
      final view = _view('2 EL Olivenöl', take: const {'bottle': 20});
      final line = view.lines.single;
      final hints = kochmodusCardHints(_en, line);

      expect(
        hints.map((hint) => hint.text),
        contains(_en.eatPageApprox('20${_nbsp}ml')),
      );
    });
  });

  group('the locale number format', () {
    final pieces = stockItem(
      'pc',
      5000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    );

    test('German groups thousands with a dot and uses a decimal comma', () {
      expect(
        kochmodusItemAmountText(_de, 2500, InventoryAmountUnit.piece, pieces),
        '2,5${_nbsp}Stk.',
      );
      expect(
        kochmodusItemAmountText(
          _de,
          1250,
          InventoryAmountUnit.gram,
          stockItem('g', 2000),
        ),
        '1.250${_nbsp}g',
      );
    });

    test('English uses a decimal point and a comma for thousands', () {
      expect(
        kochmodusItemAmountText(_en, 2500, InventoryAmountUnit.piece, pieces),
        '2.5${_nbsp}pcs',
      );
      expect(
        kochmodusItemAmountText(
          _en,
          1250,
          InventoryAmountUnit.gram,
          stockItem('g', 2000),
        ),
        '1,250${_nbsp}g',
      );
    });
  });

  group('kochmodusWeightText', () {
    final oil = stockItem('oil', 500, unit: InventoryAmountUnit.milliliter);
    final eggs = stockItem(
      'egg',
      3000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    );

    test('is ml for a food kept in ml', () {
      expect(kochmodusWeightText(_de, 20, oil), '20${_nbsp}ml');
      expect(kochmodusWeightText(_en, 20, oil), '20${_nbsp}ml');
    });

    test('is g for a food in grams, in pieces, and without a food', () {
      expect(kochmodusWeightText(_de, 20, stockItem('g', 500)), '20${_nbsp}g');
      expect(kochmodusWeightText(_de, 120, eggs), '120${_nbsp}g');
      expect(kochmodusWeightText(_en, 20, null), '20${_nbsp}g');
    });

    test('groups thousands in German', () {
      expect(kochmodusWeightText(_de, 1250, null), '1.250${_nbsp}g');
      expect(kochmodusWeightText(_en, 1250, null), '1,250${_nbsp}g');
    });
  });
}
