import 'package:meta/meta.dart';

/// The numbers of the "Gekocht" step: the pot on the scale, what it leaves
/// for the food, and what one portion holds.
@immutable
class CookedPot {
  /// Creates the numbers for the typed pot weight [grossInput], the empty pot
  /// [tareWeight] (0 without a pot), [portions], and the meal's [totalKcal].
  const new({
    required this.grossInput,
    required this.tareWeight,
    required this.portions,
    required this.totalKcal,
  });

  /// The typed weight of the pot on the scale; empty when it was not weighed.
  final String grossInput;

  /// The weight of the empty pot in grams.
  final int tareWeight;

  /// The number of portions; at least 1.
  final int portions;

  /// The kcal of the whole meal.
  final double totalKcal;

  /// The pot on the scale in grams, or `null` when it was not weighed.
  int? get grossWeight => int.tryParse(grossInput);

  /// The food weight: the pot on the scale minus the empty pot, or `null`
  /// when the pot was not weighed or is not heavier than the empty pot.
  int? get netWeight => switch (grossWeight) {
    final gross? when gross > tareWeight => gross - tareWeight,
    _ => null,
  };

  /// Whether the pot was weighed but is not heavier than the empty pot. The
  /// step cannot be saved then.
  bool get isTooLight => grossWeight != null && netWeight == null;

  /// Grams of food per portion, or `null` without a food weight.
  int? get gramsPerPortion => switch (netWeight) {
    final net? => (net / portions).round(),
    null => null,
  };

  /// kcal per portion.
  int get kcalPerPortion => (totalKcal / portions).round();
}
