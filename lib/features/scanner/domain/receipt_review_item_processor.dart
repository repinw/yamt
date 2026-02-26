import 'package:yamt/features/inventory/domain/fridge_item.dart';

class ReceiptReviewMetadata {
  const ReceiptReviewMetadata({
    required this.storeName,
    required this.receiptDate,
  });

  final String storeName;
  final DateTime? receiptDate;
}

class ReceiptReviewProcessingResult {
  const ReceiptReviewProcessingResult({
    required this.items,
    required this.metadata,
  });

  final List<FridgeItem> items;
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

  ReceiptReviewProcessingResult process(List<FridgeItem> items) {
    final mergedItems = _mergeDiscountItems(items);
    final metadata = _deriveReceiptMetadata(mergedItems);
    return ReceiptReviewProcessingResult(
      items: mergedItems,
      metadata: metadata,
    );
  }

  List<FridgeItem> _mergeDiscountItems(List<FridgeItem> items) {
    final merged = <FridgeItem>[];
    int? previousSavableIndex;

    for (final item in items) {
      final normalizedItem = _normalizeDiscountLine(item);
      if (normalizedItem.isDiscount && previousSavableIndex != null) {
        final previousItem = merged[previousSavableIndex];
        final discountAmount =
            normalizedItem.unitPrice * normalizedItem.quantity;
        final updatedDiscounts = Map<String, double>.from(
          previousItem.discounts,
        );
        final discountName = _normalizeDiscountName(normalizedItem);
        updatedDiscounts[discountName] =
            (updatedDiscounts[discountName] ?? 0) + discountAmount;
        merged[previousSavableIndex] = previousItem.copyWith(
          discounts: updatedDiscounts,
        );
        continue;
      }

      merged.add(normalizedItem);
      if (normalizedItem.canBeSavedToFridge) {
        previousSavableIndex = merged.length - 1;
      }
    }

    return merged;
  }

  FridgeItem _normalizeDiscountLine(FridgeItem item) {
    if (_looksLikeDepositLine(item)) {
      return item.copyWith(isDeposit: true, isDiscount: false);
    }
    if (item.isDiscount) {
      return item.copyWith(isDeposit: false, isDiscount: true);
    }
    if (!_looksLikeDiscountLine(item)) {
      return item;
    }
    return item.copyWith(isDeposit: false, isDiscount: true);
  }

  bool _looksLikeDiscountLine(FridgeItem item) {
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

  bool _looksLikeDepositLine(FridgeItem item) {
    final normalizedName = item.name.trim().toLowerCase();
    if (normalizedName.isEmpty) {
      return false;
    }
    return _depositKeywords.any(normalizedName.contains);
  }

  ReceiptReviewMetadata _deriveReceiptMetadata(List<FridgeItem> items) {
    var storeName = '-';
    DateTime? receiptDate;

    for (final item in items) {
      final trimmedStoreName = item.storeName.trim();
      if (storeName == '-' && trimmedStoreName.isNotEmpty) {
        storeName = trimmedStoreName;
      }
      if (receiptDate == null && item.receiptDate != null) {
        receiptDate = item.receiptDate;
      }
      if (storeName != '-' && receiptDate != null) {
        break;
      }
    }

    return ReceiptReviewMetadata(
      storeName: storeName,
      receiptDate: receiptDate,
    );
  }

  String _normalizeDiscountName(FridgeItem item) {
    return item.name.trim();
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
