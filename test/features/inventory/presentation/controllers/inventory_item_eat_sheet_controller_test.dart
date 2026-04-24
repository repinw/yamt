import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_item_eat_sheet_controller.dart';

InventoryItem _pieceItem() {
  return InventoryItem.create(
    id: 'piece-item',
    name: 'Apple',
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: 3,
    initialQuantity: 3,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 52,
    ),
  );
}

InventoryItem _fixedUnitItem() {
  return InventoryItem.create(
    id: 'fixed-unit-item',
    name: 'Cheese',
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 200,
    currentAmount: 200,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 350,
    ),
  );
}

void main() {
  group('InventoryItemEatSheetController', () {
    test('requires manual portion before logging raw piece items', () {
      final controller = InventoryItemEatSheetController(
        item: _pieceItem(),
        maxAmount: 3,
      );

      final draft = controller.buildSubmissionDraft(
        usesPortionMode: false,
        inventoryAmountText: '2',
        portionCountText: '',
        portionAmountText: '',
        portionUnit: ConsumedUnit.grams,
        inedibleAmountText: '',
      );

      expect(draft.hasValidationErrors, isFalse);
      expect(draft.needsManualCalorieAmount, isTrue);
      expect(draft.inventoryAmount, 2);
    });

    test('maps portion count to piece inventory amount and total calories', () {
      final controller = InventoryItemEatSheetController(
        item: _pieceItem(),
        maxAmount: 3,
      );

      final draft = controller.buildSubmissionDraft(
        usesPortionMode: true,
        inventoryAmountText: '',
        portionCountText: '2',
        portionAmountText: '80',
        portionUnit: ConsumedUnit.grams,
        inedibleAmountText: '',
      );

      expect(draft.hasValidationErrors, isFalse);
      expect(draft.inventoryAmount, 2);
      expect(draft.portionBaseAmount, 80);
      expect(draft.portionTotalAmount, 160);
    });

    test('reduces fixed-unit calories by non-edible amount', () {
      final controller = InventoryItemEatSheetController(
        item: _fixedUnitItem(),
        maxAmount: 200,
      );

      final draft = controller.buildSubmissionDraft(
        usesPortionMode: false,
        inventoryAmountText: '125',
        portionCountText: '',
        portionAmountText: '',
        portionUnit: ConsumedUnit.grams,
        inedibleAmountText: '25',
      );

      expect(draft.hasValidationErrors, isFalse);
      expect(draft.inventoryAmount, 125);
      expect(draft.fixedUnitCalorieAmount, 100);
    });
  });
}
