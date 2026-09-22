import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';

void main() {
  test('earliest day is the plan start and latest is two weeks ahead', () {
    final bounds = DiaryCalendarBounds.resolve(
      today: DateTime(2026, 4, 27, 10),
      planStartDay: DateTime(2026, 4, 20, 8),
    );

    expect(bounds.earliestDay, DateTime(2026, 4, 20));
    expect(bounds.latestDay, DateTime(2026, 5, 11));
    expect(bounds.contains(DateTime(2026, 4, 19)), isFalse);
    expect(bounds.contains(DateTime(2026, 5, 11, 23)), isTrue);
    expect(bounds.clamp(DateTime(2026, 6)), DateTime(2026, 5, 11));
  });

  test('without a plan or with a future plan the earliest day is today', () {
    for (final planStart in [null, DateTime(2026, 5, 4)]) {
      final bounds = DiaryCalendarBounds.resolve(
        today: DateTime(2026, 4, 27),
        planStartDay: planStart,
      );

      expect(bounds.earliestDay, DateTime(2026, 4, 27));
      expect(bounds.canGoBack(DateTime(2026, 4, 27)), isFalse);
      expect(bounds.canGoForward(DateTime(2026, 5, 11)), isFalse);
    }
  });

  test('maps days to page indexes from the earliest day', () {
    final bounds = DiaryCalendarBounds.resolve(
      today: DateTime(2026, 4, 27),
      planStartDay: DateTime(2026, 4, 20),
    );

    expect(bounds.dayCount, 22);
    expect(bounds.indexOf(DateTime(2026, 4, 20, 18)), 0);
    expect(bounds.indexOf(DateTime(2026, 5, 11)), 21);
    expect(bounds.dayAt(0), DateTime(2026, 4, 20));
    expect(bounds.dayAt(7), DateTime(2026, 4, 27));
  });

  test('counts days across a daylight saving time change', () {
    // Clocks move forward on 29 March 2026 in Europe.
    final bounds = DiaryCalendarBounds(
      earliestDay: DateTime(2026, 3, 28),
      latestDay: DateTime(2026, 3, 31),
    );

    expect(bounds.indexOf(DateTime(2026, 3, 30)), 2);
    expect(bounds.dayAt(2), DateTime(2026, 3, 30));
    expect(bounds.dayCount, 4);
  });
}
