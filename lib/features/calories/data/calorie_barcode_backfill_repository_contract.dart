import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

/// Defines barcode lookup batch item.
class BarcodeLookupBatchItem {
  /// The barcode lookup batch item.
  const BarcodeLookupBatchItem({
    required this.itemId,
    required this.fingerprint,
    required this.itemName,
    this.brand,
    this.storeName,
    this.weight,
  });

  /// The item id.
  final String itemId;

  /// The fingerprint.
  final String fingerprint;

  /// The item name.
  final String itemName;

  /// The brand.
  final String? brand;

  /// The store name.
  final String? storeName;

  /// The weight.
  final String? weight;
}

/// Defines calorie barcode backfill repository contract.
abstract interface class CalorieBarcodeBackfillRepositoryContract {
  /// Enqueue fingerprint lookup.
  Future<bool> enqueueFingerprintLookup({
    String? itemId,
    required String fingerprint,
    required String itemName,
    String? brand,
    required String trigger,
    bool forceRetry = false,
  });

  /// Enqueue batch lookup.
  Future<bool> enqueueBatchLookup({
    required List<BarcodeLookupBatchItem> items,
    required String trigger,
  });

  /// Get resolved profile by fingerprint.
  Future<CalorieProductProfile?> getResolvedProfileByFingerprint(
    String fingerprint,
  );

  /// Submit user provided barcode.
  Future<bool> submitUserProvidedBarcode({
    required String fingerprint,
    required String barcode,
    required String itemName,
    String? brand,
  });
}
