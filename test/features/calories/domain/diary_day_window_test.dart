import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';

void main() {
  test('addLocalDays moves by whole calendar days', () {
    expect(addLocalDays(DateTime(2026, 10, 25), 1), DateTime(2026, 10, 26));
    expect(addLocalDays(DateTime(2026, 10, 25), -1), DateTime(2026, 10, 24));
    expect(addLocalDays(DateTime(2026, 10, 25), 1).hour, 0);
  });

  test('addLocalDays stays on calendar midnights across DST boundaries', () {
    expect(addLocalDays(DateTime(2026, 3, 29), 1), DateTime(2026, 3, 30));
    expect(addLocalDays(DateTime(2026, 10, 25), 1), DateTime(2026, 10, 26));
  });

  test('buildRollingLocalDays stays aligned to local calendar days', () {
    final days = buildRollingLocalDays(anchorDay: DateTime(2026, 10, 26));

    expect(days.length, localVisibleDayCount);
    expect(days.first, DateTime(2026, 10, 20));
    expect(days.last, DateTime(2026, 10, 26));
    for (final day in days) {
      expect(day.hour, 0);
      expect(day.minute, 0);
      expect(day.second, 0);
    }
  });
}
