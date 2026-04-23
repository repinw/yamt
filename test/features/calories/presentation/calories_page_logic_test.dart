import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/calories_page_logic.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_week_overview_provider.dart';

void main() {
  test(
    'resolveDisplayedWeekOverview keeps previous value during refresh',
    () async {
      final previous = CalorieWeekOverview(
        days: List<CalorieWeekDayOverview>.unmodifiable([
          CalorieWeekDayOverview(
            date: DateTime(2026, 3, 27),
            totalKcal: 1600,
            goalKcal: 2200,
            entryCount: 1,
          ),
        ]),
        totalConsumedKcal: 1600,
        totalGoalKcal: 2200,
        remainingKcal: 600,
        balanceStartDate: DateTime(2026, 3, 27),
        carryoverBeforeTodayKcal: 600,
        todayFlexibleGoalKcal: 2200,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      );
      var currentFuture = Future<CalorieWeekOverview>.value(previous);
      final provider = FutureProvider<CalorieWeekOverview>((ref) {
        return currentFuture;
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(provider.future);

      currentFuture = Future<CalorieWeekOverview>.delayed(
        const Duration(milliseconds: 1),
        () => previous,
      );
      container.refresh(provider);
      final loading = subscription.read();

      final visibleWindowEnd = DateTime(2026, 3, 27);

      expect(
        resolveDisplayedWeekOverview(
          loading,
          goalKcal: 2200,
          visibleWindowEnd: visibleWindowEnd,
        ),
        same(previous),
      );
    },
  );

  test('resolveDisplayedWeekOverview falls back without previous value', () {
    final visibleWindowEnd = DateTime(2026, 3, 27);
    final resolved = resolveDisplayedWeekOverview(
      const AsyncLoading<CalorieWeekOverview>(),
      goalKcal: 2200,
      visibleWindowEnd: visibleWindowEnd,
    );

    expect(resolved.days, hasLength(7));
    expect(resolved.totalConsumedKcal, 0);
    expect(resolved.totalGoalKcal, 15400);
    expect(resolved.remainingKcal, 15400);
  });

  test(
    'visible-window settle keeps the selected day when it stays visible',
    () {
      final selectedDay = DateTime(2026, 3, 5);

      final resolved = resolveSelectedDiaryDayForVisibleWindowChange(
        previousWindowEnd: DateTime(2026, 3, 8),
        nextWindowEnd: DateTime(2026, 3, 7),
        selectedDay: selectedDay,
      );

      expect(resolved, selectedDay);
    },
  );

  test(
    'visible-window settle picks the right edge when swiping to older days',
    () {
      final resolved = resolveSelectedDiaryDayForVisibleWindowChange(
        previousWindowEnd: DateTime(2026, 3, 8),
        nextWindowEnd: DateTime(2026, 3, 7),
        selectedDay: DateTime(2026, 3, 8),
      );

      expect(resolved, DateTime(2026, 3, 7));
    },
  );

  test(
    'visible-window settle picks the left edge when swiping to newer days',
    () {
      final resolved = resolveSelectedDiaryDayForVisibleWindowChange(
        previousWindowEnd: DateTime(2026, 3, 7),
        nextWindowEnd: DateTime(2026, 3, 8),
        selectedDay: DateTime(2026, 3),
      );

      expect(resolved, DateTime(2026, 3, 2));
    },
  );

  testWidgets(
    'handleVisibleWindowSettled keeps selected day when still visible',
    (tester) async {
      WidgetRef? widgetRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                widgetRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final ref = widgetRef!;
      ref
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(DateTime(2026, 3, 8));
      ref
          .read(calorieDayControllerProvider.notifier)
          .setDay(DateTime(2026, 3, 5));

      handleVisibleWindowSettled(ref, DateTime(2026, 3, 7));

      expect(
        ref.read(calorieVisibleWindowControllerProvider),
        DateTime(2026, 3, 7),
      );
      expect(ref.read(calorieDayControllerProvider), DateTime(2026, 3, 5));
    },
  );

  testWidgets(
    'handleVisibleWindowSettled moves selected day to new edge when needed',
    (tester) async {
      WidgetRef? widgetRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                widgetRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final ref = widgetRef!;
      ref
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(DateTime(2026, 3, 8));
      ref
          .read(calorieDayControllerProvider.notifier)
          .setDay(DateTime(2026, 3, 8));

      handleVisibleWindowSettled(ref, DateTime(2026, 3, 7));

      expect(
        ref.read(calorieVisibleWindowControllerProvider),
        DateTime(2026, 3, 7),
      );
      expect(ref.read(calorieDayControllerProvider), DateTime(2026, 3, 7));
    },
  );
}
