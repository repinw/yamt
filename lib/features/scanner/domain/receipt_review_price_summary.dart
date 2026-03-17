import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

class ReceiptReviewPriceSummary {
  const ReceiptReviewPriceSummary({
    required this.totalPrice,
    required this.storablePrice,
    required this.excludedPrice,
  });

  final double totalPrice;
  final double storablePrice;
  final double excludedPrice;
}

class ReceiptReviewPriceSummaryCalculator {
  const ReceiptReviewPriceSummaryCalculator();

  ReceiptReviewPriceSummary calculate(Iterable<ReceiptReviewItemDraft> items) {
    var totalPrice = 0.0;
    var storablePrice = 0.0;
    var excludedPrice = 0.0;

    for (final draft in items) {
      final item = draft.item;
      final discountTotal = item.discounts.values.fold<double>(
        0.0,
        (sum, value) => sum + value,
      );
      final linePrice = (item.quantity * item.unitPrice) + discountTotal;
      totalPrice += linePrice;

      if (draft.canBeSavedToInventory) {
        storablePrice += linePrice;
      } else {
        excludedPrice += linePrice;
      }
    }

    return ReceiptReviewPriceSummary(
      totalPrice: totalPrice,
      storablePrice: storablePrice,
      excludedPrice: excludedPrice,
    );
  }
}
