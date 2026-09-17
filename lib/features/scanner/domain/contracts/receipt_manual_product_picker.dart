import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';

/// Contract for launching external product search, AI estimation, or custom
/// product creation.
///
/// Decouples scanner UI from the app-wide ProductSearchHub and related
/// inventory models.
abstract interface class ReceiptManualProductPicker {
  /// Opens product search or custom editor and returns the resulting
  /// [ProductCandidate] or null if dismissed.
  Future<ProductCandidate?> pickOrEditProduct(
    BuildContext context, {
    required String initialQuery,
    String? barcode,
    String? rawName,
    String? storeName,
    String? brand,
    String? weight,
  });

  /// Opens product creator directly for creating a new custom item.
  Future<ProductCandidate?> createCustomProduct(
    BuildContext context, {
    String? barcode,
    String? initialName,
  });
}
