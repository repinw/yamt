import 'package:intl/intl.dart';

/// Formats a rounded diary kcal value with its localized unit.
String formatDiaryKcal(NumberFormat numberFormat, double value, String unit) {
  return '${numberFormat.format(value.round())} $unit';
}

/// Formats a rounded signed kcal value with its localized unit.
String formatDiarySignedKcal(
  double value,
  NumberFormat numberFormat,
  String unit,
) {
  final roundedValue = value.round();
  final sign = roundedValue > 0 ? '+' : '';
  return '$sign${numberFormat.format(roundedValue)} $unit';
}
