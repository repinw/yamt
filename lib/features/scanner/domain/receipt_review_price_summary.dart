import 'package:yamt/features/inventory/domain/fridge_item.dart';

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

  ReceiptReviewPriceSummary calculate(Iterable<FridgeItem> items) {
    var totalPrice = 0.0;
    var storablePrice = 0.0;
    var excludedPrice = 0.0;

    for (final item in items) {
      final linePrice = item.quantity * item.unitPrice;
      totalPrice += linePrice;

      if (item.canBeSavedToFridge) {
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
