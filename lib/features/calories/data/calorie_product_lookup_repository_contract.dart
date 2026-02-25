import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

abstract interface class CalorieProductLookupRepositoryContract {
  Future<CalorieLookupOutcome> lookupByBarcode(String rawBarcode);

  Future<bool> persistGlobalProduct(CalorieProductProfile profile);
}
