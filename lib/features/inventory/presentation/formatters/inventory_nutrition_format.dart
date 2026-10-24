/// Format inventory nutrition value, with one decimal only for a fraction.
String formatInventoryNutritionValue(double value) {
  return value % 1 != 0 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
}
