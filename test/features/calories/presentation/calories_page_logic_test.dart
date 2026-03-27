import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/calories_page.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

CalorieWeekOverview _overview({
  required int dayOffset,
  required double totalConsumedKcal,
  required double totalGoalKcal,
  required double remainingKcal,
}) {
  return CalorieWeekOverview(
    days: List<CalorieWeekDayOverview>.unmodifiable([
      CalorieWeekDayOverview(
        date: DateTime(2026, 3, 27).subtract(Duration(days: dayOffset)),
        totalKcal: totalConsumedKcal,
        goalKcal: totalGoalKcal,
        entryCount: 1,
      ),
    ]),
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    remainingKcal: remainingKcal,
  );
}

void main() {
  test('resolveDisplayedWeekOverview keeps previous value during refresh', () {
    final previous = _overview(
      dayOffset: 0,
      totalConsumedKcal: 1600,
      totalGoalKcal: 2200,
      remainingKcal: 600,
    );
    // ignore: invalid_use_of_internal_member
    final loading = const AsyncLoading<CalorieWeekOverview>().copyWithPrevious(
      AsyncData<CalorieWeekOverview>(previous),
    );

    final resolved = resolveDisplayedWeekOverview(loading, goalKcal: 2200);

    expect(resolved, same(previous));
  });

  test('resolveDisplayedWeekOverview falls back without previous value', () {
    final resolved = resolveDisplayedWeekOverview(
      const AsyncLoading<CalorieWeekOverview>(),
      goalKcal: 2200,
    );

    expect(resolved.days, hasLength(7));
    expect(resolved.totalConsumedKcal, 0);
    expect(resolved.totalGoalKcal, 15400);
    expect(resolved.remainingKcal, 15400);
  });
}
