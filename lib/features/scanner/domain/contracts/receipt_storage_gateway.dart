import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

/// Contract for persistently saving a reviewed receipt.
///
/// Decouples receipt scanner logic from inventory persistence.
abstract interface class ReceiptStorageGateway {
  /// Saves confirmed line items to the user's inventory.
  Future<void> saveReceipt({
    required ScannedReceipt receipt,
    required List<ReceiptLineItem> items,
  });

  /// Persists a learned mapping between receipt text and product.
  Future<void> learnAlias({
    required String rawLineText,
    required String productId,
    String? storeName,
  });
}
