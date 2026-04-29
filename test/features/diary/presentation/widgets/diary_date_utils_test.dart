import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_date_utils.dart';

void main() {
  test('formats German diary date labels', () {
    final day = DateTime(2026, 4, 27, 18, 30);

    expect(diaryWeekdayLabel(day), 'Mo');
    expect(diaryWeekdayFullLabel(day), 'Montag');
    expect(formatDiaryHeaderDate(day), 'Mo, 27. April');
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
