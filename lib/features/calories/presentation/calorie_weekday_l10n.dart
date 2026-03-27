import 'package:yamt/l10n/app_localizations.dart';

/// Returns the short localized weekday label used by the diary strip.
String localizedDiaryWeekdayLabel(AppLocalizations l10n, DateTime day) {
  return switch (day.weekday) {
    DateTime.monday => l10n.caloriesWeekdayShortMonday,
    DateTime.tuesday => l10n.caloriesWeekdayShortTuesday,
    DateTime.wednesday => l10n.caloriesWeekdayShortWednesday,
    DateTime.thursday => l10n.caloriesWeekdayShortThursday,
    DateTime.friday => l10n.caloriesWeekdayShortFriday,
    DateTime.saturday => l10n.caloriesWeekdayShortSaturday,
    DateTime.sunday => l10n.caloriesWeekdayShortSunday,
    _ => l10n.caloriesWeekdayShortMonday, // coverage:ignore-line
  };
}
