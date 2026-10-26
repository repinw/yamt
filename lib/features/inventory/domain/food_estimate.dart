import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

part 'food_estimate.g.dart';

/// How rich the preparation of an estimated food is assumed to be.
enum FoodEstimateLevel {
  /// Little oil, sauce, and fat.
  lean,

  /// A typical preparation.
  normal,

  /// Much oil, sauce, and fat.
  rich,
}

/// One component of an estimated food, for a normal preparation.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class FoodEstimateIngredient {
  /// Creates an ingredient.
  const new({required this.name, required this.grams, required this.kcal});

  /// Reads a stored ingredient.
  factory fromJson(Map<String, dynamic> json) =>
      _$FoodEstimateIngredientFromJson(json);

  /// Ingredient name.
  final String name;

  /// Weight in the whole portion.
  final double grams;

  /// Energy in the whole portion.
  final double kcal;

  /// The stored form.
  Map<String, dynamic> toJson() => _$FoodEstimateIngredientToJson(this);

  @override
  bool operator ==(Object other) =>
      other is FoodEstimateIngredient &&
      other.name == name &&
      other.grams == grams &&
      other.kcal == kcal;

  @override
  int get hashCode => Object.hash(name, grams, kcal);
}

/// AI estimate of a food from photos and a description.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class FoodEstimate {
  /// Creates an estimate.
  const new({
    required this.name,
    required this.portionGrams,
    required this.kcalLean,
    required this.kcalRich,
    required this.per100,
    required this.ingredients,
  });

  /// Reads a stored estimate.
  factory fromJson(Map<String, dynamic> json) => _$FoodEstimateFromJson(json);

  /// Dish or food name.
  final String name;

  /// Weight of the whole portion.
  final double portionGrams;

  /// Energy of the whole portion for a lean preparation.
  final double kcalLean;

  /// Energy of the whole portion for a rich preparation.
  final double kcalRich;

  /// Nutrition per 100 g for a normal preparation.
  @JsonKey(name: 'per_100')
  final GlobalFoodNutrition per100;

  /// Components of the portion for a normal preparation.
  final List<FoodEstimateIngredient> ingredients;

  /// Energy of the whole portion at [level].
  double portionKcal(FoodEstimateLevel level) => switch (level) {
    FoodEstimateLevel.lean => kcalLean,
    FoodEstimateLevel.normal => (per100.per100Kcal ?? 0) * portionGrams / 100,
    FoodEstimateLevel.rich => kcalRich,
  };

  /// Nutrition per 100 g at [level].
  ///
  /// A richer or leaner preparation mostly changes fat and sauce, but the
  /// estimate only knows the energy range, so every value scales with the
  /// energy.
  GlobalFoodNutrition per100At(FoodEstimateLevel level) {
    final factor = _factor(level);
    double? scale(double? value) => value == null ? null : value * factor;
    return per100.copyWith(
      per100Kcal: scale(per100.per100Kcal),
      per100Protein: scale(per100.per100Protein),
      per100Carbs: scale(per100.per100Carbs),
      per100Fat: scale(per100.per100Fat),
      per100Salt: scale(per100.per100Salt),
      per100SaturatedFat: scale(per100.per100SaturatedFat),
      per100PolyunsaturatedFat: scale(per100.per100PolyunsaturatedFat),
      per100Sugar: scale(per100.per100Sugar),
      per100Fiber: scale(per100.per100Fiber),
    );
  }

  /// Ingredients of [grams] of the food at [level], with their energy
  /// scaled like [per100At].
  List<FoodEstimateIngredient> ingredientsAt(
    FoodEstimateLevel level, {
    required double grams,
  }) {
    final factor = _factor(level);
    final share = portionGrams <= 0 ? 0.0 : grams / portionGrams;
    return [
      for (final ingredient in ingredients)
        FoodEstimateIngredient(
          name: ingredient.name,
          grams: ingredient.grams * share,
          kcal: ingredient.kcal * factor * share,
        ),
    ];
  }

  double _factor(FoodEstimateLevel level) {
    final normal = portionKcal(FoodEstimateLevel.normal);
    return normal <= 0 ? 1 : portionKcal(level) / normal;
  }

  /// The stored form.
  Map<String, dynamic> toJson() => _$FoodEstimateToJson(this);

  @override
  bool operator ==(Object other) =>
      other is FoodEstimate &&
      other.name == name &&
      other.portionGrams == portionGrams &&
      other.kcalLean == kcalLean &&
      other.kcalRich == kcalRich &&
      other.per100 == per100 &&
      const ListEquality<FoodEstimateIngredient>().equals(
        other.ingredients,
        ingredients,
      );

  @override
  int get hashCode => Object.hash(
    name,
    portionGrams,
    kcalLean,
    kcalRich,
    per100,
    const ListEquality<FoodEstimateIngredient>().hash(ingredients),
  );
}

/// The AI estimate an item was made from, kept for its eat page and a new
/// analysis (#763).
@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SavedFoodEstimate {
  /// Creates the saved estimate.
  const new({
    required this.estimate,
    required this.level,
    required this.description,
    this.photoUrls = const [],
  });

  /// Reads a stored estimate.
  factory fromJson(Map<String, dynamic> json) =>
      _$SavedFoodEstimateFromJson(json);

  /// What the AI answered.
  final FoodEstimate estimate;

  /// The preparation the user chose.
  final FoodEstimateLevel level;

  /// The user's description of the food.
  final String description;

  /// Storage addresses of the photos the AI saw, in the user's order. The
  /// first is also the item's image.
  @JsonKey(required: true)
  final List<String> photoUrls;

  /// This estimate with [level] or [photoUrls] in place of its own.
  SavedFoodEstimate copyWith({
    FoodEstimateLevel? level,
    List<String>? photoUrls,
  }) => SavedFoodEstimate(
    estimate: estimate,
    level: level ?? this.level,
    description: description,
    photoUrls: photoUrls ?? this.photoUrls,
  );

  /// The stored form.
  Map<String, dynamic> toJson() => _$SavedFoodEstimateToJson(this);

  @override
  bool operator ==(Object other) =>
      other is SavedFoodEstimate &&
      other.estimate == estimate &&
      other.level == level &&
      other.description == description &&
      const ListEquality<String>().equals(other.photoUrls, photoUrls);

  @override
  int get hashCode => Object.hash(
    estimate,
    level,
    description,
    const ListEquality<String>().hash(photoUrls),
  );
}
