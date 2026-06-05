import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_candidate_lookup.dart';
import 'package:yamt/features/inventory/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft_extensions.dart';

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 120,
);

final DateTime _now = DateTime.parse('2026-03-01T12:00:00Z');

InventoryItem _item({
  String id = 'item-1',
  String name = 'Receipt Milk',
  String? brand,
  String? category,
  String? barcode,
  String? weight = '500 g',
  int quantity = 1,
  GlobalFoodNutrition? nutrition,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: _now,
    storeName: 'Store',
    quantity: quantity,
    brand: brand,
    category: category,
    barcode: barcode,
    weight: weight,
    nutrition: nutrition,
  );
}

GlobalFoodItem _globalFood({
  String id = 'food-1',
  String name = 'Canonical Milk',
  String? brand = 'Brand',
  String? category = 'Dairy',
  String? barcode = '123456',
  String? packageWeight = '500 g',
  GlobalFoodNutrition? nutrition = _nutrition,
}) {
  return GlobalFoodItem.create(
    id: id,
    name: name,
    now: _now,
    brand: brand,
    category: category,
    barcode: barcode,
    packageWeight: packageWeight,
    nutrition: nutrition,
  );
}

GlobalFoodMatchCandidate _candidate({GlobalFoodItem? item}) {
  return GlobalFoodMatchCandidate(
    item: item ?? _globalFood(),
    score: 91,
    reason: GlobalFoodMatchReason.nameBrandStrong,
  );
}

ReceiptReviewItemDraft _resolvedDraft({
  required InventoryItem lookupItem,
  required GlobalFoodMatchCandidate candidate,
}) {
  return ReceiptReviewItemDraft(
        item: lookupItem,
        candidates: <GlobalFoodMatchCandidate>[candidate],
      )
      .applyAutomaticSelection(candidate.item.id)
      .syncToSelectedCandidate()
      .prepareForReceiptReview();
}

void main() {
  test('candidate lookup input ignores quantity-only changes', () {
    final lookupItem = _item();
    final currentItem = lookupItem.copyWith(quantity: 3);

    expect(
      hasSameReceiptReviewCandidateLookupInput(lookupItem, currentItem),
      isTrue,
    );
  });

  test('candidate lookup input changes when searchable fields change', () {
    final lookupItem = _item(name: 'Milk', brand: 'Brand');
    final currentItem = lookupItem.copyWith(brand: 'Other Brand');

    expect(
      hasSameReceiptReviewCandidateLookupInput(lookupItem, currentItem),
      isFalse,
    );
  });

  test('merge applies resolved candidate while preserving confirmation', () {
    final lookupItem = _item();
    final candidate = _candidate();
    final currentDraft = ReceiptReviewItemDraft(
      item: lookupItem,
      isConfirmed: true,
    );

    final result = mergeResolvedReceiptReviewCandidates(
      currentDraft: currentDraft,
      resolvedDraft: _resolvedDraft(
        lookupItem: lookupItem,
        candidate: candidate,
      ),
      lookupItem: lookupItem,
    );

    expect(result.isConfirmed, isTrue);
    expect(result.selectedGlobalFoodItemId, 'food-1');
    expect(result.candidates, hasLength(1));
    expect(result.item.name, 'Canonical Milk');
    expect(result.item.barcode, '123456');
    expect(result.item.nutrition, _nutrition);
  });

  test('merge preserves product edits made while lookup was pending', () {
    final lookupItem = _item();
    final candidate = _candidate();
    final currentDraft = ReceiptReviewItemDraft(
      item: lookupItem.copyWith(category: 'User Category'),
      isConfirmed: true,
    );

    final result = mergeResolvedReceiptReviewCandidates(
      currentDraft: currentDraft,
      resolvedDraft: _resolvedDraft(
        lookupItem: lookupItem,
        candidate: candidate,
      ),
      lookupItem: lookupItem,
    );

    expect(result.isConfirmed, isTrue);
    expect(result.selectedGlobalFoodItemId, 'food-1');
    expect(result.candidates, hasLength(1));
    expect(result.item.name, 'Receipt Milk');
    expect(result.item.category, 'User Category');
    expect(result.item.barcode, isNull);
  });
}
