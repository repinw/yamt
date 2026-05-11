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
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      'Tomatn (2)',
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
    );

    expect(
      steps.single.segments.where((segment) => segment.isHighlight).single.text,
      'Zwibel (1)',
    );
  });

  test('fuzzy typo matching accepts one edit but rejects transposition', () {
    final cases = <({String instruction, String? highlight})>[
      (instruction: 'Apfel schneiden.', highlight: 'Apfel (1)'),
      (instruction: 'Apfe schneiden.', highlight: 'Apfe (1)'),
      (instruction: 'Apxel schneiden.', highlight: 'Apxel (1)'),
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
      );

      expect(
        steps.single.segments
            .where((segment) => segment.isHighlight)
            .map((segment) => segment.text),
        <String>['Ei (2)', 'Öl (20 ml)'],
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
        recipeInstructions: const <String>[
          'Und auch etwas Salz dazugeben.',
        ],
      ),
      introDraft: null,
      inventoryItems: const <InventoryItem>[],
      text: _text,
      localeCode: 'en',
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
    );

    expect(
      steps.single.segments
          .where((segment) => segment.isHighlight)
          .map((segment) => segment.text),
      <String>['rote Zwiebel (1)'],
    );
    expect(_plainText(steps.single), 'rote Zwiebel (1) schneiden.');
  });
}

String _plainText(CookingFlowInstructionStep step) {
  return step.segments.map((segment) => segment.text).join();
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
}) {
  final now = DateTime.parse('2026-03-27T12:00:00Z');
  return PreparedMeal(
    id: 'template-1',
    name: 'Testgericht',
    recipeIngredients: recipeIngredients,
    recipeInstructions: recipeInstructions,
    totalPortions: 4,
    remainingPortions: 4,
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
