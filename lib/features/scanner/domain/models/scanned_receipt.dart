import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';

part 'scanned_receipt.freezed.dart';

/// Represents a fully parsed receipt in the review state.
@freezed
abstract class ScannedReceipt with _$ScannedReceipt {
  /// Creates an instance of [ScannedReceipt].
  const factory({
    /// Unique ID for this scan session.
    required String id,

    /// Recognized store name (e.g. "Lidl", "Rewe", "Aldi Süd").
    String? storeName,

    /// Purchase date and time from the receipt.
    DateTime? dateTime,

    /// Printed total amount on the receipt (e.g. 24.89).
    double? printedTotal,

    /// File paths of original receipt files
    /// (e.g. multiple photos for long receipts).
    @Default(<String>[]) List<String> sourceFilePaths,

    /// MIME type of the original receipts (e.g. 'image/jpeg' or 'application/pdf').
    String? sourceMimeType,

    /// Overall OCR / parsing confidence score (0.0 to 1.0).
    @Default(1.0) double confidenceScore,

    /// Unprocessed raw text of the receipt (for debugging and transparency).
    String? rawText,

    /// Currency (default: 'EUR').
    @Default('EUR') String currency,

    /// All line items extracted from the receipt.
    @Default(<ReceiptLineItem>[]) List<ReceiptLineItem> items,
  }) = _ScannedReceipt;

  const new _();

  /// Primary source file path of the receipt (if available).
  String? get primarySourceFilePath => sourceFilePaths.firstOrNull;

  /// Mathematical sum of all item prices minus line discounts.
  double get calculatedTotal {
    return items.fold<double>(0, (sum, item) => sum + item.effectivePrice);
  }

  /// Absolute difference between printed total and calculated item sum.
  double get totalDiscrepancy {
    if (printedTotal == null) return 0;
    return (calculatedTotal - printedTotal!).abs();
  }

  /// Whether there is a significant total discrepancy (> 2 cents).
  bool get hasDiscrepancy => totalDiscrepancy > 0.02;

  /// Number of line items that still require confirmation or resolution.
  int get unresolvedCount => items
      .where(
        (item) =>
            item.status != ReceiptItemStatus.confirmed &&
            item.status != ReceiptItemStatus.ignored,
      )
      .length;

  /// Number of confirmed items.
  int get confirmedCount =>
      items.where((item) => item.status == ReceiptItemStatus.confirmed).length;

  /// Whether the receipt is ready to be saved into inventory.
  bool get isReadyToSave =>
      items.any((item) => item.shouldPersist) && unresolvedCount == 0;

  /// All items that should be saved into inventory.
  List<ReceiptLineItem> get savableItems =>
      items.where((item) => item.shouldPersist).toList(growable: false);

  /// Total savings across all line item discounts.
  double get totalSavings {
    return items.fold<double>(0, (sum, item) => sum + item.lineSavings);
  }

  /// Total sum of all deposit items.
  double get totalDeposit {
    return items
        .where((item) => item.isDeposit)
        .fold<double>(0, (sum, item) => sum + item.totalPrice);
  }

  /// Adds a new line item to the receipt.
  ScannedReceipt addItem(ReceiptLineItem newItem) {
    return copyWith(items: [...items, newItem]);
  }

  /// Replaces a line item by ID with an updated instance.
  ScannedReceipt updateItem(ReceiptLineItem updatedItem) {
    final newItems = items
        .map((item) {
          return item.id == updatedItem.id ? updatedItem : item;
        })
        .toList(growable: false);

    return copyWith(items: newItems);
  }

  /// Removes a line item by ID.
  ScannedReceipt removeItem(String itemId) {
    final newItems = items
        .where((item) => item.id != itemId)
        .toList(growable: false);

    return copyWith(items: newItems);
  }

  /// Confirms all items that currently have a suggested candidate.
  ScannedReceipt confirmAllSuggestions() {
    final newItems = items
        .map((item) {
          if (item.status == ReceiptItemStatus.suggested &&
              item.matchedProduct != null) {
            return item.copyWith(status: ReceiptItemStatus.confirmed);
          }
          return item;
        })
        .toList(growable: false);

    return copyWith(items: newItems);
  }
}
