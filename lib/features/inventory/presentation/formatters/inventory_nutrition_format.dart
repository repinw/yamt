import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';

/// Format inventory nutrition value.
String formatInventoryNutritionValue(double value) {
  return value.toNutritionMetricValue();
}
