import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

InventoryItem _item({
  required String id,
  required String name,
  String? brand,
  String? barcode,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    brand: brand,
    barcode: barcode,
  );
}

GlobalFoodItem _product({
  required String id,
  required String name,
  String? brand,
  String? barcode,
}) {
  return GlobalFoodItem.create(
    id: id,
    name: name,
    now: DateTime.parse('2026-03-01T10:00:00Z'),
    brand: brand,
    barcode: barcode,
  );
}

void main() {
  test('copyWith clears nullable fields when null is passed explicitly', () {
    final draft = ReceiptReviewItemDraft(
      item: _item(id: 'draft-1', name: 'Milk'),
      selectedGlobalFoodItemId: 'global-1',
      initialSelectedGlobalFoodItemId: 'global-1',
      ocrName: 'OCR Milk',
      receiptTimeText: '12:30',
    );

    final updated = draft.copyWith(
      selectedGlobalFoodItemId: null,
      initialSelectedGlobalFoodItemId: null,
      ocrName: null,
      receiptTimeText: null,
    );

    expect(updated.selectedGlobalFoodItemId, isNull);
    expect(updated.initialSelectedGlobalFoodItemId, isNull);
    expect(updated.ocrName, isNull);
    expect(updated.receiptTimeText, isNull);
  });

  test('copyWith keeps nullable fields when omitted', () {
    final draft = ReceiptReviewItemDraft(
      item: _item(id: 'draft-1', name: 'Milk'),
      selectedGlobalFoodItemId: 'global-1',
      initialSelectedGlobalFoodItemId: 'global-1',
      ocrName: 'OCR Milk',
      receiptTimeText: '12:30',
    );

    final updated = draft.copyWith(isConfirmed: true);

    expect(updated.selectedGlobalFoodItemId, 'global-1');
    expect(updated.initialSelectedGlobalFoodItemId, 'global-1');
    expect(updated.ocrName, 'OCR Milk');
    expect(updated.receiptTimeText, '12:30');
    expect(updated.isConfirmed, isTrue);
  });

  test('differsFromSelectedCandidate stays false for OFF candidates '
      'that still need persistence', () {
    final draft = ReceiptReviewItemDraft(
      item: _item(id: 'draft-1', name: 'OCR Name', brand: 'OCR Brand'),
      candidates: <GlobalFoodMatchCandidate>[
        GlobalFoodMatchCandidate(
          item: _product(
            id: 'off-123',
            name: 'Resolved Product',
            brand: 'Resolved Brand',
            barcode: '123',
          ),
          score: 80,
          reason: GlobalFoodMatchReason.externalSearch,
          requiresPersistence: true,
        ),
      ],
      selectedGlobalFoodItemId: 'off-123',
    );

    expect(draft.differsFromSelectedCandidate, isFalse);
  });

  test('differsFromSelectedCandidate stays true for edited local matches', () {
    final draft = ReceiptReviewItemDraft(
      item: _item(id: 'draft-1', name: 'Milk', brand: 'Different Brand'),
      candidates: <GlobalFoodMatchCandidate>[
        GlobalFoodMatchCandidate(
          item: _product(id: 'milk', name: 'Milk', brand: 'Acme'),
          score: 100,
          reason: GlobalFoodMatchReason.nameBrandStrong,
        ),
      ],
      selectedGlobalFoodItemId: 'milk',
    );

    expect(draft.differsFromSelectedCandidate, isTrue);
  });
}
