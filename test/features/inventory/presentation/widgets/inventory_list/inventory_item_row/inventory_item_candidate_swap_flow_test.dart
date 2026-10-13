import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'receipt_review_item_draft.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_candidate_swap_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/manual_product_search_editor_support.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_types.dart';

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

    test('generates a global id for a new product to write', () {
      final request = buildInventoryItemCandidateSwapRequestFromManualResult(
        result: InventoryReceiptManualProductResult(
          item: _item(weight: '100 g'),
          action: InventoryReceiptManualProductAction.addToInventory,
        ),
        matcher: GlobalFoodItemMatcher(),
      );

      expect(request.requiresGlobalPersistence, isTrue);
      expect(request.weight, '100 g');
      expect(request.resolvedProduct.id, startsWith('global-food-'));
      expect(request.resolvedProduct.packageWeight, '100 g');
    });

    test('writes a new product made in the editor to the catalog', () {
      final request = _requestFromEditor(
        (editor) => editor
          ..updateNameText('Porridge')
          ..updateWeightAmount('500')
          ..updateKcalText('370'),
      );

      expect(request.requiresGlobalPersistence, isTrue);
      expect(request.resolvedProduct.id, startsWith('global-food-'));
      expect(request.resolvedProduct.name, 'Porridge');
    });

    test('keeps a product whose front photo shows no package out of the '
        'catalog (#658)', () {
      final request = _requestFromEditor(
        (editor) => editor
          ..updateNameText('Brot vom Bäcker')
          ..updateWeightAmount('500')
          ..updateKcalText('250')
          ..updateFrontShowsNoPackage(value: true),
        photoImageUrl: _privatePhoto,
      );

      expect(request.requiresGlobalPersistence, isFalse);
      expect(request.resolvedProduct.name, 'Brot vom Bäcker');
      // Not in the catalog, so the item does not point at a catalog id.
      expect(isPendingGlobalFoodItemId(request.resolvedProduct.id), isTrue);
      // The private photo stays for the user's own item.
      expect(request.resolvedProduct.imageUrl, _privatePhoto);
    });

    test('keeps a private Open Food Facts pick out of the catalog (#658)', () {
      final request = buildInventoryItemCandidateSwapRequestFromManualResult(
        result: InventoryReceiptManualProductResult(
          item: _item(weight: '1 l'),
          action: InventoryReceiptManualProductAction.addToInventory,
          selectedProduct: _offMilk,
          requiresGlobalPersistence: false,
        ),
        matcher: GlobalFoodItemMatcher(),
      );

      expect(request.requiresGlobalPersistence, isFalse);
      expect(isPendingGlobalFoodItemId(request.resolvedProduct.id), isTrue);
      expect(request.resolvedProduct.packageWeight, '1 l');
    });

    test('keeps a scanned product whose front photo shows no package out of '
        'the catalog (#658)', () {
      final request = _requestFromEditor(
        (editor) => editor
          ..applyScannedProduct(_offMilk)
          ..updateFrontShowsNoPackage(value: true),
        photoImageUrl: _privatePhoto,
      );

      expect(request.requiresGlobalPersistence, isFalse);
      expect(isPendingGlobalFoodItemId(request.resolvedProduct.id), isTrue);
    });

    test('writes a scanned product with a package to the catalog', () {
      final request = _requestFromEditor(
        (editor) => editor.applyScannedProduct(_offMilk),
      );

      expect(request.requiresGlobalPersistence, isTrue);
      expect(request.resolvedProduct.id, 'off-4006381333931');
    });
  });
}

const _offMilk = OffProductSearchResult(
  code: '4006381333931',
  name: 'Selected Milk',
  brand: 'Brand',
  packageWeight: '1 l',
  score: 42,
);

const _privatePhoto = 'gs://bucket/users/user-1/food_photos/photo-1.jpg';

/// The swap request for the food saved in the editor that the Replace flow
/// opens for the Vorrat item, after [edit].
InventoryItemCandidateSwapRequest _requestFromEditor(
  void Function(InventoryReceiptManualProductController editor) edit, {
  String? photoImageUrl,
}) {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final provider = inventoryReceiptManualProductControllerProvider(
    InventoryReceiptManualProductConfig(item: _item(weight: '1 l')),
  );
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  final editor = container.read(provider.notifier);
  edit(editor);
  return buildInventoryItemCandidateSwapRequestFromManualResult(
    result: buildSaveProductResult(
      payload: editor.buildSavePayload(photoImageUrl: photoImageUrl)!,
      action: InventoryReceiptManualProductAction.addToInventory,
    ),
    matcher: GlobalFoodItemMatcher(),
  );
}

InventoryItem _item({String name = 'Milk', String? brand, String? weight}) {
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
