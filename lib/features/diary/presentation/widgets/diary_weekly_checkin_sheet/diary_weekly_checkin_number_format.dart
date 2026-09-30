import 'package:intl/intl.dart';

/// Number formats of the weekly check-in sheet for one locale.
class DiaryWeeklyCheckInNumberFormat {
  /// Creates the formats for [locale].
  new(String locale)
    : _whole = NumberFormat.decimalPattern(locale),
      _tenths = NumberFormat.decimalPatternDigits(
        locale: locale,
        decimalDigits: 1,
      ),
      _day = DateFormat.MMMd(locale);

  final NumberFormat _whole;
  final NumberFormat _tenths;
  final DateFormat _day;

  /// kcal without decimals, with a thousands separator.
  String kcal(double value) => _whole.format(value.round());

  /// Weight with one decimal.
  String kg(double value) => _tenths.format(value);

  /// A change with a sign, with one decimal.
  String signedKg(double value) => _signed(value, _tenths.format(value.abs()));

  /// A kcal change with a sign.
  String signedKcal(double value) =>
      _signed(value, _whole.format(value.round().abs()));

  /// A short date like "29. Sep".
  String day(DateTime value) => _day.format(value);

  /// A date range like "22. Sep – 28. Sep".
  String range(DateTime start, DateTime end) => '${day(start)} – ${day(end)}';

  String _signed(double value, String magnitude) {
    if (value.abs() < 0.05) {
      return magnitude;
    }
    return value > 0 ? '+$magnitude' : '−$magnitude';
  }
}
