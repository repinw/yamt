import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_result.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_item_edit_policy.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_selection.dart';

InventoryReceiptManualProductSelection _selection({
  OffProductSearchResult? externalProduct,
}) {
  return InventoryReceiptManualProductSelection(
    source: InventoryReceiptManualProductSelectionSource.recentInventory,
    name: 'Milch',
    barcode: '4000000000000',
    externalProduct: externalProduct,
  );
}

void main() {
  group('manualProductRequiresGlobalPersistence', () {
    test('an AI estimate stays the user own', () {
      expect(
        manualProductRequiresGlobalPersistence(
          selection: null,
          editKind: GlobalFoodItemEditKind.patchExisting,
          aiEstimated: true,
        ),
        isFalse,
      );
    });

    test('a food without a selection goes to the catalog', () {
      expect(
        manualProductRequiresGlobalPersistence(
          selection: null,
          editKind: GlobalFoodItemEditKind.unchanged,
          aiEstimated: false,
        ),
        isTrue,
      );
    });

    test('a search result goes to the catalog', () {
      expect(
        manualProductRequiresGlobalPersistence(
          selection: _selection(
            externalProduct: const OffProductSearchResult(
              code: '4000000000000',
              name: 'Milch',
              score: 1,
            ),
          ),
          editKind: GlobalFoodItemEditKind.unchanged,
          aiEstimated: false,
        ),
        isTrue,
      );
    });

    test('a stock food goes to the catalog only when patched', () {
      bool requires(GlobalFoodItemEditKind editKind) =>
          manualProductRequiresGlobalPersistence(
            selection: _selection(),
            editKind: editKind,
            aiEstimated: false,
          );

      expect(requires(GlobalFoodItemEditKind.unchanged), isFalse);
      expect(requires(GlobalFoodItemEditKind.createNewCandidate), isFalse);
      expect(requires(GlobalFoodItemEditKind.patchExisting), isTrue);
    });
  });

  test('manualProductHasSameNutrition ignores tiny rounding only', () {
    const base = GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
      per100Kcal: 100,
    );

    expect(
      manualProductHasSameNutrition(
        base,
        base.copyWith(per100Kcal: 100.0000001),
      ),
      isTrue,
    );
    expect(
      manualProductHasSameNutrition(base, base.copyWith(per100Kcal: 101)),
      isFalse,
    );
    expect(
      manualProductHasSameNutrition(base, base.copyWith(per100Fiber: 0)),
      isFalse,
    );
  });
}
