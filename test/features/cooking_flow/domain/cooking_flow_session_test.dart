import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';

void main() {
  test('round trips full session json', () {
    const session = CookingFlowSession(
      templateId: 'template-1',
      step: CookingFlowSessionStep.finalize,
      taraText: '420',
      taraUtensilId: 'pot-1',
      adjustmentInputText: 'more salt',
      adjustments: <String>['extra onions'],
      summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[
        CookingFlowSummaryIngredientSessionDraft(
          key: 'template:300g Linsen',
          name: 'Linsen',
          amount: '300',
          unitCode: 'g',
          inventoryItemIds: <String>['item-1'],
          kind: CookingFlowSummaryIngredientKind.template,
          sourceIngredient: '300g Linsen',
        ),
      ],
      grossWeightText: '1800',
      splitIntoPortions: false,
      portionCount: 4,
      finalPortionCount: 6,
      introDraft: CookingFlowIntroDraft(
        rowStates: <CookingFlowIntroRowDraft>[
          CookingFlowIntroRowDraft(
            rawIngredient: '300g Linsen',
            action: CookingFlowIntroRowAction.assigned,
            selections: <CookingFlowIntroSelectionDraft>[
              CookingFlowIntroSelectionDraft(
                itemId: 'item-1',
                isAdditionalIngredient: true,
              ),
            ],
            conflictResolution: CookingFlowIntroConflictResolution.weighLater,
            editedName: 'Rote Linsen',
            editedAmountLabel: '320 g',
          ),
        ],
      ),
      introShoppingHandled: true,
      introShoppingBaselineInventoryItemIds: <String>['old-item'],
      storageContainers: <CookingFlowStorageContainerSessionDraft>[
        CookingFlowStorageContainerSessionDraft(
          id: 'container-1',
          label: 'Topf',
          taraText: '420',
          taraUtensilId: 'pot-1',
          grossWeightText: '1800',
          portionCount: 4,
        ),
      ],
      ingredientContainerAssignments: <String, String>{
        'template:300g Linsen': 'container-1',
      },
    );

    final restored = CookingFlowSession.fromJson(session.toJson());

    expect(restored.templateId, 'template-1');
    expect(restored.step, CookingFlowSessionStep.finalize);
    expect(restored.taraUtensilId, 'pot-1');
    expect(restored.adjustments, <String>['extra onions']);
    expect(restored.summaryIngredients.single.name, 'Linsen');
    expect(restored.splitIntoPortions, isFalse);
    expect(restored.portionCount, 4);
    expect(restored.finalPortionCount, 6);
    expect(restored.introDraft.rowStates.single.editedName, 'Rote Linsen');
    expect(
      restored
          .introDraft
          .rowStates
          .single
          .selections
          .single
          .isAdditionalIngredient,
      isTrue,
    );
    expect(restored.storageContainers.single.taraUtensilId, 'pot-1');
    expect(restored.ingredientContainerAssignments, <String, String>{
      'template:300g Linsen': 'container-1',
    });
  });

  test('fromJson rejects malformed generated json', () {
    expect(
      () => CookingFlowSession.fromJson(<String, dynamic>{
        'template_id': 'template-1',
        'step': 'unknown',
        'tara_text': '1000',
        'adjustment_input_text': 'note',
        'adjustments': const <String>[],
        'summary_ingredients': const <Object?>[],
        'gross_weight_text': '1500',
        'split_into_portions': true,
        'portion_count': '2,5',
        'intro_draft': const <String, Object?>{'row_states': <Object?>[]},
        'intro_shopping_handled': false,
        'intro_shopping_baseline_inventory_item_ids': const <String>[],
      }),
      throwsA(isA<Object>()),
    );
  });
}
