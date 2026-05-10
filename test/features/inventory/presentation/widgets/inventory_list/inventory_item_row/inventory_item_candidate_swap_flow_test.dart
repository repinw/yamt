import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_candidate_swap_flow.dart';
import 'package:yamt/features/product_search/domain/'
    'receipt_review_item_draft.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_models.dart';

void main() {
  group('buildInventoryItemCandidateSwapRequestFromCandidate', () {
    test('returns selected candidate and preserves source item weight', () {
      final sourceItem = _item(weight: '500 g');
      final candidateItem = _globalFoodItem(id: 'candidate-1');
      final draft = ReceiptReviewItemDraft(
        item: sourceItem,
        candidates: <GlobalFoodMatchCandidate>[
          GlobalFoodMatchCandidate(
            item: candidateItem,
            score: 10,
            reason: GlobalFoodMatchReason.nameExact,
            requiresPersistence: true,
          ),
        ],
      );

      final request = buildInventoryItemCandidateSwapRequestFromCandidate(
        draft: draft,
        candidateId: 'candidate-1',
        sourceItem: sourceItem,
      );

      expect(request?.resolvedProduct, candidateItem);
      expect(request?.requiresGlobalPersistence, isTrue);
      expect(request?.weight, '500 g');
    });

    test(
      'falls back to candidate package weight when source weight is empty',
      () {
        final sourceItem = _item();
        final candidateItem = _globalFoodItem(
          id: 'candidate-1',
          packageWeight: '750 ml',
        );
        final draft = ReceiptReviewItemDraft(
          item: sourceItem,
          candidates: <GlobalFoodMatchCandidate>[
            GlobalFoodMatchCandidate(
              item: candidateItem,
              score: 10,
              reason: GlobalFoodMatchReason.nameExact,
            ),
          ],
        );

        final request = buildInventoryItemCandidateSwapRequestFromCandidate(
          draft: draft,
          candidateId: 'candidate-1',
          sourceItem: sourceItem,
        );

        expect(request?.weight, '750 ml');
      },
    );

    test('returns null for empty or unknown candidate ids', () {
      final sourceItem = _item();
      final draft = ReceiptReviewItemDraft(
        item: sourceItem,
        candidates: <GlobalFoodMatchCandidate>[
          GlobalFoodMatchCandidate(
            item: _globalFoodItem(id: 'candidate-1'),
            score: 10,
            reason: GlobalFoodMatchReason.nameExact,
          ),
        ],
      );

      expect(
        buildInventoryItemCandidateSwapRequestFromCandidate(
          draft: draft,
          candidateId: null,
          sourceItem: sourceItem,
        ),
        isNull,
      );
      expect(
        buildInventoryItemCandidateSwapRequestFromCandidate(
          draft: draft,
          candidateId: 'missing',
          sourceItem: sourceItem,
        ),
        isNull,
      );
    });
  });

  group('buildInventoryItemCandidateSwapRequestFromManualResult', () {
    test(
      'maps selected OFF product through matcher and keeps inventory weight',
      () {
        const selectedProduct = OffProductSearchResult(
          code: '4006381333931',
          name: 'Selected Milk',
          brand: 'Brand',
          packageWeight: '1 l',
          servingSize: '250 ml',
          servingQuantity: 250,
          servingQuantityUnit: 'ml',
          score: 42,
        );
        final request = buildInventoryItemCandidateSwapRequestFromManualResult(
          result: InventoryReceiptManualProductResult(
            item: _item(
              name: 'Manual Milk',
              brand: 'Manual Brand',
              weight: '950 ml',
            ),
            action: InventoryReceiptManualProductAction.addToInventory,
            selectedProduct: selectedProduct,
          ),
          matcher: GlobalFoodItemMatcher(),
        );

        expect(request.requiresGlobalPersistence, isTrue);
        expect(request.weight, '950 ml');
        expect(request.resolvedProduct.id, 'off-4006381333931');
        expect(request.resolvedProduct.name, 'Manual Milk');
        expect(request.resolvedProduct.brand, 'Manual Brand');
        expect(request.resolvedProduct.packageWeight, '1 l');
        expect(request.resolvedProduct.servingSize, '250 ml');
        expect(request.resolvedProduct.servingQuantity, 250);
        expect(request.resolvedProduct.servingQuantityUnit, 'ml');
      },
    );

    test('reuses selected global id without forcing persistence', () {
      final request = buildInventoryItemCandidateSwapRequestFromManualResult(
        result: InventoryReceiptManualProductResult(
          item: _item(weight: '250 g'),
          action: InventoryReceiptManualProductAction.addToInventory,
          selectedGlobalFoodItemId: 'global-1',
          requiresGlobalPersistence: false,
        ),
        matcher: GlobalFoodItemMatcher(),
      );

      expect(request.requiresGlobalPersistence, isFalse);
      expect(request.weight, '250 g');
      expect(request.resolvedProduct.id, 'global-1');
      expect(request.resolvedProduct.packageWeight, '250 g');
    });

    test(
      'generates a global id and requires persistence for manual-only data',
      () {
        final request = buildInventoryItemCandidateSwapRequestFromManualResult(
          result: InventoryReceiptManualProductResult(
            item: _item(weight: '100 g'),
            action: InventoryReceiptManualProductAction.addToInventory,
            requiresGlobalPersistence: false,
          ),
          matcher: GlobalFoodItemMatcher(),
        );

        expect(request.requiresGlobalPersistence, isTrue);
        expect(request.weight, '100 g');
        expect(request.resolvedProduct.id, startsWith('global-food-'));
        expect(request.resolvedProduct.packageWeight, '100 g');
      },
    );
  });
}

InventoryItem _item({
  String name = 'Milk',
  String? brand,
  String? weight,
}) {
  return InventoryItem.create(
    id: 'item-1',
    name: name,
    brand: brand,
    weight: weight,
    entryDate: DateTime.utc(2026),
    storeName: 'Store',
    quantity: 1,
  );
}

GlobalFoodItem _globalFoodItem({
  required String id,
  String packageWeight = '1 kg',
}) {
  return GlobalFoodItem.create(
    id: id,
    name: 'Candidate',
    now: DateTime.utc(2026),
    packageWeight: packageWeight,
  );
}
