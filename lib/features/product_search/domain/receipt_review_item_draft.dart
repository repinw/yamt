import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines receipt review item draft.
@immutable
class ReceiptReviewItemDraft {
  /// The receipt review item draft.
  const ReceiptReviewItemDraft({
    required this.item,
    this.candidates = const <GlobalFoodMatchCandidate>[],
    this.selectedGlobalFoodItemId,
    this.initialSelectedGlobalFoodItemId,
    this.selectionNeedsReview = false,
    this.isConfirmed = false,
    this.weightNeedsAttention = false,
    this.shouldSaveReceiptAlias = false,
    this.ocrName,
    this.receiptTimeText,
  });

  /// The item.
  final InventoryItem item;

  /// The candidates.
  final List<GlobalFoodMatchCandidate> candidates;

  /// The selected global food item id.
  final String? selectedGlobalFoodItemId;

  /// The initial selected global food item id.
  final String? initialSelectedGlobalFoodItemId;

  /// The selection needs review.
  final bool selectionNeedsReview;

  /// Whether confirmed.
  final bool isConfirmed;

  /// The weight needs attention.
  final bool weightNeedsAttention;

  /// Whether save receipt alias.
  final bool shouldSaveReceiptAlias;

  /// The ocr name.
  final String? ocrName;

  /// The receipt time text.
  final String? receiptTimeText;

  /// Copy with.
  ReceiptReviewItemDraft copyWith({
    InventoryItem? item,
    List<GlobalFoodMatchCandidate>? candidates,
    Object? selectedGlobalFoodItemId = _keepValue,
    Object? initialSelectedGlobalFoodItemId = _keepValue,
    bool? selectionNeedsReview,
    bool? isConfirmed,
    bool? weightNeedsAttention,
    bool? shouldSaveReceiptAlias,
    Object? ocrName = _keepValue,
    Object? receiptTimeText = _keepValue,
  }) {
    return ReceiptReviewItemDraft(
      item: item ?? this.item,
      candidates: candidates ?? this.candidates,
      selectedGlobalFoodItemId: selectedGlobalFoodItemId == _keepValue
          ? this.selectedGlobalFoodItemId
          : selectedGlobalFoodItemId as String?,
      initialSelectedGlobalFoodItemId:
          initialSelectedGlobalFoodItemId == _keepValue
          ? this.initialSelectedGlobalFoodItemId
          : initialSelectedGlobalFoodItemId as String?,
      selectionNeedsReview: selectionNeedsReview ?? this.selectionNeedsReview,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      weightNeedsAttention: weightNeedsAttention ?? this.weightNeedsAttention,
      shouldSaveReceiptAlias:
          shouldSaveReceiptAlias ?? this.shouldSaveReceiptAlias,
      ocrName: ocrName == _keepValue ? this.ocrName : ocrName as String?,
      receiptTimeText: receiptTimeText == _keepValue
          ? this.receiptTimeText
          : receiptTimeText as String?,
    );
  }

  /// Apply automatic selection.
  ReceiptReviewItemDraft applyAutomaticSelection(
    String? globalFoodItemId, {
    bool selectionNeedsReview = false,
  }) {
    return copyWith(
      selectedGlobalFoodItemId: globalFoodItemId,
      initialSelectedGlobalFoodItemId: globalFoodItemId,
      selectionNeedsReview: selectionNeedsReview,
      shouldSaveReceiptAlias: false,
    );
  }

  /// Select candidate.
  ReceiptReviewItemDraft selectCandidate(String globalFoodItemId) {
    return copyWith(
      selectedGlobalFoodItemId: globalFoodItemId,
      selectionNeedsReview: false,
      isConfirmed: false,
      shouldSaveReceiptAlias:
          globalFoodItemId != initialSelectedGlobalFoodItemId,
    );
  }

  /// Select new item.
  ReceiptReviewItemDraft selectNewItem() {
    return copyWith(
      selectedGlobalFoodItemId: null,
      selectionNeedsReview: false,
      isConfirmed: false,
      shouldSaveReceiptAlias: true,
    );
  }

  /// The selected candidate.
  GlobalFoodMatchCandidate? get selectedCandidate {
    final selectedId = selectedGlobalFoodItemId;
    if (selectedId == null) {
      return null;
    }
    return candidates.firstWhereOrNull(
      (candidate) => candidate.item.id == selectedId,
    );
  }

  /// Whether be saved to inventory.
  bool get canBeSavedToInventory => item.canBeSavedToInventory;

  /// Whether candidates.
  bool get hasCandidates => candidates.isNotEmpty;

  /// The differs from selected candidate.
  bool get differsFromSelectedCandidate {
    final candidate = selectedCandidate;
    if (candidate == null) {
      return true;
    }
    if (candidate.requiresPersistence) {
      return false;
    }
    final selectedSnapshot = candidate.item.toProductSnapshot();
    return selectedSnapshot != item.productSnapshot;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReceiptReviewItemDraft &&
            other.item == item &&
            const ListEquality<GlobalFoodMatchCandidate>().equals(
              other.candidates,
              candidates,
            ) &&
            other.selectedGlobalFoodItemId == selectedGlobalFoodItemId &&
            other.initialSelectedGlobalFoodItemId ==
                initialSelectedGlobalFoodItemId &&
            other.selectionNeedsReview == selectionNeedsReview &&
            other.isConfirmed == isConfirmed &&
            other.weightNeedsAttention == weightNeedsAttention &&
            other.shouldSaveReceiptAlias == shouldSaveReceiptAlias &&
            other.ocrName == ocrName &&
            other.receiptTimeText == receiptTimeText;
  }

  @override
  int get hashCode {
    return Object.hash(
      item,
      const ListEquality<GlobalFoodMatchCandidate>().hash(candidates),
      selectedGlobalFoodItemId,
      initialSelectedGlobalFoodItemId,
      selectionNeedsReview,
      isConfirmed,
      weightNeedsAttention,
      shouldSaveReceiptAlias,
      ocrName,
      receiptTimeText,
    );
  }
}

const Object _keepValue = Object();
