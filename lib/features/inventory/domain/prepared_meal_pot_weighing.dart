import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'prepared_meal_pot_weighing.g.dart';

/// The last time someone weighed the food of a cooked meal, in its pot while
/// eating from it or with "Gewicht ändern": the food left then, and the
/// portions left then.
///
/// Water evaporates from a pot over days, so the weight at "Gekocht" stops
/// telling what a gram is worth. A fresh weighing ties the food left to the
/// portions left, and later eaters of the household start from it.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class PreparedMealPotWeighing {
  /// Creates the weighing.
  const new({
    required this.netWeight,
    required this.weighedAt,
    required this.remainingPortions,
  });

  /// Creates a [PreparedMealPotWeighing] from json.
  factory fromJson(Map<String, dynamic> json) =>
      _$PreparedMealPotWeighingFromJson(json);

  /// Grams of food left: the pot on the scale minus the empty pot, or the
  /// food weighed on its own.
  final int netWeight;

  /// When the pot was weighed.
  final DateTime weighedAt;

  /// The meal's remaining portions when the pot was weighed.
  final num remainingPortions;

  /// Grams left now when [remaining] portions are left, assuming nothing
  /// evaporated since the weighing.
  int? netWeightFor(num remaining) {
    if (remainingPortions <= 0) {
      return null;
    }
    return (netWeight * remaining / remainingPortions).round();
  }

  /// To json.
  Map<String, dynamic> toJson() => _$PreparedMealPotWeighingToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreparedMealPotWeighing &&
          other.netWeight == netWeight &&
          other.weighedAt == weighedAt &&
          other.remainingPortions == remainingPortions;

  @override
  int get hashCode => Object.hash(netWeight, weighedAt, remainingPortions);
}
