import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'recipe_estimate.g.dart';

/// The AI's rough nutrition of one portion of a recipe, made from its
/// ingredient lines before any Vorrat food is assigned, so the cook can plan
/// before shopping.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class RecipeEstimate {
  /// Creates the estimate made at [createdAt] for [portions] portions of
  /// the ingredient lines with [linesKey].
  const new({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portions,
    required this.linesKey,
    required this.createdAt,
    this.lines,
  });

  /// Creates a [RecipeEstimate] from json.
  factory fromJson(Map<String, dynamic> json) => _$RecipeEstimateFromJson(json);

  /// The kcal of one portion.
  final double kcal;

  /// The protein of one portion in grams.
  final double protein;

  /// The carbohydrates of one portion in grams.
  final double carbs;

  /// The fat of one portion in grams.
  final double fat;

  /// The portions the recipe was written for when the estimate was made.
  final int portions;

  /// The [recipeLinesKey] of the ingredient lines the estimate was made
  /// from.
  final String linesKey;

  /// When the estimate was made.
  final DateTime createdAt;

  /// The kcal and macros of each whole ingredient line, in the order of the
  /// lines the estimate was made from; `null` for an estimate without them,
  /// such as one of the recipe estimate template.
  @JsonKey(includeIfNull: false)
  final List<RecipeLineNutrition>? lines;

  /// Whether the estimate was made from [lines] for [portions] portions.
  bool isFor(List<String> lines, int portions) =>
      this.portions == portions && linesKey == recipeLinesKey(lines);

  /// To json.
  Map<String, dynamic> toJson() => _$RecipeEstimateToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeEstimate &&
          other.kcal == kcal &&
          other.protein == protein &&
          other.carbs == carbs &&
          other.fat == fat &&
          other.portions == portions &&
          other.linesKey == linesKey &&
          other.createdAt == createdAt &&
          const ListEquality<RecipeLineNutrition>().equals(other.lines, lines);

  @override
  int get hashCode => Object.hash(
    kcal,
    protein,
    carbs,
    fat,
    portions,
    linesKey,
    createdAt,
    const ListEquality<RecipeLineNutrition>().hash(lines),
  );
}

/// The kcal and macros of one whole ingredient line of a recipe, for the
/// portions the recipe is written for.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class RecipeLineNutrition {
  /// Creates the nutrition of a line.
  const new({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Creates a [RecipeLineNutrition] from json.
  factory fromJson(Map<String, dynamic> json) =>
      _$RecipeLineNutritionFromJson(json);

  /// The kcal of the line.
  final double kcal;

  /// The protein of the line in grams.
  final double protein;

  /// The carbohydrates of the line in grams.
  final double carbs;

  /// The fat of the line in grams.
  final double fat;

  /// The nutrition of the line [factor] times, such as for other portions.
  RecipeLineNutrition scaled(double factor) => RecipeLineNutrition(
    kcal: kcal * factor,
    protein: protein * factor,
    carbs: carbs * factor,
    fat: fat * factor,
  );

  /// To json.
  Map<String, dynamic> toJson() => _$RecipeLineNutritionToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeLineNutrition &&
          other.kcal == kcal &&
          other.protein == protein &&
          other.carbs == carbs &&
          other.fat == fat;

  @override
  int get hashCode => Object.hash(kcal, protein, carbs, fat);
}

/// The key that tells whether a recipe's ingredient [lines] changed since
/// an estimate: the lines in their order.
String recipeLinesKey(List<String> lines) => lines.join('\n');

/// The unit of a recipe line's weight.
enum RecipeLineWeightUnit {
  /// Grams.
  @JsonValue('g')
  gram,

  /// Milliliters.
  @JsonValue('ml')
  milliliter,
}

/// Where a recipe line's weight comes from.
enum RecipeLineWeightSource {
  /// The AI estimated it from the line.
  @JsonValue('ai')
  ai,

  /// The cook typed it.
  @JsonValue('user')
  user,
}

/// The rough weight of a whole recipe line, such as 150 g for "1 Zwiebel".
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class RecipeLineWeight {
  /// Creates the weight [amount] in [unit] from [source].
  const new({required this.amount, required this.unit, required this.source});

  /// Creates a [RecipeLineWeight] from json.
  factory fromJson(Map<String, dynamic> json) =>
      _$RecipeLineWeightFromJson(json);

  /// The amount in [unit], above zero.
  final int amount;

  /// Grams or milliliters.
  final RecipeLineWeightUnit unit;

  /// Who set the weight.
  final RecipeLineWeightSource source;

  /// Whether the cook typed the weight.
  bool get isFromUser => source == RecipeLineWeightSource.user;

  /// To json.
  Map<String, dynamic> toJson() => _$RecipeLineWeightToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeLineWeight &&
          other.amount == amount &&
          other.unit == unit &&
          other.source == source;

  @override
  int get hashCode => Object.hash(amount, unit, source);
}
