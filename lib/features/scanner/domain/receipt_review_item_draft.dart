import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

class ReceiptReviewItemDraft {
  const ReceiptReviewItemDraft({
    required this.item,
    this.candidates = const <GlobalFoodMatchCandidate>[],
    this.selectedGlobalFoodItemId,
    this.selectionNeedsReview = false,
    this.ocrName,
    this.receiptTimeText,
  });

  final InventoryItem item;
  final List<GlobalFoodMatchCandidate> candidates;
  final String? selectedGlobalFoodItemId;
  final bool selectionNeedsReview;
  final String? ocrName;
  final String? receiptTimeText;

  ReceiptReviewItemDraft copyWith({
    InventoryItem? item,
    List<GlobalFoodMatchCandidate>? candidates,
    Object? selectedGlobalFoodItemId = _keepValue,
    bool? selectionNeedsReview,
    Object? ocrName = _keepValue,
    Object? receiptTimeText = _keepValue,
  }) {
    return ReceiptReviewItemDraft(
      item: item ?? this.item,
      candidates: candidates ?? this.candidates,
      selectedGlobalFoodItemId: selectedGlobalFoodItemId == _keepValue
          ? this.selectedGlobalFoodItemId
          : selectedGlobalFoodItemId as String?,
      selectionNeedsReview: selectionNeedsReview ?? this.selectionNeedsReview,
      ocrName: ocrName == _keepValue ? this.ocrName : ocrName as String?,
      receiptTimeText: receiptTimeText == _keepValue
          ? this.receiptTimeText
          : receiptTimeText as String?,
    );
  }

  ReceiptReviewItemDraft selectCandidate(String globalFoodItemId) {
    return copyWith(
      selectedGlobalFoodItemId: globalFoodItemId,
      selectionNeedsReview: false,
    );
  }

  ReceiptReviewItemDraft selectNewItem() {
    return copyWith(
      selectedGlobalFoodItemId: null,
      selectionNeedsReview: false,
    );
  }

  GlobalFoodMatchCandidate? get selectedCandidate {
    final selectedId = selectedGlobalFoodItemId;
    if (selectedId == null) {
      return null;
    }
    return candidates.firstWhereOrNull(
      (candidate) => candidate.item.id == selectedId,
    );
  }

  bool get isNewItemSelection => selectedGlobalFoodItemId == null;

  bool get canBeSavedToInventory => item.canBeSavedToInventory;

  bool get hasCandidates => candidates.isNotEmpty;

  bool get differsFromSelectedCandidate {
    final candidate = selectedCandidate;
    if (candidate == null) {
      return true;
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
            other.selectionNeedsReview == selectionNeedsReview &&
            other.ocrName == ocrName &&
            other.receiptTimeText == receiptTimeText;
  }

  @override
  int get hashCode {
    return Object.hash(
      item,
      const ListEquality<GlobalFoodMatchCandidate>().hash(candidates),
      selectedGlobalFoodItemId,
      selectionNeedsReview,
      ocrName,
      receiptTimeText,
    );
  }
}

const Object _keepValue = Object();
