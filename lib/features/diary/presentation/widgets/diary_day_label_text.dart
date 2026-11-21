import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A leap year, so that it has every date, 29 Feb included.
const int _leapYear = 2024;
const int _daysInLeapYear = 366;
const int _daysInWeek = 7;

/// Most days away that the small line has room for: "vor 99 Tagen".
const int _widestDayCount = 99;

/// Style of the small line over the date, such as "Heute".
TextStyle? diaryDayNameStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    fontSize: AppFontSizes.diaryDayName,
    color: FoodLabelColors.of(context).muted,
  );
}

/// Style of the date line.
TextStyle? diaryDateStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleLarge?.copyWith(
    fontSize: AppFontSizes.diaryDate,
    fontWeight: FontWeight.w600,
    color: FoodLabelColors.of(context).ink,
    height: 1.2,
  );
}

/// The date line of a day in the current locale, such as "Sa, 21. Nov.".
String Function(DateTime day) diaryDateLineOf(BuildContext context) {
  final format = _dateFormats(context);
  return (day) =>
      format.line(format.weekday.format(day), format.date.format(day));
}

({DateFormat weekday, DateFormat date, String Function(String, String) line})
_dateFormats(BuildContext context) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final l10n = AppLocalizations.of(context)!;
  return (
    // Stand-alone form: "Do", not the "Do." of the format form.
    weekday: DateFormat('ccc', locale),
    date: DateFormat.MMMd(locale),
    line: l10n.diaryDateLine,
  );
}

/// The width that the text of the day label needs at its full size: the
/// widest date line or the widest small line. The date line is the widest
/// weekday with the widest date, which is wider than or as wide as every real
/// line of any year. The width does not depend on the selected day, so the
/// label scales the same on every day.
double diaryDayLabelTextWidth(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final painter = TextPainter(
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  );
  double measure(String text, TextStyle? style) {
    painter
      ..text = TextSpan(text: text, style: style)
      ..layout();
    return painter.width;
  }

  final dateStyle = diaryDateStyle(context);
  final format = _dateFormats(context);
  String widestOf(Iterable<DateTime> days, DateFormat formatter) {
    final texts = {for (final day in days) formatter.format(day)};
    return texts.reduce(
      (a, b) => measure(a, dateStyle) >= measure(b, dateStyle) ? a : b,
    );
  }

  final widestWeekday = widestOf([
    for (var i = 0; i < _daysInWeek; i += 1) DateTime(_leapYear, 1, 1 + i),
  ], format.weekday);
  final widestDate = widestOf([
    for (var i = 0; i < _daysInLeapYear; i += 1) DateTime(_leapYear, 1, 1 + i),
  ], format.date);
  var widest = measure(format.line(widestWeekday, widestDate), dateStyle);
  final nameStyle = diaryDayNameStyle(context);
  for (final name in [
    l10n.diaryTodayTitle,
    l10n.diaryYesterdayTitle,
    l10n.diaryTomorrowTitle,
    l10n.diaryDayAfterTomorrowTitle,
    l10n.diaryDaysAgo(_widestDayCount),
    l10n.diaryInDays(_widestDayCount),
  ]) {
    widest = math.max(widest, measure(name, nameStyle));
  }
  painter.dispose();
  return widest;
}
