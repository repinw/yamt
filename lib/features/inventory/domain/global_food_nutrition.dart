import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'global_food_nutrition.freezed.dart';

/// Defines global food nutrition quality status.
enum GlobalFoodNutritionQualityStatus {
  /// Missing.
  missing,

  /// Unverified.
  unverified,

  /// Verified.
  verified
  ;

  /// Resolves quality status from dynamic JSON value.
  static GlobalFoodNutritionQualityStatus fromJson(Object? value) {
    final raw = value is String ? value.trim() : '';
    if (raw == 'partial') {
      return GlobalFoodNutritionQualityStatus.unverified;
    }
    return GlobalFoodNutritionQualityStatus.values.firstWhereOrNull(
          (status) => status.name == raw,
        ) ??
        GlobalFoodNutritionQualityStatus.missing;
  }
}

/// Defines global food nutrition model.
@freezed
abstract class GlobalFoodNutrition with _$GlobalFoodNutrition {
  /// The global food nutrition.
  const factory GlobalFoodNutrition({
    required GlobalFoodNutritionQualityStatus qualityStatus,
    double? per100Kcal,
    double? per100Protein,
    double? per100Carbs,
    double? per100Fat,
    double? per100Salt,
    double? per100SaturatedFat,
    double? per100PolyunsaturatedFat,
    double? per100Sugar,
    double? per100Fiber,
  }) = _GlobalFoodNutrition;

  const GlobalFoodNutrition._();

  /// Creates a [GlobalFoodNutrition] from json payload with optional fallback.
  factory GlobalFoodNutrition.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? fallback,
    GlobalFoodNutritionQualityStatus? qualityStatusOverride,
  }) {
    double? read(List<String> keys) => _readFirstDouble(json, fallback, keys);

    final directKcal = read(const <String>[
      'per_100_kcal',
      'energy_kcal_100g',
      'energy-kcal_100g',
      'energy_kcal_100ml',
      'energy-kcal_100ml',
      'energy_kcal',
    ]);
    final kj = directKcal != null
        ? null
        : read(const <String>[
            'energy_kj_100g',
            'energy-kj_100g',
            'energy_kj_100ml',
            'energy-kj_100ml',
            'energy_100g',
            'energy_100ml',
            'energy_kj',
          ]);
    final resolvedKcal = directKcal ?? (kj != null ? (kj / 4.184) : null);

    final directSalt = read(const <String>[
      'per_100_salt',
      'salt_100g',
      'salt_100ml',
      'salt',
    ]);
    final sodium = directSalt != null
        ? null
        : read(const <String>[
            'sodium_100g',
            'sodium_100ml',
            'sodium',
          ]);
    final resolvedSalt = directSalt ?? (sodium != null ? (sodium * 2.5) : null);

    final qualityStatus =
        qualityStatusOverride ??
        GlobalFoodNutritionQualityStatus.fromJson(
          json['quality_status'] ?? fallback?['quality_status'],
        );

    return GlobalFoodNutrition(
      qualityStatus: qualityStatus,
      per100Kcal: resolvedKcal,
      per100Protein: read(const <String>[
        'per_100_protein',
        'proteins_100g',
        'proteins_100ml',
        'proteins',
      ]),
      per100Carbs: read(const <String>[
        'per_100_carbs',
        'carbohydrates_100g',
        'carbohydrates_100ml',
        'carbohydrates',
      ]),
      per100Fat: read(const <String>[
        'per_100_fat',
        'fat_100g',
        'fat_100ml',
        'fat',
      ]),
      per100Salt: resolvedSalt,
      per100SaturatedFat: read(const <String>[
        'per_100_saturated_fat',
        'saturated-fat_100g',
        'saturated_fat_100g',
        'saturated-fat_100ml',
        'saturated_fat_100ml',
        'saturated_fat',
      ]),
      per100PolyunsaturatedFat: read(const <String>[
        'per_100_polyunsaturated_fat',
        'polyunsaturated-fat_100g',
        'polyunsaturated_fat_100g',
        'polyunsaturated-fat_100ml',
        'polyunsaturated_fat_100ml',
        'polyunsaturated_fat',
      ]),
      per100Sugar: read(const <String>[
        'per_100_sugar',
        'sugars_100g',
        'sugars_100ml',
        'sugars',
        'sugar',
      ]),
      per100Fiber: read(const <String>[
        'per_100_fiber',
        'fiber_100g',
        'fibre_100g',
        'fiber_100ml',
        'fibre_100ml',
        'fiber',
        'fibre',
      ]),
    );
  }

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

  /// Whether the mandatory EU nutrition declaration is complete.
  bool get hasEuMandatoryNutritionDeclaration {
    return per100Kcal != null &&
        per100Fat != null &&
        per100SaturatedFat != null &&
        per100Carbs != null &&
        per100Sugar != null &&
        per100Protein != null &&
        per100Salt != null;
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

double? _readFirstDouble(
  Map<String, dynamic> primary,
  Map<String, dynamic>? fallback,
  List<String> keys,
) {
  for (final key in keys) {
    final value = _readDouble(primary[key]);
    if (value != null) {
      return value;
    }
  }
  if (fallback != null) {
    for (final key in keys) {
      final value = _readDouble(fallback[key]);
      if (value != null) {
        return value;
      }
    }
  }
  return null;
}
