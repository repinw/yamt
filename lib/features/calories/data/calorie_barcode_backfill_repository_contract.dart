import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

class BarcodeLookupBatchItem {
  const BarcodeLookupBatchItem({
    required this.itemId,
    required this.fingerprint,
    required this.itemName,
    this.brand,
    this.storeName,
    this.weight,
  });

  final String itemId;
  final String fingerprint;
  final String itemName;
  final String? brand;
  final String? storeName;
  final String? weight;
}

abstract interface class CalorieBarcodeBackfillRepositoryContract {
  Future<bool> enqueueFingerprintLookup({
    String? itemId,
    required String fingerprint,
    required String itemName,
    String? brand,
    required String trigger,
    bool forceRetry = false,
  });

  Future<bool> enqueueBatchLookup({
    required List<BarcodeLookupBatchItem> items,
    required String trigger,
  });

  Future<CalorieProductProfile?> getResolvedProfileByFingerprint(
    String fingerprint,
  );

  Future<bool> submitUserProvidedBarcode({
    required String fingerprint,
    required String barcode,
    required String itemName,
    String? brand,
  });
}
