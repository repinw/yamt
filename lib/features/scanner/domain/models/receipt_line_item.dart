import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';

part 'receipt_line_item.freezed.dart';

/// The review status of a receipt line item.
enum ReceiptItemStatus {
  /// 🟢 Green: Item is reliably matched
  /// (e.g. via learned alias or user confirmation).
  confirmed,

  /// 🟡 Yellow: Candidate suggestion exists (e.g. fuzzy catalog match).
  suggested,

  /// ⚪ White/Gray: No matching product found yet.
  unmatched,

  /// ❌ Ignored: Line item will be skipped during save
  /// (e.g. deposit, discount line).
  ignored,
}

/// A single position extracted from the scanned receipt.
@freezed
abstract class ReceiptLineItem with _$ReceiptLineItem {
  /// Creates an instance of [ReceiptLineItem].
  const factory ReceiptLineItem({
    /// Unique ID of this line within the receipt.
    required String id,

    /// Original raw text on the receipt (e.g. "JA! VOLLM 3.8% 1L").
    required String rawName,

    /// Printed total price on receipt before discounts.
    required double totalPrice,

    /// Line discount (e.g. 0.50 coupon or promotion).
    @Default(0.0) double discount,

    /// Purchased quantity (e.g. 1.0 pieces or 0.450 kg).
    @Default(1.0) double quantity,

    /// Unit price if printed on receipt.
    double? unitPrice,

    /// Unit (e.g. "kg", "g", "l", "pcs").
    String? unit,

    /// Store product category if listed on receipt.
    String? rawCategory,

    /// Brand name or abbreviated brand marker extracted from the receipt.
    String? rawBrand,

    /// Package content printed or inferred for this product (e.g. 200g, 1L).
    String? packageWeight,

    /// Whether this is a deposit line item.
    @Default(false) bool isDeposit,

    /// Whether this is a discount / voucher line item.
    @Default(false) bool isDiscount,

    /// Current review status.
    @Default(ReceiptItemStatus.unmatched) ReceiptItemStatus status,

    /// Currently matched product candidate.
    ProductCandidate? matchedProduct,

    /// Alternative product candidates for this line item.
    @Default(<ProductCandidate>[]) List<ProductCandidate> candidates,
  }) = _ReceiptLineItem;

  const ReceiptLineItem._();

  /// Actually paid price for this item.
  ///
  /// For regular items: `totalPrice - discount`.
  /// For voucher/discount lines: `-totalPrice.abs()`.
  double get effectivePrice {
    if (isDiscount) {
      return -totalPrice.abs();
    }
    return totalPrice - discount;
  }

  /// Savings amount for this line item.
  double get lineSavings {
    if (isDiscount) {
      return totalPrice.abs();
    }
    return discount;
  }

  /// Display name in the UI: product name or raw receipt name.
  String get displayName => matchedProduct?.name ?? rawName;

  /// Whether this item should be persisted into inventory.
  bool get shouldPersist =>
      status == ReceiptItemStatus.confirmed &&
      matchedProduct != null &&
      !isDeposit &&
      !isDiscount;

  /// Associates a concrete product with this receipt line item.
  ReceiptLineItem withSelectedProduct(ProductCandidate product) {
    return copyWith(
      matchedProduct: product,
      status: ReceiptItemStatus.confirmed,
    );
  }

  /// Clears the product association and resets status to unmatched.
  ReceiptLineItem clearProduct() {
    return copyWith(
      matchedProduct: null,
      status: ReceiptItemStatus.unmatched,
    );
  }
}
