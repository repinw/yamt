/// Normalize manual product text.
String? normalizeManualProductText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

/// Parse manual product double.
double? parseManualProductDouble(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return double.tryParse(trimmed.replaceAll(',', '.'));
}

/// Format manual product double.
String formatManualProductDouble(double? value) {
  if (value == null) {
    return '';
  }
  if (value.truncateToDouble() == value) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}
