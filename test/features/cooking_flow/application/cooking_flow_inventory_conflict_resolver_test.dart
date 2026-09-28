import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_requirement.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

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

  group('spoon-measured amounts', () {
    test('parses EL into the tablespoon unit code', () {
      final requirement = cookingFlowParseInventoryRequirement(
        '8 EL',
        localeCode: 'de',
      );

      expect(requirement?.unitCode, cookingFlowTablespoonUnitCode);
      expect(requirement?.amount, 8);
    });

    test('parses TL into the teaspoon unit code', () {
      final requirement = cookingFlowParseInventoryRequirement(
        '2 TL',
        localeCode: 'de',
      );

      expect(requirement?.unitCode, cookingFlowTeaspoonUnitCode);
      expect(requirement?.amount, 2);
    });

    test('parses tbsp and tsp into the same canonical unit codes', () {
      expect(
        cookingFlowParseInventoryRequirement(
          '1 tbsp',
          localeCode: 'en',
        )?.unitCode,
        cookingFlowTablespoonUnitCode,
      );
      expect(
        cookingFlowParseInventoryRequirement(
          '1 tsp',
          localeCode: 'en',
        )?.unitCode,
        cookingFlowTeaspoonUnitCode,
      );
    });

    test(
      'reports a unit conversion conflict for EL requirement backed by grams',
      () {
        final conflict = cookingFlowInventoryConflictForRow(
          row: const CookingFlowInventoryCheckRowData(
            rawIngredient: '4 EL Milch (oder Sahne)',
            name: 'Milch (oder Sahne)',
            amountLabel: '8 EL',
          ),
          selectedSelections: const <CookingFlowInventoryAssignmentSelection>[
            CookingFlowInventoryAssignmentSelection(itemId: 'milk'),
          ],
          inventoryItems: <InventoryItem>[
            _amountItem(id: 'milk', name: 'Milch', currentAmount: 1000),
          ],
          localeCode: 'de',
        );

        expect(conflict?.kind, CookingFlowInventoryConflictKind.unitConversion);
        expect(conflict?.requiredUnitCode, cookingFlowTablespoonUnitCode);
        expect(conflict?.selectedUnitCode, 'g');
      },
    );

    test('convert-unit resolution deducts stock in grams', () {
      final requirement = cookingFlowParseInventoryRequirement(
        '8 EL',
        localeCode: 'de',
      )!;
      final unitCode = cookingFlowSelectedUnitConflictCode(
        selectedItems: <InventoryItem>[
          _amountItem(id: 'milk', name: 'Milch', currentAmount: 1000),
        ],
        requirement: requirement,
      );

      expect(unitCode, 'g');
      // 8 EL at the default 15 g/EL conversion becomes 120 g of deduction.
      expect(requirement.amount * cookingFlowDefaultGramsPerTablespoon, 120);
    });
  });

  group('piece-tracked stock', () {
    test('labels the stock in whole pieces', () {
      expect(cookingFlowInventoryAmountLabel(_eggPack(pieces: 10)), '10 pc');
      expect(
        cookingFlowInventoryAmountLabel(_eggPack(pieces: 6, milliPieces: 500)),
        '6.5 pc',
      );
    });

    test('previews used and remaining pieces', () {
      final preview = cookingFlowInventoryUsagePreview(
        amountLabel: '8',
        selectedAction: CookingFlowInventoryRowAction.assigned,
        selectedSelections: const <CookingFlowInventoryAssignmentSelection>[
          CookingFlowInventoryAssignmentSelection(itemId: 'eggs'),
        ],
        inventoryItems: <InventoryItem>[_eggPack(pieces: 10)],
        localeCode: 'de',
      );

      expect(preview?.usedAmountLabel, '8');
      expect(preview?.remainingAmountLabel, '2');
    });

    test('reports shortage in whole pieces', () {
      final conflict = cookingFlowInventoryConflictForRow(
        row: const CookingFlowInventoryCheckRowData(
          rawIngredient: '12 Eier',
          name: 'Eier',
          amountLabel: '12',
        ),
        selectedSelections: const <CookingFlowInventoryAssignmentSelection>[
          CookingFlowInventoryAssignmentSelection(itemId: 'eggs'),
        ],
        inventoryItems: <InventoryItem>[_eggPack(pieces: 10)],
        localeCode: 'de',
      );

      expect(conflict?.kind, CookingFlowInventoryConflictKind.shortage);
      expect(conflict?.availableAmountLabel, '10');
      expect(conflict?.missingAmountLabel, '2');
    });

    test('adjust-template row shows the available pieces', () {
      final label = cookingFlowInventoryRowDisplayAmountLabel(
        row: const CookingFlowInventoryCheckRowData(
          rawIngredient: '12 Eier',
          name: 'Eier',
          amountLabel: '12',
        ),
        selectedAction: CookingFlowInventoryRowAction.assigned,
        selectedSelections: const <CookingFlowInventoryAssignmentSelection>[
          CookingFlowInventoryAssignmentSelection(itemId: 'eggs'),
        ],
        inventoryItems: <InventoryItem>[_eggPack(pieces: 10)],
        conflictResolution:
            CookingFlowInventoryConflictResolution.adjustTemplate,
        localeCode: 'de',
      );

      expect(label, '10');
    });

    test('formats stored component pieces as whole pieces', () {
      final eggs = _eggPack(pieces: 10);
      final component = PreparedMealComponent(
        inventoryItemId: eggs.id,
        name: eggs.name,
        brand: null,
        imageUrl: null,
        usedAmount: 8 * inventoryPieceAmountScale,
        usedUnit: InventoryAmountUnit.piece,
        totalKcal: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        sourceItemSnapshot: eggs,
      );

      expect(
        cookingFlowComponentAmountValue(
          component,
          amount: component.usedAmount,
        ),
        '8',
      );
    });
  });
}

InventoryItem _eggPack({required int pieces, int milliPieces = 0}) {
  final storedAmount = pieces * inventoryPieceAmountScale + milliPieces;
  return InventoryItem.create(
    id: 'eggs',
    name: 'Eier',
    entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
    storeName: 'Test',
    quantity: 1,
    initialAmount: storedAmount,
    currentAmount: storedAmount,
    amountScale: inventoryPieceAmountScale,
    amountUnit: InventoryAmountUnit.piece,
  );
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
