import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

abstract interface class CalorieProductCacheRepositoryContract {
  Future<CalorieProductProfile?> readUserOverride(String barcode);

  Future<CalorieProductProfile?> readGlobalProduct(String barcode);

  Future<bool> saveGlobalProduct(CalorieProductProfile profile);

  Future<bool> saveUserOverride({
    required CalorieProductProfile profile,
    required String reason,
  });
}
