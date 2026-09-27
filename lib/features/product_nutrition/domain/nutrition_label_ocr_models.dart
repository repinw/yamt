import 'dart:math' show max;

/// Nutrition values read from a label, per 100 g or 100 ml.
///
/// Holds every value that EU food labels must print (Regulation 1169/2011):
/// energy in kJ and kcal, fat, saturates, carbohydrate, sugars, protein, and
/// salt.
class NutritionLabelOcrDraft {
  /// Creates a nutrition label OCR draft.
  const new({
    required this.barcode,
    required this.per100Kj,
    required this.per100Kcal,
    required this.per100Fat,
    required this.per100SaturatedFat,
    required this.per100Carbs,
    required this.per100Sugar,
    required this.per100Protein,
    required this.per100Salt,
    this.name,
    this.brand,
    this.quantityLabel,
    this.servingSizeLabel,
    this.per100PolyunsaturatedFat,
    this.per100Fiber,
  });

  /// Grams above 100 that label rounding can explain in a nutrient sum.
  static const _massTolerance = 1.0;

  /// Grams by which a "davon" value may exceed its parent: one 0.1 g
  /// rounding step on the label, plus slack for floating-point sums.
  static const _partTolerance = 0.15;

  /// Highest possible energy density: pure fat.
  static const _maxKcal = 900.0;

  static const _kjPerKcal = 4.184;
  static const _kjToleranceShare = 0.05;
  static const _kjToleranceMin = 8.0;

  /// The barcode.
  final String barcode;

  /// The name.
  final String? name;

  /// The brand.
  final String? brand;

  /// The quantity label.
  final String? quantityLabel;

  /// The serving size label.
  final String? servingSizeLabel;

  /// The per100 kJ.
  final double per100Kj;

  /// The per100 kcal.
  final double per100Kcal;

  /// The per100 fat.
  final double per100Fat;

  /// The per100 saturated fat.
  final double per100SaturatedFat;

  /// The per100 carbs.
  final double per100Carbs;

  /// The per100 sugar.
  final double per100Sugar;

  /// The per100 protein.
  final double per100Protein;

  /// The per100 salt.
  final double per100Salt;

  /// The per100 polyunsaturated fat.
  final double? per100PolyunsaturatedFat;

  /// The per100 fiber.
  final double? per100Fiber;

  /// Whether the values can belong to a real food.
  ///
  /// Checks only hard limits that no correct label breaks. Whether kcal fits
  /// the macros is left to the model, because sugar alcohols and alcohol
  /// legitimately break that rule.
  bool get isPlausible {
    final values = [
      per100Kj,
      per100Kcal,
      per100Fat,
      per100SaturatedFat,
      per100Carbs,
      per100Sugar,
      per100Protein,
      per100Salt,
      ?per100PolyunsaturatedFat,
      ?per100Fiber,
    ];
    if (values.any((value) => value < 0)) return false;

    final mass =
        per100Fat +
        per100Carbs +
        per100Protein +
        per100Salt +
        (per100Fiber ?? 0);
    final kjTolerance = max(_kjToleranceMin, per100Kj * _kjToleranceShare);

    return per100SaturatedFat <= per100Fat + _partTolerance &&
        (per100PolyunsaturatedFat ?? 0) <= per100Fat + _partTolerance &&
        per100Sugar <= per100Carbs + _partTolerance &&
        mass <= 100 + _massTolerance &&
        per100Kcal <= _maxKcal &&
        (per100Kj - per100Kcal * _kjPerKcal).abs() <= kjTolerance;
  }
}

/// Defines nutrition label OCR status.
enum NutritionLabelOcrStatus {
  /// Succeeded.
  succeeded,

  /// Canceled.
  canceled,

  /// Failed.
  failed,
}

/// Defines nutrition label OCR result.
class NutritionLabelOcrResult {
  /// Creates a succeeded result.
  const new succeeded({required NutritionLabelOcrDraft draft})
    : this._(status: NutritionLabelOcrStatus.succeeded, draft: draft);

  /// Creates a canceled result.
  const new canceled() : this._(status: NutritionLabelOcrStatus.canceled);

  /// Creates a failed result.
  const new failed({required String errorCode})
    : this._(status: NutritionLabelOcrStatus.failed, errorCode: errorCode);

  const new _({required this.status, this.draft, this.errorCode});

  /// The status.
  final NutritionLabelOcrStatus status;

  /// The parsed draft.
  final NutritionLabelOcrDraft? draft;

  /// The error code.
  final String? errorCode;
}
