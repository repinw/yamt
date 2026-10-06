import 'package:meta/meta.dart';

/// The numbers of the "Gekocht" step: the pot on the scale, what it leaves
/// for the food, and what one portion holds.
@immutable
class CookedPot {
  /// Creates the numbers for the typed pot weight [grossInput], the empty pot
  /// [tareWeight] (`null` without a pot), [portions], and the meal's
  /// [totalKcal].
  const new({
    required this.grossInput,
    required this.tareWeight,
    required this.portions,
    required this.totalKcal,
  });

  /// The typed weight of the pot on the scale; empty when it was not weighed.
  final String grossInput;

  /// The weight of the empty pot in grams, or `null` when no pot is picked.
  final int? tareWeight;

  /// The number of portions; at least 1.
  final int portions;

  /// The kcal of the whole meal.
  final double totalKcal;

  /// The pot on the scale in grams, or `null` when it was not weighed.
  int? get grossWeight => int.tryParse(grossInput);

  /// The food weight: the pot on the scale minus the empty pot, or `null`
  /// when the pot was not weighed, no pot is picked, or it is not heavier
  /// than the empty pot.
  int? get netWeight => switch ((grossWeight, tareWeight)) {
    (final gross?, final tare?) when gross > tare => gross - tare,
    _ => null,
  };

  /// Whether the pot was weighed without picking the pot. Without its weight
  /// the food weight would be wrong, so the step cannot be saved then.
  bool get needsUtensil => grossWeight != null && tareWeight == null;

  /// Whether the pot was weighed but is not heavier than the empty pot. The
  /// step cannot be saved then.
  bool get isTooLight =>
      grossWeight != null && tareWeight != null && netWeight == null;

  /// Grams of food per portion, or `null` without a food weight.
  int? get gramsPerPortion => switch (netWeight) {
    final net? => (net / portions).round(),
    null => null,
  };

  /// kcal per portion.
  int get kcalPerPortion => (totalKcal / portions).round();
}
