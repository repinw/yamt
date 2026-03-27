import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

void main() {
  test(
    'buildDiaryVisibleDays returns seven normalized days ending at anchor',
    () {
      final anchor = DateTime(2026, 3, 27, 18, 45);

      final days = buildDiaryVisibleDays(anchorDay: anchor);

      expect(days, hasLength(diaryVisibleDayCount));
      expect(days.first, DateTime(2026, 3, 21));
      expect(days.last, DateTime(2026, 3, 27));
    },
  );

  test('previousDiaryVisibleDay clamps to earliest visible day', () {
    final anchor = DateTime(2026, 3, 27, 18, 45);
    final earliest = resolveDiaryWindowStart(anchorDay: anchor);

    final previous = previousDiaryVisibleDay(earliest, anchorDay: anchor);

    expect(previous, earliest);
  });

  test('nextDiaryVisibleDay clamps to latest visible day', () {
    final anchor = DateTime(2026, 3, 27, 18, 45);
    final latest = resolveDiaryWindowEnd(anchorDay: anchor);

    final next = nextDiaryVisibleDay(latest, anchorDay: anchor);

    expect(next, latest);
  });
}
