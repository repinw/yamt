/// Defines nutrition label OCR draft.
class NutritionLabelOcrDraft {
  /// Creates a nutrition label OCR draft.
  const NutritionLabelOcrDraft({
    required this.barcode,
    this.name,
    this.brand,
    this.quantityLabel,
    this.servingSizeLabel,
    this.per100Kcal,
    this.per100Protein,
    this.per100Carbs,
    this.per100Fat,
    this.per100Salt,
    this.per100SaturatedFat,
    this.per100PolyunsaturatedFat,
    this.per100Sugar,
    this.per100Fiber,
  });

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

  /// The per100 kcal.
  final double? per100Kcal;

  /// The per100 protein.
  final double? per100Protein;

  /// The per100 carbs.
  final double? per100Carbs;

  /// The per100 fat.
  final double? per100Fat;

  /// The per100 salt.
  final double? per100Salt;

  /// The per100 saturated fat.
  final double? per100SaturatedFat;

  /// The per100 polyunsaturated fat.
  final double? per100PolyunsaturatedFat;

  /// The per100 sugar.
  final double? per100Sugar;

  /// The per100 fiber.
  final double? per100Fiber;

  /// Whether any nutrition value exists.
  bool get hasAnyNutritionValue {
    return per100Kcal != null ||
        per100Protein != null ||
        per100Carbs != null ||
        per100Fat != null ||
        per100Salt != null ||
        per100SaturatedFat != null ||
        per100PolyunsaturatedFat != null ||
        per100Sugar != null ||
        per100Fiber != null;
  }

  /// Whether any value was detected at all.
  bool get hasAnyDetectedValue {
    return hasAnyNutritionValue ||
        _hasText(name) ||
        _hasText(brand) ||
        _hasText(quantityLabel) ||
        _hasText(servingSizeLabel);
  }

  static bool _hasText(String? value) {
    return _normalizedText(value) != null;
  }

  static String? _normalizedText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
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
  const NutritionLabelOcrResult.succeeded({
    required NutritionLabelOcrDraft draft,
  }) : this._(
         status: NutritionLabelOcrStatus.succeeded,
         draft: draft,
       );

  /// Creates a canceled result.
  const NutritionLabelOcrResult.canceled()
    : this._(status: NutritionLabelOcrStatus.canceled);

  /// Creates a failed result.
  const NutritionLabelOcrResult.failed({required String errorCode})
    : this._(
        status: NutritionLabelOcrStatus.failed,
        errorCode: errorCode,
      );

  const NutritionLabelOcrResult._({
    required this.status,
    this.draft,
    this.errorCode,
  });

  /// The status.
  final NutritionLabelOcrStatus status;

  /// The parsed draft.
  final NutritionLabelOcrDraft? draft;

  /// The error code.
  final String? errorCode;
}
