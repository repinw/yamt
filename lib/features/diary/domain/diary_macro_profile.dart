/// Neutral description of the distribution of energy among the three macros.
enum DiaryMacroEmphasis {
  /// Protein contributes the largest share.
  protein,

  /// Carbohydrates contribute the largest share.
  carbs,

  /// Fat contributes the largest share.
  fat,

  /// No share leads the next by ten percentage points.
  mixed,
}

/// Unrounded macro energy shares for a recorded portion.
class DiaryMacroProfile {
  const DiaryMacroProfile._(this.protein, this.carbs, this.fat, this.emphasis);

  /// Builds a profile only from complete, attributable nutrition.
  static DiaryMacroProfile? calculate({
    required double protein,
    required double carbs,
    required double fat,
  }) {
    if ([protein, carbs, fat].any((value) => !value.isFinite || value < 0)) {
      return null;
    }
    final energy = [protein * 4, carbs * 4, fat * 9];
    final total = energy.reduce((a, b) => a + b);
    if (!total.isFinite || total <= 0) return null;
    final shares = energy.map((value) => value / total).toList();
    final ranked = [0, 1, 2]..sort((a, b) => energy[b].compareTo(energy[a]));
    // Compare energy before division to avoid rounding displayed percentages.
    final lead = energy[ranked[0]] - energy[ranked[1]];
    final dominant = lead >= total * 0.1 - total * 1e-12;
    return DiaryMacroProfile._(
      shares[0],
      shares[1],
      shares[2],
      dominant
          ? DiaryMacroEmphasis.values[ranked[0]]
          : DiaryMacroEmphasis.mixed,
    );
  }

  /// Protein energy share, from zero to one.
  final double protein;

  /// Carbohydrate energy share, from zero to one.
  final double carbs;

  /// Fat energy share, from zero to one.
  final double fat;

  /// Description of this distribution, without a health rating.
  final DiaryMacroEmphasis emphasis;
}
