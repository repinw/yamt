import 'package:intl/intl.dart';

/// Formats prepared meal portion values without noisy trailing zeroes.
String formatPreparedMealPortions(num portions, {String? localeName}) {
  return NumberFormat.decimalPattern(localeName).format(portions);
}
