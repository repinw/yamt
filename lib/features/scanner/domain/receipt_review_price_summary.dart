import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

/// Defines receipt review price summary.
class ReceiptReviewPriceSummary {
  /// The receipt review price summary.
  const ReceiptReviewPriceSummary({
    required this.totalPrice,
    required this.storablePrice,
    required this.excludedPrice,
  });

  /// The total price.
  final double totalPrice;

  /// The storable price.
  final double storablePrice;

  /// The excluded price.
  final double excludedPrice;
}

/// Defines receipt review price summary calculator.
class ReceiptReviewPriceSummaryCalculator {
  /// The receipt review price summary calculator.
  const ReceiptReviewPriceSummaryCalculator();

  /// Calculate.
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
