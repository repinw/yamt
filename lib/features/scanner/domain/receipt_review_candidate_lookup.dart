import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft_extensions.dart';

/// Whether two inventory items have the same candidate lookup input.
bool hasSameReceiptReviewCandidateLookupInput(
  InventoryItem lookupItem,
  InventoryItem currentItem,
) {
  return lookupItem.id == currentItem.id &&
      lookupItem.name == currentItem.name &&
      lookupItem.brand == currentItem.brand &&
      lookupItem.barcode == currentItem.barcode &&
      lookupItem.weight == currentItem.weight &&
      lookupItem.storeName == currentItem.storeName;
}

/// Merges completed candidate lookup data into the latest draft state.
ReceiptReviewItemDraft mergeResolvedReceiptReviewCandidates({
  required ReceiptReviewItemDraft currentDraft,
  required ReceiptReviewItemDraft resolvedDraft,
  required InventoryItem lookupItem,
}) {
  if (currentDraft.hasCandidates) {
    return currentDraft;
  }

  final merged = currentDraft.copyWith(
    candidates: resolvedDraft.candidates,
    selectedGlobalFoodItemId: resolvedDraft.selectedGlobalFoodItemId,
    initialSelectedGlobalFoodItemId:
        resolvedDraft.initialSelectedGlobalFoodItemId,
    selectionNeedsReview: resolvedDraft.selectionNeedsReview,
    shouldSaveReceiptAlias: resolvedDraft.shouldSaveReceiptAlias,
  );

  final productDataUnchanged =
      currentDraft.item.productSnapshot == lookupItem.productSnapshot;
  final withCandidateProductData = productDataUnchanged
      ? merged.syncToSelectedCandidate()
      : merged;
  final prepared = withCandidateProductData.prepareForReceiptReview();
  if (!currentDraft.isConfirmed) {
    return prepared;
  }

  return prepared.copyWith(
    isConfirmed: true,
    selectionNeedsReview: false,
    weightNeedsAttention: false,
  );
}
