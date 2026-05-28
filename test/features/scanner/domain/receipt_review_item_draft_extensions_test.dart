import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
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
  String? imageUrl,
  String? foodFingerprint,
  String? weight,
  InventoryAmountUnit? amountUnit,
  GlobalFoodNutrition? nutrition,
  bool isDiscount = false,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: _now,
    storeName: 'Store',
    quantity: 1,
    brand: brand,
    category: category,
    barcode: barcode,
    imageUrl: imageUrl,
    foodFingerprint: foodFingerprint,
    weight: weight,
    amountUnit: amountUnit,
    nutrition: nutrition,
    isDiscount: isDiscount,
  );
}

GlobalFoodItem _globalFood({
  String id = 'food-1',
  String name = 'Canonical Milk',
  String? brand = 'Brand',
  String? category = 'Dairy',
  String? barcode = '123456',
  String? imageUrl = 'https://example.test/milk.png',
  String? foodFingerprint = 'milk-brand',
  String? packageWeight = '750 g',
  String? servingSize = '100 g',
  double? servingQuantity = 100,
  String? servingQuantityUnit = 'g',
  GlobalFoodNutrition? nutrition = _nutrition,
}) {
  return GlobalFoodItem.create(
    id: id,
    name: name,
    now: _now,
    brand: brand,
    category: category,
    barcode: barcode,
    imageUrl: imageUrl,
    packageWeight: packageWeight,
    foodFingerprint: foodFingerprint,
    servingSize: servingSize,
    servingQuantity: servingQuantity,
    servingQuantityUnit: servingQuantityUnit,
    nutrition: nutrition,
  );
}

GlobalFoodMatchCandidate _candidate({
  GlobalFoodItem? item,
  double score = 91,
}) {
  return GlobalFoodMatchCandidate(
    item: item ?? _globalFood(),
    score: score,
    reason: GlobalFoodMatchReason.nameBrandStrong,
  );
}

ReceiptReviewItemDraft _draft({
  InventoryItem? item,
  List<GlobalFoodMatchCandidate>? candidates,
  String? selectedGlobalFoodItemId,
}) {
  return ReceiptReviewItemDraft(
    item: item ?? _item(),
    candidates: candidates ?? const <GlobalFoodMatchCandidate>[],
    selectedGlobalFoodItemId: selectedGlobalFoodItemId,
  );
}

