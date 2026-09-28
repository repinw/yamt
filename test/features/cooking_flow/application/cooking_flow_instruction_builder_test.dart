import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_builder.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

void main() {
  test('builds fallback instructions from recipe ingredients', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(recipeIngredients: const <String>['300g Linsen']),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(steps, hasLength(2));
    expect(_plainText(steps.first), 'Bereite vor: 300 g Linsen.');
    expect(_plainText(steps.last), 'Koche alles.');
  });

  test(
    'highlights fuzzy ingredient mentions with selected inventory amount',
    () {
      final steps = buildCookingFlowInstructionSteps(
        template: _template(
          recipeIngredients: const <String>['2 Zwiebeln'],
          recipeInstructions: const <String>['Zwiebel fein wuerfeln.'],
        ),
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '2 Zwiebeln',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'onions'),
              ],
            ),
          ],
        ),
        inventoryItems: <InventoryItem>[
          _inventoryItem(id: 'onions', name: 'Zwiebeln', currentAmount: 180),
        ],
        text: _text,
        localeCode: 'de',
        targetPortions: 4,
      );

      expect(
        steps.single.segments
            .where((segment) => segment.isHighlight)
            .single
            .text,
        'Zwiebel (180g)',
      );
    },
  );

  test('does not duplicate amount when instruction already contains it', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['500 g Hackfleisch'],
        recipeInstructions: const <String>['500g Hackfleisch anbraten.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      '500g Hackfleisch',
    );
  });

  test('fuzzy highlights ingredient typo in instructions', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['2 Tomaten'],
        recipeInstructions: const <String>['Tomatn grob hacken.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      'Tomatn (2 Stück)',
    );
  });

  test('fuzzy highlights ingredients with one Levenshtein edit', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['1 Zwiebel'],
        recipeInstructions: const <String>['Zwibel fein wuerfeln.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      'Zwibel (1 Stück)',
    );
  });

  test('fuzzy typo matching accepts one edit but rejects transposition', () {
    final cases = <({String instruction, String? highlight})>[
      (instruction: 'Apfel schneiden.', highlight: 'Apfel (1 Stück)'),
      (instruction: 'Apfe schneiden.', highlight: 'Apfe (1 Stück)'),
      (instruction: 'Apxel schneiden.', highlight: 'Apxel (1 Stück)'),
      (instruction: 'Afpel schneiden.', highlight: null),
    ];

    for (final testCase in cases) {
      final steps = buildCookingFlowInstructionSteps(
        template: _template(
          recipeIngredients: const <String>['1 Apfel'],
          recipeInstructions: <String>[testCase.instruction],
        ),
        introDraft: null,
        inventoryItems: const <InventoryItem>[],
        text: _text,
        localeCode: 'de',
        targetPortions: 4,
      );
      final highlights = steps.single.segments
          .where((segment) => segment.isHighlight)
          .map((segment) => segment.text)
          .toList();

      final expectedHighlight = testCase.highlight;
      if (expectedHighlight == null) {
        expect(highlights, isEmpty, reason: testCase.instruction);
      } else {
        expect(highlights, <String>[expectedHighlight]);
      }
    }
  });

  test(
    'highlights short ingredients beside punctuation without false positives',
    () {
      final steps = buildCookingFlowInstructionSteps(
        template: _template(
          recipeIngredients: const <String>['2 Eier', '20 ml Öl'],
          recipeInstructions: const <String>[
            'Das Ei, das Öl und ein Drittel Wasser verruehren.',
          ],
        ),
        introDraft: null,
        inventoryItems: const <InventoryItem>[],
        text: _text,
        localeCode: 'de',
        targetPortions: 4,
      );

      expect(
        steps.single.segments
            .where((segment) => segment.isHighlight)
            .map((segment) => segment.text),
        <String>['Ei (2 Stück)', 'Öl (20 ml)'],
      );
      expect(_plainText(steps.single), contains('ein Drittel'));
    },
  );

  test('ignores German stop-word-only fuzzy candidates', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['1 Minze'],
        recipeInstructions: const <String>['Mit und auch dann verruehren.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight),
      isEmpty,
    );
  });

  test('does not fuzzy-highlight stop words inside ingredient names', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['1 Bund Koriander', '1 Lauch'],
        recipeInstructions: const <String>['Und auch etwas Salz dazugeben.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'en',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight),
      isEmpty,
    );
  });

  test('does not duplicate overlapping ingredient highlights', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['1 rote Zwiebel', '1 Zwiebel'],
        recipeInstructions: const <String>['rote Zwiebel schneiden.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments
          .where((segment) => segment.isHighlight)
          .map((segment) => segment.text),
      <String>['rote Zwiebel (1 Stück)'],
    );
    expect(_plainText(steps.single), 'rote Zwiebel (1 Stück) schneiden.');
  });

  test('replaces pre-existing different amount in instruction with required '
      'piece amount', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['2 Zwiebeln'],
        recipeInstructions: const <String>['1 Zwiebel fein wuerfeln.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      'Zwiebel (2 Stück)',
    );
    expect(_plainText(steps.single), 'Zwiebel (2 Stück) fein wuerfeln.');
  });

  test('replaces pre-existing matching amount in instruction with required '
      'piece amount', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['2 Zwiebeln'],
        recipeInstructions: const <String>['2 Zwiebeln fein wuerfeln.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      'Zwiebeln (2 Stück)',
    );
    expect(_plainText(steps.single), 'Zwiebeln (2 Stück) fein wuerfeln.');
  });

  test('replaces pre-existing weight amount in instruction when recipe '
      'amount differs', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['800 g Hackfleisch'],
        recipeInstructions: const <String>['500g Hackfleisch anbraten.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      'Hackfleisch (800 g)',
    );
    expect(_plainText(steps.single), 'Hackfleisch (800 g) anbraten.');
  });

  test('does not duplicate trailing parenthesized amounts in instruction', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['2 Zwiebeln'],
        recipeInstructions: const <String>['Zwiebeln (2 Stück) fein wuerfeln.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      'Zwiebeln (2 Stück)',
    );
    expect(_plainText(steps.single), 'Zwiebeln (2 Stück) fein wuerfeln.');
  });

  test('parses unicode vulgar fractions, ranges, and prefix qualifiers', () {
    const instruction =
        'Kartoffeln schaelen, Knoblauch pressen, '
        'Zitrone auspressen und Salz zugeben.';
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>[
          '½ Zitrone',
          '1-2 Zehen Knoblauch',
          'ca. 500 g Kartoffeln',
          '1/4 TL Salz',
        ],
        recipeInstructions: const <String>[instruction],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    final highlights = steps.single.segments
        .where((segment) => segment.isHighlight)
        .map((segment) => segment.text)
        .toList();

    expect(highlights, contains('Kartoffeln (500 g)'));
    expect(highlights, contains('Knoblauch (1-2 Zehen)'));
    expect(highlights, contains('Zitrone (1 Stück)'));
    expect(highlights, contains('Salz (1/4 TL)'));
  });

  test('scales pinch, clove range, and pinch-unit amounts by portions', () {
    const instruction = 'Salz, Pfeffer, Knoblauch und Schnittlauch dazugeben.';
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>[
          '2 Prisen Salz',
          '1 Prise Pfeffer',
          '1-2 Zehen Knoblauch',
          'etwas Schnittlauch',
        ],
        recipeInstructions: const <String>[instruction],
        totalPortions: 2,
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    final highlights = steps.single.segments
        .where((segment) => segment.isHighlight)
        .map((segment) => segment.text)
        .toList();

    expect(highlights, contains('Salz (4 Prisen)'));
    expect(highlights, contains('Pfeffer (2 Prisen)'));
    expect(highlights, contains('Knoblauch (2-4 Zehen)'));
    expect(highlights, contains('Schnittlauch (etwas)'));
  });

  test('handles qualitative amounts without showing unknown amount', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>[
          'etwas Salz',
          'Olivenöl nach Geschmack',
        ],
        recipeInstructions: const <String>[
          'Mit Salz und Olivenöl abschmecken.',
        ],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    final plain = _plainText(steps.single);
    expect(plain, isNot(contains('unbekannt')));
    final highlights = steps.single.segments
        .where((segment) => segment.isHighlight)
        .map((segment) => segment.text)
        .toList();
    expect(highlights, contains('Salz (etwas)'));
    expect(highlights, contains('Olivenöl (nach Geschmack)'));
  });

  test('matches short words and irregular German plurals', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>[
          '200 g Pilze',
          '1 Ei',
          '2 Knoblauchzehen',
        ],
        recipeInstructions: const <String>[
          'Den Pilz putzen, die Eier trennen und den Knoblauch hacken.',
        ],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    final highlights = steps.single.segments
        .where((segment) => segment.isHighlight)
        .map((segment) => segment.text)
        .toList();

    expect(highlights, contains('Pilz (200 g)'));
    expect(highlights, contains('Eier (1 Stück)'));
    expect(highlights, contains('Knoblauch (2 Stück)'));
  });

  test(
    'applies flow-local editedName and editedAmountLabel from introDraft',
    () {
      final steps = buildCookingFlowInstructionSteps(
        template: _template(
          recipeIngredients: const <String>['2 Zwiebeln'],
          recipeInstructions: const <String>['Schalotten fein wuerfeln.'],
        ),
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '2 Zwiebeln',
              editedName: 'Schalotten',
              editedAmountLabel: '3 Stück',
            ),
          ],
        ),
        inventoryItems: const <InventoryItem>[],
        text: _text,
        localeCode: 'de',
        targetPortions: 4,
      );

      expect(
        steps.single.segments
            .where((segment) => segment.isHighlight)
            .single
            .text,
        'Schalotten (3 Stück)',
      );
    },
  );

  test('scales piece amounts to the currently selected target portions', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['4 Eier'],
        recipeInstructions: const <String>['Eier verruehren.'],
        totalPortions: 2,
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      'Eier (8 Stück)',
    );
  });

  test('keeps the qualitative amount when an inventory piece item is assigned '
      'to an ingredient without a numeric amount', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['etwas Schnittlauch'],
        recipeInstructions: const <String>['Schnittlauch darueberstreuen.'],
      ),
      introDraft: const CookingFlowIntroDraft(
        rowStates: <CookingFlowIntroRowDraft>[
          CookingFlowIntroRowDraft(
            rawIngredient: 'etwas Schnittlauch',
            action: CookingFlowIntroRowAction.assigned,
            selections: <CookingFlowIntroSelectionDraft>[
              CookingFlowIntroSelectionDraft(itemId: 'chives'),
            ],
          ),
        ],
      ),
      inventoryItems: <InventoryItem>[
        _quantityInventoryItem(id: 'chives', name: 'Schnittlauch', quantity: 1),
      ],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      'Schnittlauch (etwas)',
    );
  });

  test(
    'does not highlight the conjunction "oder" as a stray ingredient match',
    () {
      final steps = buildCookingFlowInstructionSteps(
        template: _template(
          recipeIngredients: const <String>['1 Kartoffel'],
          recipeInstructions: const <String>[
            'Kartoffel halbieren oder vierteln.',
          ],
        ),
        introDraft: null,
        inventoryItems: const <InventoryItem>[],
        text: _text,
        localeCode: 'de',
        targetPortions: 4,
      );

      final highlights = steps.single.segments
          .where((segment) => segment.isHighlight)
          .map((segment) => segment.text)
          .toList();

      expect(highlights, <String>['Kartoffel (1 Stück)']);
      expect(_plainText(steps.single), contains('oder vierteln'));
    },
  );

  group('recipe "Rührei mit Tomaten" scaled from 2 to 4 portions', () {
    const tomatoLine = '20 kleine Tomaten';
    const chivesLine = 'etwas Schnittlauch (frisch oder TK)';
    const olderChivesLine = '1 etwas Schnittlauch (frisch oder TK)';

    List<String> ingredientLines(String chives) => <String>[
      '4 Eier (möglichst Bio)',
      tomatoLine,
      '4 EL Milch (oder Sahne)',
      '20 g Butter',
      '2 Prisen Salz',
      '1 Prise Pfeffer',
      chives,
    ];

    List<String> highlightsFor({
      required String chives,
      required String instruction,
    }) {
      final steps = buildCookingFlowInstructionSteps(
        template: _template(
          recipeIngredients: ingredientLines(chives),
          recipeInstructions: <String>[instruction],
          totalPortions: 2,
        ),
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: tomatoLine,
              editedAmountLabel: '400 g',
            ),
          ],
        ),
        inventoryItems: const <InventoryItem>[],
        text: _text,
        localeCode: 'de',
        targetPortions: 4,
      );
      return _highlights(steps.single);
    }

    const cutInstruction =
        'Kleine Tomaten halbieren oder vierteln. '
        'Frischen Schnittlauch in Ringe schneiden.';

    test('highlights tomatoes and chives, never "halbieren oder"', () {
      expect(
        highlightsFor(chives: chivesLine, instruction: cutInstruction),
        <String>['Kleine Tomaten (400 g)', 'Schnittlauch (etwas)'],
      );
    });

    test('never highlights "halbieren oder" for the older chives import', () {
      final highlights = highlightsFor(
        chives: olderChivesLine,
        instruction: cutInstruction,
      );

      expect(highlights, hasLength(2));
      expect(highlights.first, 'Kleine Tomaten (400 g)');
      expect(highlights.last, startsWith('Schnittlauch ('));
      expect(
        highlights.where(
          (highlight) =>
              highlight.contains('halbieren') || highlight.contains('oder'),
        ),
        isEmpty,
      );
    });

    test('highlights only Eier, Milch, Salz and Pfeffer', () {
      final highlights = highlightsFor(
        chives: chivesLine,
        instruction:
            'Eier in eine Schüssel schlagen. '
            'Milch, Salz und Pfeffer zugeben.',
      );

      expect(
        highlights.map((highlight) => highlight.split(' (').first),
        <String>['Eier', 'Milch', 'Salz', 'Pfeffer'],
      );
      expect(highlights.first, 'Eier (8 Stück)');
      expect(highlights[1], 'Milch (8 EL)');
    });
  });

  test('matches the last word of a multi-word ingredient name', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['20 kleine Tomaten'],
        recipeInstructions: const <String>['Die Tomaten waschen.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(_highlights(steps.single), <String>['Tomaten (20 Stück)']);
  });

  test('keeps a trailing note in parentheses that is not an amount', () {
    final steps = buildCookingFlowInstructionSteps(
      template: _template(
        recipeIngredients: const <String>['4 EL Milch'],
        recipeInstructions: const <String>['Milch (lauwarm) zugeben.'],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'de',
      targetPortions: 4,
    );

    expect(_highlights(steps.single), <String>['Milch (4 EL)']);
    expect(_plainText(steps.single), 'Milch (4 EL) (lauwarm) zugeben.');
  });
}

