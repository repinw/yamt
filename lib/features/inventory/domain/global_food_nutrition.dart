import 'package:collection/collection.dart';

enum GlobalFoodNutritionQualityStatus { missing, unverified, verified }

class GlobalFoodNutrition {
  const GlobalFoodNutrition({
    required this.qualityStatus,
    this.per100Kcal,
    this.per100Protein,
    this.per100Carbs,
    this.per100Fat,
    this.per100Salt,
  });

  final GlobalFoodNutritionQualityStatus qualityStatus;
  final double? per100Kcal;
  final double? per100Protein;
  final double? per100Carbs;
  final double? per100Fat;
  final double? per100Salt;

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
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'quality_status': qualityStatus.name,
      'per_100_kcal': per100Kcal,
      'per_100_protein': per100Protein,
      'per_100_carbs': per100Carbs,
      'per_100_fat': per100Fat,
      'per_100_salt': per100Salt,
    };
  }

  GlobalFoodNutrition copyWith({
    GlobalFoodNutritionQualityStatus? qualityStatus,
    Object? per100Kcal = _keepValue,
    Object? per100Protein = _keepValue,
    Object? per100Carbs = _keepValue,
    Object? per100Fat = _keepValue,
    Object? per100Salt = _keepValue,
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
    );
  }

  bool get hasAnyNutritionValue {
    return <double?>[
      per100Kcal,
      per100Protein,
      per100Carbs,
      per100Fat,
      per100Salt,
    ].any((value) => value != null);
  }

  bool get isAllZero {
    final values = <double?>[
      per100Kcal,
      per100Protein,
      per100Carbs,
      per100Fat,
      per100Salt,
    ].whereType<double>();
    if (values.isEmpty) {
      return false;
    }
    return values.every((value) => value == 0);
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
            other.per100Salt == per100Salt;
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
        'per100Salt: $per100Salt'
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
