import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

/// Defines receipt review metadata.
class ReceiptReviewMetadata {
  /// The receipt review metadata.
  const ReceiptReviewMetadata({
    required this.storeName,
    required this.receiptDate,
    required this.receiptTimeText,
  });

  /// The store name.
  final String storeName;

  /// The receipt date.
  final DateTime? receiptDate;

  /// The receipt time text.
  final String? receiptTimeText;
}

/// Defines receipt review processing result.
class ReceiptReviewProcessingResult {
  /// The receipt review processing result.
  const ReceiptReviewProcessingResult({
    required this.items,
    required this.metadata,
  });

  /// The items.
  final List<ReceiptReviewItemDraft> items;

  /// The metadata.
  final ReceiptReviewMetadata metadata;
}

/// Defines receipt review item processor.
class ReceiptReviewItemProcessor {
  /// The receipt review item processor.
  const ReceiptReviewItemProcessor({
    Set<String> discountKeywords = _defaultDiscountKeywords,
    Set<String> depositKeywords = _defaultDepositKeywords,
  }) : _discountKeywords = discountKeywords,
       _depositKeywords = depositKeywords;

  final Set<String> _discountKeywords;
  final Set<String> _depositKeywords;

  /// Process.
  ReceiptReviewProcessingResult process(List<ReceiptReviewItemDraft> items) {
    final mergedItems = _mergeDiscountItems(items);
    final sortedItems = _sortNonFoodItemsToBottom(mergedItems);
    final metadata = _deriveReceiptMetadata(sortedItems);
    return ReceiptReviewProcessingResult(
      items: sortedItems,
      metadata: metadata,
    );
  }

  List<ReceiptReviewItemDraft> _mergeDiscountItems(
    List<ReceiptReviewItemDraft> items,
  ) {
    final merged = <ReceiptReviewItemDraft>[];
    int? previousSavableIndex;

    for (final draft in items) {
      final normalizedDraft = _normalizeDiscountLine(draft);
      if (normalizedDraft.item.isDiscount && previousSavableIndex != null) {
        final previousDraft = merged[previousSavableIndex];
        final discountAmount =
            normalizedDraft.item.unitPrice * normalizedDraft.item.quantity;
        final updatedDiscounts = Map<String, double>.from(
          previousDraft.item.discounts,
        );
        final discountName = _normalizeDiscountName(normalizedDraft);
        updatedDiscounts[discountName] =
            (updatedDiscounts[discountName] ?? 0) + discountAmount;
        merged[previousSavableIndex] = previousDraft.copyWith(
          item: previousDraft.item.copyWith(discounts: updatedDiscounts),
        );
        continue;
      }

      merged.add(normalizedDraft);
      if (normalizedDraft.canBeSavedToInventory) {
        previousSavableIndex = merged.length - 1;
      }
    }

    return merged;
  }

  ReceiptReviewItemDraft _normalizeDiscountLine(ReceiptReviewItemDraft draft) {
    final item = draft.item;
    if (_looksLikeDepositLine(item)) {
      return draft.copyWith(
        item: item.copyWith(isDeposit: true, isDiscount: false),
      );
    }
    if (item.isDiscount) {
      return draft.copyWith(
        item: item.copyWith(isDeposit: false, isDiscount: true),
      );
    }
    if (!_looksLikeDiscountLine(item)) {
      return draft;
    }
    return draft.copyWith(
      item: item.copyWith(isDeposit: false, isDiscount: true),
    );
  }

  List<ReceiptReviewItemDraft> _sortNonFoodItemsToBottom(
    List<ReceiptReviewItemDraft> items,
  ) {
    final regularItems = <ReceiptReviewItemDraft>[];
    final nonFoodItems = <ReceiptReviewItemDraft>[];

    for (final draft in items) {
      if (_isLikelyNonFoodArticle(draft.item)) {
        nonFoodItems.add(draft);
        continue;
      }
      regularItems.add(draft);
    }

    return <ReceiptReviewItemDraft>[
      ...regularItems,
      ...nonFoodItems,
    ];
  }

  bool _looksLikeDiscountLine(InventoryItem item) {
    if (_looksLikeDepositLine(item) || item.unitPrice >= 0) {
      return false;
    }

    final normalizedName = item.name.trim().toLowerCase();
    if (normalizedName.isEmpty) {
      return true;
    }
    if (_discountKeywords.any(normalizedName.contains)) {
      return true;
    }

    final hasBrand = (item.brand ?? '').trim().isNotEmpty;
    final hasCategory = (item.category ?? '').trim().isNotEmpty;
    return !hasBrand && !hasCategory;
  }

  bool _isLikelyNonFoodArticle(InventoryItem item) {
    // Receipt mapping currently uses `isDeposit` as the review-only marker
    // for non-food lines. Real deposit rows are filtered out by keyword so
    // only non-food articles get moved to the bottom.
    final isReviewOnlyNonFoodCandidate = item.isDeposit && !item.isDiscount;
    if (!isReviewOnlyNonFoodCandidate) {
      return false;
    }
    return !_looksLikeDepositLine(item);
  }

  bool _looksLikeDepositLine(InventoryItem item) {
    final normalizedName = item.name.trim().toLowerCase();
    if (normalizedName.isEmpty) {
      return false;
    }
    return _depositKeywords.any(normalizedName.contains);
  }

  ReceiptReviewMetadata _deriveReceiptMetadata(
    List<ReceiptReviewItemDraft> items,
  ) {
    var storeName = '-';
    DateTime? receiptDate;
    String? receiptTimeText;

    for (final draft in items) {
      final item = draft.item;
      final trimmedStoreName = item.storeName.trim();
      if (storeName == '-' && trimmedStoreName.isNotEmpty) {
        storeName = trimmedStoreName;
      }
      if (receiptDate == null && item.receiptDate != null) {
        receiptDate = item.receiptDate;
      }
      receiptTimeText ??= _normalizeReceiptTimeText(draft.receiptTimeText);
      if (storeName != '-' && receiptDate != null && receiptTimeText != null) {
        break;
      }
    }

    return ReceiptReviewMetadata(
      storeName: storeName,
      receiptDate: receiptDate,
      receiptTimeText: receiptTimeText,
    );
  }

  String _normalizeDiscountName(ReceiptReviewItemDraft draft) {
    return draft.item.name.trim();
  }

  String? _normalizeReceiptTimeText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

const Set<String> _defaultDiscountKeywords = <String>{
  'rabatt',
  'discount',
  'coupon',
  'couponing',
  'gutschein',
  'nachlass',
  'ersparnis',
};

const Set<String> _defaultDepositKeywords = <String>{
  'leergut',
  'pfand',
  'deposit',
  'bottle deposit',
  'einwegpfand',
  'mehrwegpfand',
};
