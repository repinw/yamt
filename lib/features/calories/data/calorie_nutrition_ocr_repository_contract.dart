import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

abstract interface class CalorieNutritionOcrRepositoryContract {
  Future<CalorieNutritionOcrResult> scanNutritionLabel({
    required String barcode,
  });
}
