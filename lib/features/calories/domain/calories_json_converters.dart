import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';

/// Stores [CalorieNutrientDetails] as a nested map with snake_case keys.
class NullableCalorieNutrientDetailsConverter
    implements JsonConverter<CalorieNutrientDetails?, Object?> {
  /// Creates the converter.
  const new();

  static const _saturatedFat = 'per_100_saturated_fat';
  static const _polyunsaturatedFat = 'per_100_polyunsaturated_fat';
  static const _sugar = 'per_100_sugar';
  static const _fiber = 'per_100_fiber';
  static const _salt = 'per_100_salt';

  @override
  CalorieNutrientDetails? fromJson(Object? json) {
    if (json == null) {
      return null;
    }
    final map = json as Map<String, dynamic>;
    return CalorieNutrientDetails(
      per100SaturatedFat: (map[_saturatedFat] as num?)?.toDouble(),
      per100PolyunsaturatedFat: (map[_polyunsaturatedFat] as num?)?.toDouble(),
      per100Sugar: (map[_sugar] as num?)?.toDouble(),
      per100Fiber: (map[_fiber] as num?)?.toDouble(),
      per100Salt: (map[_salt] as num?)?.toDouble(),
    );
  }

  @override
  Object? toJson(CalorieNutrientDetails? object) {
    if (object == null) {
      return null;
    }
    return <String, Object?>{
      _saturatedFat: object.per100SaturatedFat,
      _polyunsaturatedFat: object.per100PolyunsaturatedFat,
      _sugar: object.per100Sugar,
      _fiber: object.per100Fiber,
      _salt: object.per100Salt,
    };
  }
}
