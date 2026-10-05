import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

void main() {
  test('addDiaryDays moves by whole calendar days', () {
    expect(addDiaryDays(DateTime(2026, 10, 25), 1), DateTime(2026, 10, 26));
    expect(addDiaryDays(DateTime(2026, 10, 25), -1), DateTime(2026, 10, 24));
    expect(addDiaryDays(DateTime(2026, 10, 25), 1).hour, 0);
  });

  test('addDiaryDays stays on calendar midnights across DST boundaries', () {
    expect(addDiaryDays(DateTime(2026, 3, 29), 1), DateTime(2026, 3, 30));
    expect(addDiaryDays(DateTime(2026, 10, 25), 1), DateTime(2026, 10, 26));
  });

  test('buildDiaryVisibleDays stays aligned to local calendar days', () {
    final days = buildDiaryVisibleDays(anchorDay: DateTime(2026, 10, 26));

    expect(days.length, diaryVisibleDayCount);
    expect(days.first, DateTime(2026, 10, 20));
    expect(days.last, DateTime(2026, 10, 26));
    for (final day in days) {
      expect(day.hour, 0);
      expect(day.minute, 0);
      expect(day.second, 0);
    }
  });

  test('only days after today are future days', () {
    final today = DateTime(2026, 10, 5, 23, 30);

    expect(
      isDiaryFutureDay(day: DateTime(2026, 10, 6, 0, 10), today: today),
      isTrue,
    );
    expect(isDiaryFutureDay(day: DateTime(2026, 10, 5), today: today), isFalse);
    expect(isDiaryFutureDay(day: DateTime(2026, 10, 4), today: today), isFalse);
  });
}
