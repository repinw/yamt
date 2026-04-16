import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

/// Defines calorie product lookup repository contract.
abstract interface class CalorieProductLookupRepositoryContract {
  /// Lookup by barcode.
  Future<CalorieLookupOutcome> lookupByBarcode(String rawBarcode);

  /// Persist global product.
  Future<bool> persistGlobalProduct(CalorieProductProfile profile);
}
