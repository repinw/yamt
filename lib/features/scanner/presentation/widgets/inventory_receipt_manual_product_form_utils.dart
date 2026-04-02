String? normalizeManualProductText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

double? parseManualProductDouble(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return double.tryParse(trimmed.replaceAll(',', '.'));
}

String formatManualProductDouble(double? value) {
  if (value == null) {
    return '';
  }
  if (value.truncateToDouble() == value) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}
