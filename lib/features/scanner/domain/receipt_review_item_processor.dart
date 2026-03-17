import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

class ReceiptReviewMetadata {
  const ReceiptReviewMetadata({
    required this.storeName,
    required this.receiptDate,
    required this.receiptTimeText,
  });

  final String storeName;
  final DateTime? receiptDate;
  final String? receiptTimeText;
}

class ReceiptReviewProcessingResult {
  const ReceiptReviewProcessingResult({
    required this.items,
    required this.metadata,
  });

  final List<ReceiptReviewItemDraft> items;
  final ReceiptReviewMetadata metadata;
}

class ReceiptReviewItemProcessor {
  const ReceiptReviewItemProcessor({
    Set<String> discountKeywords = _defaultDiscountKeywords,
    Set<String> depositKeywords = _defaultDepositKeywords,
  }) : _discountKeywords = discountKeywords,
       _depositKeywords = depositKeywords;

  final Set<String> _discountKeywords;
  final Set<String> _depositKeywords;

  ReceiptReviewProcessingResult process(List<ReceiptReviewItemDraft> items) {
    final mergedItems = _mergeDiscountItems(items);
    final metadata = _deriveReceiptMetadata(mergedItems);
    return ReceiptReviewProcessingResult(
      items: mergedItems,
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
