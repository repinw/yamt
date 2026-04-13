/// Reads a positive integer-like value from JSON-compatible input.
int? readJsonPositiveInt(Object? value) {
  if (value is int) {
    return value < 1 ? 1 : value;
  }
  if (value is num) {
    final normalized = value.toInt();
    return normalized < 1 ? 1 : normalized;
  }
  return null;
}

/// Reads a non-negative integer-like value from JSON-compatible input.
int? readJsonNonNegativeInt(Object? value) {
  if (value is int) {
    return value < 0 ? 0 : value;
  }
  if (value is num) {
    final normalized = value.toInt();
    return normalized < 0 ? 0 : normalized;
  }
  return null;
}

/// Reads an ISO-8601 datetime string or `DateTime` from JSON-compatible input.
DateTime? readJsonDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.trim());
}

/// Reads a dynamic map and normalizes keys to strings.
Map<String, dynamic>? readJsonMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map<String, dynamic>(
    (key, item) => MapEntry<String, dynamic>(key.toString(), item),
  );
}
