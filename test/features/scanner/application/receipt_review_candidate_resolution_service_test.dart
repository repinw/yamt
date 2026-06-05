import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/application/'
    'receipt_review_candidate_resolution_service.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

void main() {
  test(
    'manual product result prefers reusable global item over external data',
    () {
      final service = ReceiptReviewCandidateResolutionService(
        matcher: GlobalFoodItemMatcher(),
      );
      final draft = ReceiptReviewItemDraft(item: _item(id: 'receipt'));
      final item = _item(
        id: 'manual',
        name: 'Verified Local Product',
        brand: 'Local Brand',
        barcode: '4006381333931',
        nutrition: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 120,
        ),
      );

      final result = service.applyManualProductResult(
        draft: draft,
        item: item,
        selectedProduct: const OffProductSearchResult(
          code: '4006381333931',
          name: 'Raw External Product',
          brand: 'External Brand',
          nutrition: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
            per100Kcal: 999,
          ),
          score: 99,
        ),
        selectedGlobalFoodItemId: 'global-local-product',
      );

      expect(result.selectedGlobalFoodItemId, 'global-local-product');
      expect(result.candidates.single.item.id, 'global-local-product');
      expect(result.candidates.single.item.name, 'Verified Local Product');
      expect(result.candidates.single.item.brand, 'Local Brand');
      expect(result.candidates.single.requiresPersistence, isFalse);
    },
  );
}

InventoryItem _item({
  required String id,
  String name = 'Receipt Product',
  String? brand,
  String? barcode,
  GlobalFoodNutrition? nutrition,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    weight: '100 g',
    brand: brand,
    barcode: barcode,
    nutrition: nutrition,
    origin: InventoryItemOrigin.manualAdd,
  );
}
