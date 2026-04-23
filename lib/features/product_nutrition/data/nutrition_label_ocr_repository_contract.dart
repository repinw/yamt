import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';

/// Defines nutrition label OCR repository contract.
abstract interface class NutritionLabelOcrRepositoryContract {
  /// Scan nutrition label.
  Future<NutritionLabelOcrResult> scanNutritionLabel({
    required String barcode,
  });
}
