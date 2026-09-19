import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';

/// Parses numeric JSON values from `num` or locale-like `String` input.
class FlexibleDoubleConverter implements JsonConverter<double, Object?> {
  /// The flexible double converter.
  const new();

  @override
  double fromJson(Object? json) {
    if (json is num) {
      return json.toDouble();
    }
    if (json is String) {
      final normalized = json.replaceAll(',', '.').trim();
      final parsed = double.tryParse(normalized);
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException('Expected number but got: $json');
  }

  @override
  Object? toJson(double object) {
    return object;
  }
}

/// Defines nullable flexible double converter.
class NullableFlexibleDoubleConverter
    implements JsonConverter<double?, Object?> {
  /// The nullable flexible double converter.
  const new();

  @override
  double? fromJson(Object? json) {
    if (json == null) {
      return null;
    }
    return const FlexibleDoubleConverter().fromJson(json);
  }

  @override
  Object? toJson(double? object) {
    return object;
  }
}

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

/// Defines flexible date time converter.
class FlexibleDateTimeConverter implements JsonConverter<DateTime, Object?> {
  /// The flexible date time converter.
  const new();

  @override
  DateTime fromJson(Object? json) {
    if (json is DateTime) {
      return json;
    }
    if (json is String) {
      final parsed = DateTime.tryParse(json);
      if (parsed != null) {
        return parsed;
      }
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    throw FormatException('Expected DateTime but got: $json');
  }

  @override
  Object? toJson(DateTime object) {
    return object;
  }
}

/// Defines nullable flexible date time converter.
class NullableFlexibleDateTimeConverter
    implements JsonConverter<DateTime?, Object?> {
  /// The nullable flexible date time converter.
  const new();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) {
      return null;
    }
    return const FlexibleDateTimeConverter().fromJson(json);
  }

  @override
  Object? toJson(DateTime? object) {
    return object;
  }
}
