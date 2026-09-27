import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Number and date formats of the profile page for the current locale.
class ProfileFormatters {
  /// Creates the formats for the locale of [context].
  factory of(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ProfileFormatters._(locale);
  }

  new _(this._locale)
    : _decimal = NumberFormat.decimalPattern(_locale)
        ..minimumFractionDigits = 1
        ..maximumFractionDigits = 1,
      _whole = NumberFormat.decimalPattern(_locale)..maximumFractionDigits = 0;

  final String _locale;
  final NumberFormat _decimal;
  final NumberFormat _whole;

  /// A weight or other value with one decimal, such as "82,6".
  String decimal(double value) => _decimal.format(value);

  /// A value without decimals, such as "2.150".
  String whole(double value) => _whole.format(value);

  /// A change with its sign, such as "+0,4" or "−0,4".
  String signedDecimal(double value) {
    final text = _decimal.format(value.abs());
    return value < 0 ? '−$text' : '+$text';
  }

  /// A short date, such as "21. Sep.".
  String shortDate(DateTime day) => DateFormat.MMMd(_locale).format(day);

  /// A date with the year, such as "14.03.1994".
  String longDate(DateTime day) => DateFormat.yMd(_locale).format(day);

  /// The short name of an ISO weekday (1 is Monday), such as "Mo.".
  String weekday(int isoWeekday) {
    // 2024-01-01 is a Monday.
    return DateFormat.E(_locale).format(DateTime(2024, 1, isoWeekday));
  }
}
