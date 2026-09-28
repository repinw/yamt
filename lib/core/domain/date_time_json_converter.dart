import 'package:json_annotation/json_annotation.dart';

/// Reads a date field that `normalizeFirestoreJson` already turned into a
/// [DateTime]. Any other type is an error.
class DateTimeJsonConverter implements JsonConverter<DateTime, DateTime> {
  /// Creates the converter.
  const new();

  @override
  DateTime fromJson(DateTime json) => json;

  @override
  DateTime toJson(DateTime object) => object;
}
