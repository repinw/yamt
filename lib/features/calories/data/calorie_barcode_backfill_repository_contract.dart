import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

abstract interface class CalorieBarcodeBackfillRepositoryContract {
  Future<bool> enqueueFingerprintLookup({
    required String fingerprint,
    required String itemName,
    String? brand,
    required String trigger,
    bool forceRetry = false,
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
