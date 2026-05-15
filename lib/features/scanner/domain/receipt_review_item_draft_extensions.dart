import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_review_weight_confirmation.dart';

/// Receipt-review behavior owned by [ReceiptReviewItemDraft].
extension ReceiptReviewItemDraftReviewExtensions on ReceiptReviewItemDraft {
  /// Builds a review-ready draft with derived weights and attention flags.
  ReceiptReviewItemDraft prepareForReceiptReview() {
    final itemWeight = normalizeReceiptReviewWeight(item.weight);
    final candidateWeight = normalizeReceiptReviewWeight(
      selectedCandidate?.item.packageWeight,
    );
    final needsWeightAttention =
        itemWeight == null || shouldRequireReceiptWeightConfirmation(this);

    InventoryItem nextItem;
    if (itemWeight != null) {
      nextItem = item.withDerivedAmount(
        weight: itemWeight,
        quantity: item.quantity,
        fallbackUnit: item.amountUnit,
      );
    } else if (candidateWeight != null) {
      nextItem = item.withDerivedAmount(
        weight: candidateWeight,
        quantity: item.quantity,
      );
    } else {
      nextItem = item;
    }

    return copyWith(
      item: nextItem,
      isConfirmed: false,
      weightNeedsAttention: needsWeightAttention,
    );
  }

  /// Copies the selected candidate's canonical product data into the draft
  /// item.
  ReceiptReviewItemDraft syncToSelectedCandidate() {
    final selectedCandidate = this.selectedCandidate;
    if (selectedCandidate == null) {
      return this;
    }

    final candidateItem = selectedCandidate.item;
    return copyWith(
      item: item.copyWith(
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

  /// Whether the draft has enough reviewed data to be confirmed.
  bool get canConfirmReceiptReview {
    if (!canBeSavedToInventory) {
      return false;
    }
    final weight = normalizeReceiptReviewWeight(item.weight);
    final hasUsableWeight = weight != null && item.amountUnit != null;
    if (!hasUsableWeight) {
      return false;
    }

    final kcal =
        item.nutrition?.per100Kcal ??
        selectedCandidate?.item.nutrition?.per100Kcal;
    return kcal != null;
  }
}

/// Receipt-review candidate behavior owned by [InventoryItem].
extension ReceiptReviewInventoryItemCandidateExtensions on InventoryItem {
  /// Creates a candidate from a recent inventory item selected manually.
  GlobalFoodMatchCandidate toRecentReceiptReviewCandidate({
    required String globalFoodItemId,
  }) {
    return GlobalFoodMatchCandidate(
      item: GlobalFoodItem.create(
        id: globalFoodItemId,
        name: name,
        now: entryDate,
        brand: brand,
        category: category,
        barcode: barcode,
        imageUrl: imageUrl,
        packageWeight: weight,
        servingSize: servingSize,
        servingQuantity: servingQuantity,
        servingQuantityUnit: servingQuantityUnit,
        foodFingerprint: resolvedFoodFingerprint,
        nutrition: nutrition,
      ),
      score: 100,
      reason: GlobalFoodMatchReason.nameExact,
    );
  }
}
