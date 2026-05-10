import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yamt/features/diary/domain/diary_date_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en');
  });

  test('formats German diary date labels', () {
    final day = DateTime(2026, 4, 27, 18, 30);

    expect(diaryWeekdayLabel(day, 'de'), 'Mo');
    expect(diaryWeekdayFullLabel(day, 'de'), 'Montag');
    expect(formatDiaryHeaderDate(day, 'de'), 'Mo, 27. April');
  });

  test('formats English diary date labels', () {
    final day = DateTime(2026, 4, 27, 18, 30);

    expect(diaryWeekdayLabel(day, 'en'), 'Mon');
    expect(diaryWeekdayFullLabel(day, 'en'), 'Monday');
    expect(formatDiaryHeaderDate(day, 'en'), 'Mon, April 27');
  });

  test('normalizes days and resolves week starts', () {
    expect(diaryDayOnly(DateTime(2026, 4, 29, 23, 59)), DateTime(2026, 4, 29));
    expect(
      startOfDiaryCalendarWeek(DateTime(2026, 5, 3)),
      DateTime(2026, 4, 27),
    );
  });

  test('compares dates at diary-day precision', () {
    expect(
      isSameDiaryCalendarDay(
        DateTime(2026, 4, 27, 1),
        DateTime(2026, 4, 27, 23),
      ),
      isTrue,
    );
    expect(
      isSameDiaryCalendarDay(
        DateTime(2026, 4, 27),
        DateTime(2026, 4, 28),
      ),
      isFalse,
    );
  });
}
