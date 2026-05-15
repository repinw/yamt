import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_review_weight_confirmation.dart';

/// Builds a review-ready draft with derived weights and attention flags.
ReceiptReviewItemDraft prepareReceiptReviewDraftForReview(
  ReceiptReviewItemDraft draft,
) {
  final itemWeight = normalizeReceiptReviewWeight(draft.item.weight);
  final candidateWeight = normalizeReceiptReviewWeight(
    draft.selectedCandidate?.item.packageWeight,
  );
  final needsWeightAttention =
      itemWeight == null || shouldRequireReceiptWeightConfirmation(draft);
  final nextItem = itemWeight != null
      ? draft.item.withDerivedAmount(
          weight: itemWeight,
          quantity: draft.item.quantity,
          fallbackUnit: draft.item.amountUnit,
        )
      : candidateWeight != null
      ? draft.item.withDerivedAmount(
          weight: candidateWeight,
          quantity: draft.item.quantity,
        )
      : draft.item;

  return draft.copyWith(
    item: nextItem,
    isConfirmed: false,
    weightNeedsAttention: needsWeightAttention,
  );
}

/// Copies the selected candidate's canonical product data into the draft item.
ReceiptReviewItemDraft syncReceiptReviewDraftToSelectedCandidate(
  ReceiptReviewItemDraft draft,
) {
  final selectedCandidate = draft.selectedCandidate;
  if (selectedCandidate == null) {
    return draft;
  }

  final candidateItem = selectedCandidate.item;
  return draft.copyWith(
    item: draft.item.copyWith(
      name: candidateItem.name,
      brand: candidateItem.brand,
      category: candidateItem.category,
      barcode: candidateItem.barcode,
      imageUrl: candidateItem.imageUrl,
      foodFingerprint: candidateItem.resolvedFoodFingerprint,
      nutrition: candidateItem.nutrition,
    ),
  );
}

/// Returns whether the draft has enough reviewed data to be confirmed.
bool canConfirmReceiptReviewDraft(ReceiptReviewItemDraft draft) {
  if (!draft.canBeSavedToInventory) {
    return false;
  }
  final weight = normalizeReceiptReviewWeight(draft.item.weight);
  final hasUsableWeight = weight != null && draft.item.amountUnit != null;
  if (!hasUsableWeight) {
    return false;
  }

  final kcal =
      draft.item.nutrition?.per100Kcal ??
      draft.selectedCandidate?.item.nutrition?.per100Kcal;
  return kcal != null;
}

/// Creates a candidate from a recent inventory item selected manually.
GlobalFoodMatchCandidate candidateFromRecentReceiptReviewItem({
  required InventoryItem item,
  required String globalFoodItemId,
}) {
  return GlobalFoodMatchCandidate(
    item: GlobalFoodItem.create(
      id: globalFoodItemId,
      name: item.name,
      now: item.entryDate,
      brand: item.brand,
      category: item.category,
      barcode: item.barcode,
      imageUrl: item.imageUrl,
      packageWeight: item.weight,
      servingSize: item.servingSize,
      servingQuantity: item.servingQuantity,
      servingQuantityUnit: item.servingQuantityUnit,
      foodFingerprint: item.resolvedFoodFingerprint,
      nutrition: item.nutrition,
    ),
    score: 100,
    reason: GlobalFoodMatchReason.nameExact,
  );
}
