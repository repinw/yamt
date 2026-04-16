import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

/// Defines calorie product cache repository contract.
abstract interface class CalorieProductCacheRepositoryContract {
  /// Read user override.
  Future<CalorieProductProfile?> readUserOverride(String barcode);

  /// Read global product.
  Future<CalorieProductProfile?> readGlobalProduct(String barcode);

  /// Save global product.
  Future<bool> saveGlobalProduct(CalorieProductProfile profile);

  /// Save user override.
  Future<bool> saveUserOverride({
    required CalorieProductProfile profile,
    required String reason,
  });
}
