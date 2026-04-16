import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_pager_support.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

import '../../support/fake_calories_repositories.dart';

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  required double totalKcal,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Item $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: totalKcal,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

void main() {
  testWidgets('prefetch helper merges cached and provider day overviews', (
    tester,
  ) async {
    final today = DateTime(2026, 3, 20);
    final prefetchedDay = DateTime(2026, 3, 10);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'visible',
          loggedAt: today.add(const Duration(hours: 9)),
          totalKcal: 1800,
        ),
        _entry(
          'prefetch',
          loggedAt: prefetchedDay.add(const Duration(hours: 8)),
          totalKcal: 550,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: prefetchedDay,
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    var result =
        <String, CalorieWeekDayOverview>{};

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              result = buildPrefetchedCaloriesDayOverviews(
                ref: ref,
                earliestDay: DateTime(2026, 3),
                referenceToday: today,
                visibleWindowEnd: today,
                visibleDaysOverview: <CalorieWeekDayOverview>[
                  CalorieWeekDayOverview(
                    date: DateTime(2026, 3, 20),
                    totalKcal: 1800,
                    goalKcal: 2200,
                    entryCount: 1,
                  ),
                ],
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(result[diaryDayKey(today)]?.totalKcal, 1800);
    expect(result[diaryDayKey(prefetchedDay)]?.totalKcal, 550);
  });

  test('scroll physics clamps and dampens fling velocity', () {
    const physics = CaloriesDayNavigationScrollPhysics();
    final applied = physics.applyTo(const AlwaysScrollableScrollPhysics());
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 2000,
      pixels: 500,
      viewportDimension: 300,
      axisDirection: AxisDirection.right,
      devicePixelRatio: 1,
    );

    expect(applied, isA<CaloriesDayNavigationScrollPhysics>());
    expect(physics.maxFlingVelocity, caloriesDayNavigationMaxFlingVelocity);
    expect(physics.carriedMomentum(1200), 0);
    expect(physics.createBallisticSimulation(metrics, 5000), isNotNull);
  });

  test('restore press helper reports true only when idle', () {
    final controller = ScrollController();
    final shouldRestore = shouldRestoreCaloriesDayNavigationPress(
      isSnapping: false,
      isPressEnabled: false,
      scrollController: controller,
    );

    expect(shouldRestore, isTrue);
  });

  testWidgets('prefetch helper normalizes buffer end when today is far ahead', (
    tester,
  ) async {
    var result =
        <String, CalorieWeekDayOverview>{};

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              result = buildPrefetchedCaloriesDayOverviews(
                ref: ref,
                earliestDay: DateTime(2026, 3),
                referenceToday: DateTime(2026, 4, 20),
                visibleWindowEnd: DateTime(2026, 3, 20),
                visibleDaysOverview: <CalorieWeekDayOverview>[
                  CalorieWeekDayOverview(
                    date: DateTime(2026, 3, 20),
                    totalKcal: 1500,
                    goalKcal: 2200,
                    entryCount: 1,
                  ),
                ],
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(result[diaryDayKey(DateTime(2026, 3, 20))]?.totalKcal, 1500);
  });

  testWidgets('animate helper moves attached scroll controller when needed', (
    tester,
  ) async {
    final controller = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 300,
            height: 80,
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemExtent: 100,
              itemCount: 10,
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final animation = animateCaloriesDayNavigationToTargetIfNeeded(
      scrollController: controller,
      targetOffset: 100,
      duration: const Duration(milliseconds: 1),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2));
    await animation;

    expect(controller.offset, 100);
  });
}
