/// Nutrients per 100 g or ml beyond calories and the three macros, as a food
/// label lists them. Each value is `null` when the source did not provide it.
class CalorieNutrientDetails {
  /// Creates nutrient details.
  const new({
    this.per100SaturatedFat,
    this.per100PolyunsaturatedFat,
    this.per100Sugar,
    this.per100Fiber,
    this.per100Salt,
  });

  /// Saturated fat, part of the fat.
  final double? per100SaturatedFat;

  /// Polyunsaturated fat, part of the fat.
  final double? per100PolyunsaturatedFat;

  /// Sugar, part of the carbohydrates.
  final double? per100Sugar;

  /// Dietary fiber.
  final double? per100Fiber;

  /// Salt.
  final double? per100Salt;

  /// Whether at least one value is known.
  bool get hasAnyValue =>
      per100SaturatedFat != null ||
      per100PolyunsaturatedFat != null ||
      per100Sugar != null ||
      per100Fiber != null ||
      per100Salt != null;
}
