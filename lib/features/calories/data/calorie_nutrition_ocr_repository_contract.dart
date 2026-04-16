import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

/// Defines calorie nutrition ocr repository contract.
abstract interface class CalorieNutritionOcrRepositoryContract {
  /// Scan nutrition label.
  Future<CalorieNutritionOcrResult> scanNutritionLabel({
    required String barcode,
  });
}
