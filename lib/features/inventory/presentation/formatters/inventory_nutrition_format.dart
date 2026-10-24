/// Format inventory nutrition value: a whole number without decimals, any
/// other value with one decimal, so 9.97 shows as "10.0".
String formatInventoryNutritionValue(double value) {
  return value % 1 != 0 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
}
