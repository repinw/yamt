import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';

/// Contract for resolving receipt text into concrete products.
///
/// Decouples scanner logic from catalog and search infrastructure
/// (Firestore, OpenFoodFacts, fuzzy matching, etc.).
abstract interface class ReceiptProductResolver {
  /// Resolves matching product candidates for a single raw line text.
  ///
  /// Returns candidates ordered by relevance.
  Future<List<ProductCandidate>> resolveCandidates({
    required String rawLineText,
    String? storeName,
    String? brand,
    String? weight,
  });

  /// Resolves multiple line items in batch.
  ///
  /// Enables efficient batch queries and parallel resolution.
  /// Map keys correspond to [ReceiptLineItem.id] values in [items].
  Future<Map<String, List<ProductCandidate>>> resolveBatch({
    required List<ReceiptLineItem> items,
    String? storeName,
  });

  /// Resolves a product by barcode.
  Future<ProductCandidate?> resolveByBarcode(String barcode);

  /// Resolves all matching product candidates for a barcode.
  Future<List<ProductCandidate>> resolveCandidatesByBarcode(String barcode);

  /// Executes manual search query in product catalog.
  Future<List<ProductCandidate>> searchByName(
    String query, {
    String? storeName,
    String? brand,
    String? weight,
  });
}
