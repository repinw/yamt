/// Defines calorie calculator field error.
enum CalorieCalculatorFieldError {
  /// Empty.
  empty,

  /// Invalid.
  invalid,
}

/// Formats [value] without trailing zeros, with at most two decimals.
String formatCalculatorNumber(double value) {
  final fixed = value.toStringAsFixed(
    value.truncateToDouble() == value ? 0 : 2,
  );
  if (!fixed.contains('.')) {
    return fixed;
  }
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Parses a positive decimal that may use a comma, or returns `null`.
double? parsePositiveCalculatorDouble(String rawValue) {
  final normalizedValue = rawValue.trim().replaceAll(',', '.');
  if (normalizedValue.isEmpty) {
    return null;
  }
  final parsedValue = double.tryParse(normalizedValue);
  if (parsedValue == null || parsedValue <= 0) {
    return null;
  }
  return parsedValue;
}

/// Parses a positive whole number, or returns `null`.
int? parsePositiveCalculatorInt(String rawValue) {
  final normalizedValue = rawValue.trim();
  if (normalizedValue.isEmpty) {
    return null;
  }
  final parsedValue = int.tryParse(normalizedValue);
  if (parsedValue == null || parsedValue <= 0) {
    return null;
  }
  return parsedValue;
}

/// Validates a required positive decimal.
CalorieCalculatorFieldError? validatePositiveCalculatorDouble(String rawValue) {
  if (rawValue.trim().isEmpty) {
    return CalorieCalculatorFieldError.empty;
  }
  return parsePositiveCalculatorDouble(rawValue) == null
      ? CalorieCalculatorFieldError.invalid
      : null;
}

/// Validates a body weight in kilograms (1 to 700).
CalorieCalculatorFieldError? validateCalculatorWeight(String rawValue) {
  if (rawValue.trim().isEmpty) {
    return CalorieCalculatorFieldError.empty;
  }
  final val = parsePositiveCalculatorDouble(rawValue);
  if (val == null || val < 1 || val > 700) {
    return CalorieCalculatorFieldError.invalid;
  }
  return null;
}

/// Validates a height in centimeters (50 to 272).
CalorieCalculatorFieldError? validateCalculatorHeight(String rawValue) {
  if (rawValue.trim().isEmpty) {
    return CalorieCalculatorFieldError.empty;
  }
  final val = parsePositiveCalculatorDouble(rawValue);
  if (val == null || val < 50 || val > 272) {
    return CalorieCalculatorFieldError.invalid;
  }
  return null;
}

/// Validates an age in years (16 to 100).
CalorieCalculatorFieldError? validateCalculatorAge(String rawValue) {
  if (rawValue.trim().isEmpty) {
    return CalorieCalculatorFieldError.empty;
  }
  final val = parsePositiveCalculatorInt(rawValue);
  if (val == null || val < 16 || val > 100) {
    return CalorieCalculatorFieldError.invalid;
  }
  return null;
}