String _plainText(CookingFlowInstructionStep step) {
  return step.segments.map((segment) => segment.text).join();
}

List<String> _highlights(CookingFlowInstructionStep step) {
  return step.segments
      .where((segment) => segment.isHighlight)
      .map((segment) => segment.text)
      .toList();
}

const _text = CookingFlowInstructionText(
  unknownAmount: 'unbekannt',
  fallbackNoIngredients: 'Keine Zutaten.',
  fallbackPrepPrefix: 'Bereite vor:',
  fallbackCookText: 'Koche alles.',
);

PreparedMeal _template({
  List<String> recipeIngredients = const <String>[],
  List<String> recipeInstructions = const <String>[],
  int totalPortions = 4,
}) {
  final now = DateTime.parse('2026-03-27T12:00:00Z');
  return PreparedMeal(
    id: 'template-1',
    name: 'Testgericht',
    recipeIngredients: recipeIngredients,
    recipeInstructions: recipeInstructions,
    totalPortions: totalPortions,
    remainingPortions: totalPortions,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
  );
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  required int currentAmount,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
    storeName: 'Test',
    quantity: 1,
    initialAmount: currentAmount,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.gram,
  );
}

InventoryItem _quantityInventoryItem({
  required String id,
  required String name,
  required int quantity,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
    storeName: 'Test',
    quantity: quantity,
  );
}
