import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_pager.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_pager_support.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

Widget _buildHarness({
  required DateTime visibleWindowEnd,
  required DateTime selectedDay,
  required double goalKcal,
  required List<CalorieWeekDayOverview> visibleDaysOverview,
  required DateTime referenceNow,
  required ValueChanged<DateTime> onSelectDay,
  required ValueChanged<DateTime> onWindowSettled,
}) {
  final logRepository = FakeCalorieLogRepository();
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: goalKcal,
      calculatorProfile: null,
      effectiveDate: visibleDaysOverview.first.date,
    ),
  );

  final container = ProviderContainer(
    overrides: [
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 700,
          child: CaloriesDayNavigationPager(
            selectedDay: selectedDay,
            visibleWindowEnd: visibleWindowEnd,
            goalKcal: goalKcal,
            visibleDaysOverview: visibleDaysOverview,
            referenceNow: referenceNow,
            onSelectDay: onSelectDay,
            onWindowSettled: onWindowSettled,
          ),
        ),
      ),
    ),
  );
}

List<CalorieWeekDayOverview> _days(DateTime end) {
  return buildDiaryVisibleDays(anchorDay: end)
      .map(
        (day) => CalorieWeekDayOverview(
          date: day,
          totalKcal: day.day.isEven ? 1400 : 1800,
          goalKcal: 2200,
          entryCount: day.day.isEven ? 1 : 0,
        ),
      )
      .toList(growable: false);
}

void main() {
  testWidgets('pager avoids reading very old day overviews on initial load', (
    tester,
  ) async {
    final windowEnd = DateTime(2026, 3, 20);
    final days = _days(windowEnd);
    final requestedDays = <DateTime>[];
    final logRepository = FakeCalorieLogRepository()
      ..onReadEntriesForDay = (day) async {
        requestedDays.add(day);
        return const [];
      };
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: days.first.date,
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: CaloriesDayNavigationPager(
                selectedDay: days.last.date,
                visibleWindowEnd: windowEnd,
                goalKcal: 2200,
                visibleDaysOverview: days,
                referenceNow: windowEnd,
                onSelectDay: (_) {},
                onWindowSettled: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final earliestExpectedDay = days.first.date.subtract(
      const Duration(days: caloriesDayNavigationPrefetchDayCount),
    );
    expect(requestedDays, isNotEmpty);
    expect(
      requestedDays.every((day) => !day.isBefore(earliestExpectedDay)),
      isTrue,
    );
  });

  testWidgets('pager selects tapped visible day', (tester) async {
    final windowEnd = DateTime(2026, 3, 20);
    final days = _days(windowEnd);
    DateTime? selectedDay;

    await tester.pumpWidget(
      _buildHarness(
        visibleWindowEnd: windowEnd,
        selectedDay: days.last.date,
        goalKcal: 2200,
        visibleDaysOverview: days,
        referenceNow: windowEnd,
        onSelectDay: (value) {
          selectedDay = value;
        },
        onWindowSettled: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();

    expect(selectedDay, DateTime(2026, 3, 18));
  });

  testWidgets('pager reports settled window after drag', (tester) async {
    final windowEnd = DateTime(2026, 3, 19);
    final days = _days(windowEnd);
    DateTime? settledWindowEnd;

    await tester.pumpWidget(
      _buildHarness(
        visibleWindowEnd: windowEnd,
        selectedDay: days.last.date,
        goalKcal: 2200,
        visibleDaysOverview: days,
        referenceNow: windowEnd,
        onSelectDay: (_) {},
        onWindowSettled: (value) {
          settledWindowEnd = value;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(-250, 0));
    await tester.pumpAndSettle();

    expect(settledWindowEnd, windowEnd);
  });

  testWidgets('pager restores tap after non-scrolling pointer move', (
    tester,
  ) async {
    final windowEnd = DateTime(2026, 3, 20);
    final days = _days(windowEnd);
    DateTime? selectedDay;

    await tester.pumpWidget(
      _buildHarness(
        visibleWindowEnd: windowEnd,
        selectedDay: days.last.date,
        goalKcal: 2200,
        visibleDaysOverview: days,
        referenceNow: windowEnd,
        onSelectDay: (value) {
          selectedDay = value;
        },
        onWindowSettled: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.renderObject<RenderBox>(
      find.byType(CaloriesDayNavigationPager),
    );
    final startPoint = renderBox.localToGlobal(
      Offset(12, renderBox.size.height - 12),
    );

    final gesture = await tester.startGesture(startPoint);
    await gesture.moveBy(const Offset(0, 60));
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();

    expect(selectedDay, DateTime(2026, 3, 19));
  });

  testWidgets('pager snaps partial drag back to day boundary', (tester) async {
    final windowEnd = DateTime(2026, 3, 20);
    final days = _days(windowEnd);
    DateTime? settledWindowEnd;

    await tester.pumpWidget(
      _buildHarness(
        visibleWindowEnd: windowEnd,
        selectedDay: days.last.date,
        goalKcal: 2200,
        visibleDaysOverview: days,
        referenceNow: windowEnd,
        onSelectDay: (_) {},
        onWindowSettled: (value) {
          settledWindowEnd = value;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(-40, 0));
    await tester.pumpAndSettle();

    expect(settledWindowEnd, isNotNull);
  });

  testWidgets('pager restores tap handling after pointer cancel', (
    tester,
  ) async {
    final windowEnd = DateTime(2026, 3, 20);
    final days = _days(windowEnd);
    DateTime? selectedDay;

    await tester.pumpWidget(
      _buildHarness(
        visibleWindowEnd: windowEnd,
        selectedDay: days.last.date,
        goalKcal: 2200,
        visibleDaysOverview: days,
        referenceNow: windowEnd,
        onSelectDay: (value) {
          selectedDay = value;
        },
        onWindowSettled: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('20')),
    );
    await gesture.moveBy(const Offset(20, 0));
    await gesture.cancel();
    await tester.pumpAndSettle();

    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();

    expect(selectedDay, DateTime(2026, 3, 19));
  });
}
