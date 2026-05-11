import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

void main() {
  test('parses localized piece units', () {
    expect(
      cookingFlowParseInventoryRequirement(
        '2 stueck',
        localeCode: 'de',
      )?.unitCode,
      cookingFlowPieceUnitCode,
    );
    expect(
      cookingFlowParseInventoryRequirement(
        '2 stueck',
        localeCode: 'de',
      )?.amount,
      2,
    );
    expect(
      cookingFlowParseInventoryRequirement('2 stueck', localeCode: 'en'),
      isNull,
    );
  });

  test('parses milligrams into gram requirement', () {
    final requirement = cookingFlowParseInventoryRequirement(
      '500 mg',
      localeCode: 'de',
    );

    expect(requirement?.unitCode, 'g');
    expect(requirement?.amount, closeTo(0.5, 1e-12));
  });

  test('parses German thousands and decimal separators', () {
    final requirement = cookingFlowParseInventoryRequirement(
      '1.000,50 g',
      localeCode: 'de',
    );

    expect(requirement?.unitCode, 'g');
    expect(requirement?.amount, 1000.5);
  });

  test('reports shortage and ignores additional ingredient selections', () {
    final conflict = cookingFlowInventoryConflictForRow(
      row: const CookingFlowInventoryCheckRowData(
        rawIngredient: '500g Mehl',
        name: 'Mehl',
        amountLabel: '500 g',
      ),
      selectedSelections: const <CookingFlowInventoryAssignmentSelection>[
        CookingFlowInventoryAssignmentSelection(itemId: 'flour'),
        CookingFlowInventoryAssignmentSelection(
          itemId: 'extra-flour',
          isAdditionalIngredient: true,
        ),
      ],
      inventoryItems: <InventoryItem>[
        _amountItem(id: 'flour', name: 'Mehl', currentAmount: 300),
        _amountItem(
          id: 'extra-flour',
          name: 'Mehl Reserve',
          currentAmount: 500,
        ),
      ],
      localeCode: 'de',
    );

    expect(conflict?.kind, CookingFlowInventoryConflictKind.shortage);
    expect(conflict?.availableAmountLabel, '300g');
    expect(conflict?.missingAmountLabel, '200g');
  });

  test('builds usage preview for compatible amount selections', () {
    final preview = cookingFlowInventoryUsagePreview(
      amountLabel: '500 g',
      selectedAction: CookingFlowInventoryRowAction.assigned,
      selectedSelections: const <CookingFlowInventoryAssignmentSelection>[
        CookingFlowInventoryAssignmentSelection(itemId: 'flour'),
      ],
      inventoryItems: <InventoryItem>[
        _amountItem(id: 'flour', name: 'Mehl', currentAmount: 800),
      ],
      localeCode: 'de',
    );

    expect(preview?.usedAmountLabel, '500g');
    expect(preview?.remainingAmountLabel, '300g');
  });

  test('reports unit conversion conflict for pieces backed by grams', () {
    final conflict = cookingFlowInventoryConflictForRow(
      row: const CookingFlowInventoryCheckRowData(
        rawIngredient: '2 Eier',
        name: 'Eier',
        amountLabel: '2',
      ),
      selectedSelections: const <CookingFlowInventoryAssignmentSelection>[
        CookingFlowInventoryAssignmentSelection(itemId: 'eggs'),
      ],
      inventoryItems: <InventoryItem>[
        _amountItem(id: 'eggs', name: 'Eier', currentAmount: 120),
      ],
      localeCode: 'de',
    );

    expect(conflict?.kind, CookingFlowInventoryConflictKind.unitConversion);
    expect(conflict?.requiredUnitCode, cookingFlowPieceUnitCode);
    expect(conflict?.selectedUnitCode, 'g');
  });
}

InventoryItem _amountItem({
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
