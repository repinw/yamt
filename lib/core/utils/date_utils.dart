import 'package:intl/intl.dart';

/// Returns the localized short weekday label for [day].
String calendarWeekdayLabel(DateTime day, String localeName) {
  return DateFormat.E(localeName).format(day).replaceFirst(RegExp(r'\.$'), '');
}

/// Normalizes [day] to date-only precision.
DateTime dateOnly(DateTime day) {
  return DateTime(day.year, day.month, day.day);
}

/// Returns the Monday that starts the calendar week for [day].
DateTime startOfCalendarWeek(DateTime day) {
  final normalized = dateOnly(day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

/// Compares two days at date-only precision.
bool isSameCalendarDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
