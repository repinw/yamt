import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';

void main() {
  test('copyWith updates fields and keeps source ingredient by default', () {
    const draft = CookingFlowSummaryIngredientDraft(
      key: 'template:300g Linsen',
      name: 'Linsen',
      amount: '300',
      unitCode: 'g',
      inventoryItemIds: <String>['item-1'],
      kind: CookingFlowSummaryIngredientKind.template,
      sourceIngredient: '300g Linsen',
    );

    final updated = draft.copyWith(
      name: 'Rote Linsen',
      amount: '350',
      inventoryItemIds: <String>['item-2'],
    );

    expect(updated.key, draft.key);
    expect(updated.name, 'Rote Linsen');
    expect(updated.amount, '350');
    expect(updated.unitCode, 'g');
    expect(updated.inventoryItemIds, <String>['item-2']);
    expect(updated.kind, CookingFlowSummaryIngredientKind.template);
    expect(updated.sourceIngredient, '300g Linsen');
  });

  test('copyWith can clear optional source ingredient', () {
    const draft = CookingFlowSummaryIngredientDraft(
      key: 'additional:item-1',
      name: 'Salz',
      amount: '1',
      unitCode: 'pc',
      inventoryItemIds: <String>['item-1'],
      kind: CookingFlowSummaryIngredientKind.additional,
      sourceIngredient: 'Salz',
    );

    final updated = draft.copyWith(sourceIngredient: null);

    expect(updated.sourceIngredient, isNull);
  });

  test('default ingredients provide stable template rows', () {
    expect(defaultCookingFlowSummaryIngredients, hasLength(3));
    expect(
      defaultCookingFlowSummaryIngredients.map((draft) => draft.kind),
      everyElement(CookingFlowSummaryIngredientKind.template),
    );
    expect(
      defaultCookingFlowSummaryIngredients.map((draft) => draft.key),
      containsAll(<String>[
        'template:300g Linsen',
        'template:500ml Passata',
        'template:2 Dosen Kidneybohnen',
      ]),
    );
  });
}
