import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/scanner/data/adapters/'
    'yamt_receipt_manual_product_picker.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';

void main() {
  group('YamtReceiptManualProductPicker', () {
    test('mapResultToCandidate maps inventory item and nutrition cleanly', () {
      final now = DateTime.now();
      final item = InventoryItem.create(
        id: 'inv-item-123',
        name: 'Hafermilch Barista',
        entryDate: now,
        storeName: 'Rewe',
        quantity: 1,
        brand: 'Oatly',
        barcode: '7394376616037',
        weight: '1000 ml',
        nutrition: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 59,
          per100Fat: 3,
          per100Carbs: 6.6,
          per100Protein: 1,
        ),
      );

      final result = InventoryReceiptManualProductResult(
        item: item,
        action: InventoryReceiptManualProductAction.addToInventory,
        selectedGlobalFoodItemId: 'global-food-456',
      );

      final candidate = YamtReceiptManualProductPicker.mapResultToCandidate(
        result,
      );

      expect(candidate.id, 'global-food-456');
      expect(candidate.name, 'Hafermilch Barista');
      expect(candidate.brand, 'Oatly');
      expect(candidate.barcode, '7394376616037');
      expect(candidate.packageSize, '1000 ml');
      expect(candidate.source, CandidateSource.manualSearch);
      expect(candidate.hasNutrition, isTrue);
      expect(candidate.kcal, 59.0);
      expect(candidate.fat, 3.0);
      expect(candidate.carbs, 6.6);
      expect(candidate.protein, 1.0);
    });

    test('mapResultToCandidate handles null nutrition gracefully', () {
      final now = DateTime.now();
      final item = InventoryItem.create(
        id: 'inv-item-789',
        name: 'Apfel lose',
        entryDate: now,
        storeName: 'Aldi',
        quantity: 1,
      );

      final result = InventoryReceiptManualProductResult(
        item: item,
        action: InventoryReceiptManualProductAction.addToInventory,
      );

      final candidate = YamtReceiptManualProductPicker.mapResultToCandidate(
        result,
      );

      expect(candidate.id, 'inv-item-789');
      expect(candidate.name, 'Apfel lose');
      expect(candidate.hasNutrition, isFalse);
      expect(candidate.nutrition, isNull);
    });
  });
}
