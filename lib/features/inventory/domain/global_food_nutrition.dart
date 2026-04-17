import 'package:collection/collection.dart';

/// Defines global food nutrition quality status.
enum GlobalFoodNutritionQualityStatus {
  /// Missing.
  missing,

  /// Unverified.
  unverified,

  /// Verified.
  verified,
}

/// Defines global food nutrition.
class GlobalFoodNutrition {
  /// The global food nutrition.
  const GlobalFoodNutrition({
    required this.qualityStatus,
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

  /// Creates a [GlobalFoodNutrition] for from json.
  factory GlobalFoodNutrition.fromJson(Map<String, dynamic> json) {
    return GlobalFoodNutrition(
      qualityStatus: _nutritionQualityFromJson(json['quality_status']),
      per100Kcal: _readFirstDouble(json, const <String>[
        'per_100_kcal',
        'energy_kcal_100g',
        'energy-kcal_100g',
      ]),
      per100Protein: _readFirstDouble(json, const <String>[
        'per_100_protein',
        'proteins_100g',
      ]),
      per100Carbs: _readFirstDouble(json, const <String>[
        'per_100_carbs',
        'carbohydrates_100g',
      ]),
      per100Fat: _readFirstDouble(json, const <String>[
        'per_100_fat',
        'fat_100g',
      ]),
      per100Salt: _readFirstDouble(json, const <String>[
        'per_100_salt',
        'salt_100g',
      ]),
      per100SaturatedFat: _readFirstDouble(json, const <String>[
        'per_100_saturated_fat',
        'saturated-fat_100g',
        'saturated_fat_100g',
      ]),
      per100PolyunsaturatedFat: _readFirstDouble(json, const <String>[
        'per_100_polyunsaturated_fat',
        'polyunsaturated-fat_100g',
        'polyunsaturated_fat_100g',
      ]),
      per100Sugar: _readFirstDouble(json, const <String>[
        'per_100_sugar',
        'sugars_100g',
      ]),
      per100Fiber: _readFirstDouble(json, const <String>[
        'per_100_fiber',
        'fiber_100g',
        'fibre_100g',
      ]),
    );
  }

  /// The quality status.
  final GlobalFoodNutritionQualityStatus qualityStatus;

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

  /// To json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'quality_status': qualityStatus.name,
      'per_100_kcal': per100Kcal,
      'per_100_protein': per100Protein,
      'per_100_carbs': per100Carbs,
      'per_100_fat': per100Fat,
      'per_100_salt': per100Salt,
      'per_100_saturated_fat': per100SaturatedFat,
      'per_100_polyunsaturated_fat': per100PolyunsaturatedFat,
      'per_100_sugar': per100Sugar,
      'per_100_fiber': per100Fiber,
    };
  }

  /// Copy with.
  GlobalFoodNutrition copyWith({
    GlobalFoodNutritionQualityStatus? qualityStatus,
    Object? per100Kcal = _keepValue,
    Object? per100Protein = _keepValue,
    Object? per100Carbs = _keepValue,
    Object? per100Fat = _keepValue,
    Object? per100Salt = _keepValue,
    Object? per100SaturatedFat = _keepValue,
    Object? per100PolyunsaturatedFat = _keepValue,
    Object? per100Sugar = _keepValue,
    Object? per100Fiber = _keepValue,
  }) {
    return GlobalFoodNutrition(
      qualityStatus: qualityStatus ?? this.qualityStatus,
      per100Kcal: per100Kcal == _keepValue
          ? this.per100Kcal
          : per100Kcal as double?,
      per100Protein: per100Protein == _keepValue
          ? this.per100Protein
          : per100Protein as double?,
      per100Carbs: per100Carbs == _keepValue
          ? this.per100Carbs
          : per100Carbs as double?,
      per100Fat: per100Fat == _keepValue
          ? this.per100Fat
          : per100Fat as double?,
      per100Salt: per100Salt == _keepValue
          ? this.per100Salt
          : per100Salt as double?,
      per100SaturatedFat: per100SaturatedFat == _keepValue
          ? this.per100SaturatedFat
          : per100SaturatedFat as double?,
      per100PolyunsaturatedFat: per100PolyunsaturatedFat == _keepValue
          ? this.per100PolyunsaturatedFat
          : per100PolyunsaturatedFat as double?,
      per100Sugar: per100Sugar == _keepValue
          ? this.per100Sugar
          : per100Sugar as double?,
      per100Fiber: per100Fiber == _keepValue
          ? this.per100Fiber
          : per100Fiber as double?,
    );
  }

  /// Whether any nutrition value.
  bool get hasAnyNutritionValue {
    return <double?>[
      per100Kcal,
      per100Protein,
      per100Carbs,
      per100Fat,
      per100Salt,
      per100SaturatedFat,
      per100PolyunsaturatedFat,
      per100Sugar,
      per100Fiber,
    ].any((value) => value != null);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GlobalFoodNutrition &&
            other.qualityStatus == qualityStatus &&
            other.per100Kcal == per100Kcal &&
            other.per100Protein == per100Protein &&
            other.per100Carbs == per100Carbs &&
            other.per100Fat == per100Fat &&
            other.per100Salt == per100Salt &&
            other.per100SaturatedFat == per100SaturatedFat &&
            other.per100PolyunsaturatedFat == per100PolyunsaturatedFat &&
            other.per100Sugar == per100Sugar &&
            other.per100Fiber == per100Fiber;
  }

  @override
  int get hashCode {
    return Object.hash(
      qualityStatus,
      per100Kcal,
      per100Protein,
      per100Carbs,
      per100Fat,
      per100Salt,
      per100SaturatedFat,
      per100PolyunsaturatedFat,
      per100Sugar,
      per100Fiber,
    );
  }

  @override
  String toString() {
    return 'GlobalFoodNutrition('
        'qualityStatus: $qualityStatus, '
        'per100Kcal: $per100Kcal, '
        'per100Protein: $per100Protein, '
        'per100Carbs: $per100Carbs, '
        'per100Fat: $per100Fat, '
        'per100Salt: $per100Salt, '
        'per100SaturatedFat: $per100SaturatedFat, '
        'per100PolyunsaturatedFat: $per100PolyunsaturatedFat, '
        'per100Sugar: $per100Sugar, '
        'per100Fiber: $per100Fiber'
        ')';
  }
}

double? _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

double? _readFirstDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _readDouble(json[key]);
    if (value != null) {
      return value;
    }
  }
  return null;
}

GlobalFoodNutritionQualityStatus _nutritionQualityFromJson(Object? value) {
  final raw = value is String ? value.trim() : '';
  if (raw == 'partial') {
    return GlobalFoodNutritionQualityStatus.unverified;
  }
  return GlobalFoodNutritionQualityStatus.values.firstWhereOrNull(
        (status) => status.name == raw,
      ) ??
      GlobalFoodNutritionQualityStatus.missing;
}

const Object _keepValue = Object();
