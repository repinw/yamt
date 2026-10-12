import 'package:meta/meta.dart';

/// Nutrients of an amount of food, as on a food label.
///
/// A null value is unknown.
@immutable
class NutritionFacts {
  /// Creates nutrition facts.
  const new({
    this.kcal,
    this.fat,
    this.saturatedFat,
    this.polyunsaturatedFat,
    this.carbs,
    this.sugar,
    this.fiber,
    this.protein,
    this.salt,
  });

  /// Energy in kcal.
  final double? kcal;

  /// Fat in grams.
  final double? fat;

  /// Saturated fat in grams.
  final double? saturatedFat;

  /// Polyunsaturated fat in grams.
  final double? polyunsaturatedFat;

  /// Carbohydrates in grams.
  final double? carbs;

  /// Sugar in grams.
  final double? sugar;

  /// Fiber in grams.
  final double? fiber;

  /// Protein in grams.
  final double? protein;

  /// Salt in grams.
  final double? salt;

  /// These facts multiplied by [factor].
  NutritionFacts scaled(double factor) {
    double? scale(double? value) => value == null ? null : value * factor;
    return NutritionFacts(
      kcal: scale(kcal),
      fat: scale(fat),
      saturatedFat: scale(saturatedFat),
      polyunsaturatedFat: scale(polyunsaturatedFat),
      carbs: scale(carbs),
      sugar: scale(sugar),
      fiber: scale(fiber),
      protein: scale(protein),
      salt: scale(salt),
    );
  }
}

/// One nutrient of [NutritionFacts].
enum Nutrient {
  /// Energy in kcal.
  kcal,

  /// Fat.
  fat,

  /// Saturated fat, part of the fat.
  saturatedFat,

  /// Polyunsaturated fat, part of the fat.
  polyunsaturatedFat,

  /// Carbohydrates.
  carbs,

  /// Sugar, part of the carbohydrates.
  sugar,

  /// Fiber.
  fiber,

  /// Protein.
  protein,

  /// Salt.
  salt;

  /// The value of this nutrient in [facts].
  double? of(NutritionFacts facts) => switch (this) {
    kcal => facts.kcal,
    fat => facts.fat,
    saturatedFat => facts.saturatedFat,
    polyunsaturatedFat => facts.polyunsaturatedFat,
    carbs => facts.carbs,
    sugar => facts.sugar,
    fiber => facts.fiber,
    protein => facts.protein,
    salt => facts.salt,
  };
}
