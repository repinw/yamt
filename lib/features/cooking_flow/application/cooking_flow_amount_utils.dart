import 'package:yamt/core/utils/flexible_decimal_parser.dart';

/// Parses decimals, simple fractions, and mixed fractions.
double? parseCookingFlowQuantity(String rawValue) {
  final normalized = rawValue.trim();
  final mixedFractionMatch = RegExp(
    r'^(\d+)\s+(\d+)/(\d+)$',
  ).firstMatch(normalized);
  if (mixedFractionMatch != null) {
    final whole = _parseCookingFlowNumber(mixedFractionMatch.group(1)!);
    final numerator = _parseCookingFlowNumber(mixedFractionMatch.group(2)!);
    final denominator = _parseCookingFlowNumber(mixedFractionMatch.group(3)!);
    if (whole == null ||
        numerator == null ||
        denominator == null ||
        denominator == 0) {
      return null;
    }
    return whole + numerator / denominator;
  }
  if (normalized.contains('/')) {
    final parts = normalized.split('/');
    if (parts.length != 2) {
      return null;
    }
    final numerator = _parseCookingFlowNumber(parts[0]);
    final denominator = _parseCookingFlowNumber(parts[1]);
    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }
    return numerator / denominator;
  }
  return _parseCookingFlowNumber(normalized);
}

double? _parseCookingFlowNumber(String value) {
  return parseFlexibleDecimal(value);
}

/// Formats a decimal amount without trailing zero noise.
String formatCookingFlowDecimal(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
}
