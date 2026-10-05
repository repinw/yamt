import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_plan_day.dart';

void main() {
  final today = DateTime(2026, 10, 5, 23, 30);
  final tomorrow = DateTime(2026, 10, 6, 0, 10);

  test('a future day counts its plans until the day before is closed', () {
    expect(
      diaryDayCountsPlans(
        day: tomorrow,
        today: today,
        isPreviousDayClosed: false,
      ),
      isTrue,
    );
    expect(
      diaryDayCountsPlans(
        day: tomorrow,
        today: today,
        isPreviousDayClosed: true,
      ),
      isFalse,
    );
    expect(
      diaryDayCountsPlans(day: today, today: today, isPreviousDayClosed: false),
      isFalse,
    );
  });
}
