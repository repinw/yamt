import 'package:json_annotation/json_annotation.dart';

/// Parses numeric JSON values from `num` or locale-like `String` input.
class FlexibleDoubleConverter implements JsonConverter<double, Object?> {
  /// The flexible double converter.
  const FlexibleDoubleConverter();

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
  const NullableFlexibleDoubleConverter();

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

/// Defines flexible date time converter.
class FlexibleDateTimeConverter implements JsonConverter<DateTime, Object?> {
  /// The flexible date time converter.
  const FlexibleDateTimeConverter();

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
  const NullableFlexibleDateTimeConverter();

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