void main() {
  group('prepareForReceiptReview', () {
    test('uses receipt weight and clears previous confirmation', () {
      final draft = _draft(
        item: _item(
          weight: '500',
          amountUnit: InventoryAmountUnit.gram,
          nutrition: _nutrition,
        ),
      ).copyWith(isConfirmed: true, weightNeedsAttention: true);

      final result = draft.prepareForReceiptReview();

      expect(result.isConfirmed, isFalse);
      expect(result.weightNeedsAttention, isFalse);
      expect(result.item.initialAmount, 500);
      expect(result.item.currentAmount, 500);
      expect(result.item.amountUnit, InventoryAmountUnit.gram);
    });

    test('uses selected candidate weight when receipt weight is missing', () {
      final candidate = _candidate();
      final result = _draft(
        candidates: <GlobalFoodMatchCandidate>[candidate],
      ).selectCandidate(candidate.item.id).prepareForReceiptReview();

      expect(result.weightNeedsAttention, isTrue);
      expect(result.item.weight, '750 g');
      expect(result.item.initialAmount, 750);
      expect(result.item.amountUnit, InventoryAmountUnit.gram);
    });

    test('keeps receipt weight and marks mismatched candidate weight', () {
      final candidate = _candidate();
      final result = _draft(
        item: _item(weight: '500 g'),
        candidates: <GlobalFoodMatchCandidate>[candidate],
      ).selectCandidate(candidate.item.id).prepareForReceiptReview();

      expect(result.weightNeedsAttention, isTrue);
      expect(result.item.weight, '500 g');
      expect(result.item.initialAmount, 500);
      expect(result.item.amountUnit, InventoryAmountUnit.gram);
    });

    test('leaves amount empty when no receipt or candidate weight exists', () {
      final result = _draft().prepareForReceiptReview();

      expect(result.weightNeedsAttention, isTrue);
      expect(result.item.initialAmount, 0);
      expect(result.item.currentAmount, 0);
      expect(result.item.amountUnit, isNull);
    });
  });

  group('syncToSelectedCandidate', () {
    test('returns the original draft without a selected candidate', () {
      final draft = _draft();

      expect(draft.syncToSelectedCandidate(), same(draft));
    });

    test('copies canonical candidate product fields to the draft item', () {
      final candidate = _candidate();
      final result = _draft(
        item: _item(name: 'OCR Milk'),
        candidates: <GlobalFoodMatchCandidate>[candidate],
      ).selectCandidate(candidate.item.id).syncToSelectedCandidate();

      expect(result.item.name, 'Canonical Milk');
      expect(result.item.brand, 'Brand');
      expect(result.item.category, 'Dairy');
      expect(result.item.barcode, '123456');
      expect(result.item.imageUrl, 'https://example.test/milk.png');
      expect(result.item.foodFingerprint, 'milk-brand');
      expect(result.item.servingSize, '100 g');
      expect(result.item.servingQuantity, 100);
      expect(result.item.servingQuantityUnit, 'g');
      expect(result.item.nutrition, _nutrition);
    });
  });

  group('canConfirmReceiptReview', () {
    test('requires a savable item with usable weight and calories', () {
      expect(
        _draft(
          item: _item(isDiscount: true, weight: '500 g'),
        ).canConfirmReceiptReview,
        isFalse,
      );
      expect(
        _draft(
          item: _item(weight: '500 g', nutrition: _nutrition),
        ).canConfirmReceiptReview,
        isFalse,
      );
      expect(
        _draft(
          item: _item(weight: '500 g', amountUnit: InventoryAmountUnit.gram),
        ).canConfirmReceiptReview,
        isFalse,
      );
    });

    test('accepts calories from either item or selected candidate', () {
      expect(
        _draft(
          item: _item(
            weight: '500 g',
            amountUnit: InventoryAmountUnit.gram,
            nutrition: _nutrition,
          ),
        ).canConfirmReceiptReview,
        isTrue,
      );

      final candidate = _candidate();
      expect(
        _draft(
          item: _item(
            weight: '500 g',
            amountUnit: InventoryAmountUnit.gram,
          ),
          candidates: <GlobalFoodMatchCandidate>[candidate],
        ).selectCandidate(candidate.item.id).canConfirmReceiptReview,
        isTrue,
      );
    });
  });

  test('toRecentReceiptReviewCandidate maps inventory item fields', () {
    final item = _item(
      name: 'Recent Yogurt',
      brand: 'Local Dairy',
      category: 'Yogurt',
      barcode: '987654',
      imageUrl: 'https://example.test/yogurt.png',
      foodFingerprint: 'recent-yogurt',
      weight: '150 g',
      nutrition: _nutrition,
    );

    final candidate = item.toRecentReceiptReviewCandidate(
      globalFoodItemId: 'global-recent-yogurt',
    );

    expect(candidate.item.id, 'global-recent-yogurt');
    expect(candidate.item.name, 'Recent Yogurt');
    expect(candidate.item.brand, 'Local Dairy');
    expect(candidate.item.category, 'Yogurt');
    expect(candidate.item.barcode, '987654');
    expect(candidate.item.imageUrl, 'https://example.test/yogurt.png');
    expect(candidate.item.packageWeight, '150 g');
    expect(candidate.item.foodFingerprint, 'recent-yogurt');
    expect(candidate.item.nutrition, _nutrition);
    expect(candidate.score, 100);
    expect(candidate.reason, GlobalFoodMatchReason.nameExact);
  });
}
