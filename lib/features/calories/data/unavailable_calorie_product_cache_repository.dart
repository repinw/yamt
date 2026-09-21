import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

/// Calorie product cache used when Firestore is not available.
/// It stores nothing.
class UnavailableCalorieProductCacheRepository
    implements CalorieProductCacheRepositoryContract {
  /// Creates an unavailable calorie product cache repository.
  const new();

  @override
  Future<CalorieProductProfile?> readUserOverride(String barcode) async {
    return null;
  }

  @override
  Future<CalorieProductProfile?> readGlobalProduct(String barcode) async {
    return null;
  }

  @override
  Future<bool> saveGlobalProduct(CalorieProductProfile profile) async {
    return false;
  }

  @override
  Future<bool> saveUserOverride({
    required CalorieProductProfile profile,
    required String reason,
  }) async {
    return false;
  }
}
