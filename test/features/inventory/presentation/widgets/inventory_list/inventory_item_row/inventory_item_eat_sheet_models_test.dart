import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/serving_suggestion_resolver.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_list/inventory_item_row/inventory_item_eat_sheet_models.dart';

void main() {
  test(
    'amount mode option only treats saved measured portions as portions',
    () {
      expect(
        const InventoryItemEatAmountModeOption(
          id: 'slice',
          label: 'Slice',
          amount: 40,
          unit: ConsumedUnit.grams,
        ).isPortion,
        isTrue,
      );
      expect(
        const InventoryItemEatAmountModeOption(
          id: 'manual',
          label: 'Manual',
          isNewPortion: true,
        ).isPortion,
        isFalse,
      );
      expect(
        const InventoryItemEatAmountModeOption(
          id: 'amount-only',
          label: 'Amount only',
          amount: 40,
        ).isPortion,
        isFalse,
      );
      expect(
        const InventoryItemEatAmountModeOption(
          id: 'unit-only',
          label: 'Unit only',
          unit: ConsumedUnit.grams,
        ).isPortion,
        isFalse,
      );
    },
  );

  test('manual portion section data keeps callbacks and suggestions', () {
    final controller = TextEditingController(text: '100');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    var changedAmount = '';
    var changedUnit = ConsumedUnit.grams;
    var submitted = false;
    ({double amount, ConsumedUnit unit})? pressedSuggestion;

    final data = InventoryItemEatSheetManualPortionSectionData(
      title: 'Save portion',
      controller: controller,
      focusNode: focusNode,
      errorText: null,
      selectedUnit: ConsumedUnit.milliliters,
      suggestions: const <PortionSuggestion>[
        PortionSuggestion(
          label: 'Cup',
          amount: 200,
          unit: ConsumedUnit.milliliters,
        ),
      ],
      onAmountChanged: (value) {
        changedAmount = value;
      },
      onUnitChanged: (value) {
        changedUnit = value;
      },
      onSubmitted: () {
        submitted = true;
      },
      onSuggestionPressed: ({required amount, required unit}) {
        pressedSuggestion = (amount: amount, unit: unit);
      },
    );

    data.onAmountChanged('125');
    data.onUnitChanged(ConsumedUnit.milliliters);
    data.onSubmitted();
    data.onSuggestionPressed(amount: 200, unit: ConsumedUnit.milliliters);

    expect(data.title, 'Save portion');
    expect(data.controller.text, '100');
    expect(data.focusNode, focusNode);
    expect(data.selectedUnit, ConsumedUnit.milliliters);
    expect(data.suggestions.single.label, 'Cup');
    expect(changedAmount, '125');
    expect(changedUnit, ConsumedUnit.milliliters);
    expect(submitted, isTrue);
    expect(
      pressedSuggestion,
      (amount: 200, unit: ConsumedUnit.milliliters),
    );
  });
}
