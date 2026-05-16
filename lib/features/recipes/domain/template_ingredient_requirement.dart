/// Defines template ingredient amount unit.
enum TemplateIngredientUnit {
  /// Gram.
  gram,

  /// Milliliter.
  milliliter,

  /// Piece.
  piece,
}

/// Defines template ingredient amount unit code extension.
extension TemplateIngredientUnitCode on TemplateIngredientUnit {
  /// The storage/display code.
  String get code {
    return switch (this) {
      TemplateIngredientUnit.gram => 'g',
      TemplateIngredientUnit.milliliter => 'ml',
      TemplateIngredientUnit.piece => 'pc',
    };
  }
}

/// Defines template ingredient requirement.
class TemplateIngredientRequirement {
  /// The template ingredient requirement.
  const TemplateIngredientRequirement({
    required this.amount,
    required this.unit,
    required this.name,
    this.countMeasureLabel,
    this.packageCountLabel,
    this.allowsDirectPieceInventoryMatch = true,
  });

  /// The amount.
  final int amount;

  /// The unit.
  final TemplateIngredientUnit unit;

  /// The name.
  final String name;

  /// The count measure label.
  final String? countMeasureLabel;

  /// Package count display label, for example `1x`.
  final String? packageCountLabel;

  /// Whether direct piece inventory match.
  final bool allowsDirectPieceInventoryMatch;
}
