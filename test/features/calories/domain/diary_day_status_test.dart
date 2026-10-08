import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';

void main() {
  final today = DateTime(2026, 10, 8, 14, 30);

  DiaryDayStatus statusOf(DateTime day, {bool isPreviousDayClosed = false}) =>
      DiaryDayStatus.of(
        day: day,
        today: today,
        isPreviousDayClosed: isPreviousDayClosed,
      );

  test('a day before today is past', () {
    final status = statusOf(DateTime(2026, 10, 7, 23, 59));

    expect(status, DiaryDayStatus.past);
    expect(status.isPast, isTrue);
    expect(status.isFuture, isFalse);
    expect(status.isPlanned, isFalse);
  });

  test('any time of today is today', () {
    expect(statusOf(DateTime(2026, 10, 8)), DiaryDayStatus.today);
    expect(statusOf(DateTime(2026, 10, 8, 23, 59)), DiaryDayStatus.today);
    expect(statusOf(DateTime(2026, 10, 8)).isFuture, isFalse);
  });

  test('a future day with an open day before is planned', () {
    final status = statusOf(DateTime(2026, 10, 9));

    expect(status, DiaryDayStatus.planned);
    expect(status.isFuture, isTrue);
    expect(status.isPlanned, isTrue);
  });

  test('tomorrow after a closed today counts like a started day', () {
    final status = statusOf(DateTime(2026, 10, 9), isPreviousDayClosed: true);

    expect(status, DiaryDayStatus.afterClosedDay);
    expect(status.isFuture, isTrue);
    expect(status.isPlanned, isFalse);
  });

  test('midnight starts the next day', () {
    final midnight = DateTime(2026, 10, 9);

    expect(
      DiaryDayStatus.of(day: midnight, today: today),
      DiaryDayStatus.planned,
    );
    expect(
      DiaryDayStatus.of(day: midnight, today: midnight),
      DiaryDayStatus.today,
    );
    expect(DiaryDayStatus.of(day: today, today: midnight), DiaryDayStatus.past);
  });
}
