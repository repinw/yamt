import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/utils/date_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en');
  });

  test('formats German weekday labels', () {
    final day = DateTime(2026, 4, 27, 18, 30);

    expect(calendarWeekdayLabel(day, 'de'), 'Mo');
  });

  test('formats English weekday labels', () {
    final day = DateTime(2026, 4, 27, 18, 30);

    expect(calendarWeekdayLabel(day, 'en'), 'Mon');
  });

  test('normalizes days and resolves week starts', () {
    expect(dateOnly(DateTime(2026, 4, 29, 23, 59)), DateTime(2026, 4, 29));
    expect(startOfCalendarWeek(DateTime(2026, 5, 3)), DateTime(2026, 4, 27));
  });

  test('the week starts at midnight on Monday across a clock change', () {
    for (
      var day = DateTime(2026);
      day.year == 2026;
      day = addLocalDays(day, 1)
    ) {
      final monday = startOfCalendarWeek(day);
      expect(monday.weekday, DateTime.monday, reason: '$day');
      expect(monday, dateOnly(monday), reason: '$day');
      expect(localDaysBetween(monday, day), day.weekday - 1, reason: '$day');
    }
  });

  test('compares dates at diary-day precision', () {
    expect(
      isSameCalendarDay(DateTime(2026, 4, 27, 1), DateTime(2026, 4, 27, 23)),
      isTrue,
    );
    expect(
      isSameCalendarDay(DateTime(2026, 4, 27), DateTime(2026, 4, 28)),
      isFalse,
    );
  });

  test('loggedAtOnDay keeps the day and takes the time of day from now', () {
    expect(
      loggedAtOnDay(
        DateTime(2026, 4, 30),
        now: DateTime(2026, 5, 2, 18, 45, 30),
      ),
      DateTime(2026, 4, 30, 18, 45),
    );
  });
}
