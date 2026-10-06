import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/burn_week_run_controller.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_loading.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_kcal_ruler.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';
import '../../../calories/support/fake_calories_repositories.dart';
import '../../../calories/support/fake_planned_entry_repository.dart';

void main() {
  testWidgets('loading skeleton reserves daily balance card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: DiaryBalanceLoading(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byType(DiaryBalanceLoading)).height,
      greaterThan(150),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders daily balance without weekly pacing', (tester) async {
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: DateTime(2026, 4, 27, 12),
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: '2026-4-27',
      ),
    );

    expect(find.text('1,000 eaten'), findsOneWidget);
    expect(find.text('LEFT TODAY'), findsOneWidget);
    expect(find.text('Week 1'), findsNothing);
    expect(find.text('Day 1 of 7'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('diary-balance-safe-zone')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('diary-balance-consumed-marker')),
      findsNothing,
    );
    expect(_findTextContaining('1,000'), findsWidgets);
    expect(_findTextContaining('14,000 kcal'), findsNothing);
  });

  testWidgets('daily ruler fills its first quarter, then the next ones', (
    tester,
  ) async {
    await _pumpDailyProgressBar(tester, eatenKcal: 0, targetKcal: 1200);

    await _pumpDailyProgressBar(tester, eatenKcal: 300, targetKcal: 1200);
    await tester.pump(const Duration(milliseconds: 500));

    double firstQuarterFill() {
      final fill = tester.getRect(
        find.byKey(DiaryBalanceCardKeys.dailyProgressEatenFill),
      );
      final quarter = tester.getRect(
        find
            .ancestor(
              of: find.byKey(DiaryBalanceCardKeys.dailyProgressEatenFill),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      return fill.width / quarter.width;
    }

    expect(firstQuarterFill(), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();

    expect(firstQuarterFill(), closeTo(1, 0.01));
    final fills = tester
        .widgetList<FractionallySizedBox>(
          find.descendant(
            of: find.byKey(DiaryBalanceCardKeys.dailyProgressTrack),
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .map((box) => box.widthFactor);
    expect(fills, [1, 0, 0, 0]);
  });

  testWidgets('pause day shows special balance', (tester) async {
    final today = normalizeDiaryDay(DateTime.now());

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: today,
      dayTotals: const [0, 0, 0, 0, 0, 0, 20000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(today),
        runWeekNumber: 2,
      ),
      isPauseDay: true,
    );

    expect(find.text('Pause day'), findsOneWidget);
    expect(find.text('Ignored for learning'), findsOneWidget);
  });

  testWidgets('recoverable over-target state keeps card quiet', (tester) async {
    final today = normalizeDiaryDay(DateTime.now());

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: today,
      dayTotals: const [0, 0, 0, 0, 0, 0, 5000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(today),
        runWeekNumber: 2,
      ),
    );

    expect(find.text('Out of safe zone'), findsNothing);
    expect(find.textContaining('Fasting'), findsNothing);
  });

  testWidgets('learning week hides game controls and zone dialogs', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final weekStartDate = today.subtract(const Duration(days: 6));

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: weekStartDate,
      dayTotals: const [0, 0, 0, 0, 0, 0, 0],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(weekStartDate),
      ),
    );

    expect(find.text('Too far below target'), findsNothing);
    expect(find.byIcon(Icons.stars_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('shows scheduled restart card when next run is pending', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final restartDate = today.add(const Duration(days: 1));

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: today,
      dayTotals: const [0, 0, 0, 0, 0, 0, 0],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(restartDate),
      ),
    );

    expect(find.text('Run over'), findsOneWidget);
    expect(find.textContaining('Fresh run starts on'), findsOneWidget);
  });

  testWidgets('shows a practice badge before a future goal start', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final startDate = nextDiaryDay(today);

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: startDate,
      dayTotals: const [0, 0, 0, 0, 0, 0, 900],
      runState: const BurnWeekRunState.initial(),
      goalKcal: 0,
      todayFlexibleGoalKcal: 0,
      goalStartsInFuture: true,
      nextGoalStartDate: startDate,
      futureGoalKcal: 1200,
    );

    expect(find.byKey(DiaryBalanceCardKeys.practiceDay), findsOneWidget);
    expect(find.textContaining('Practice day · counts from'), findsOneWidget);
    // The real daily card measures the day against the goal that starts later.
    expect(find.text('Base 1,200 kcal'), findsOneWidget);
  });

  testWidgets('shows the practice badge for a past day before goal start', (
    tester,
  ) async {
    final selectedDay = normalizeDiaryDay(
      DateTime.now().subtract(const Duration(days: 7)),
    );
    final startDate = nextDiaryDay(selectedDay);

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: startDate,
      dayTotals: const [0, 0, 0, 0, 0, 0, 900],
      runState: const BurnWeekRunState.initial(),
      goalKcal: 0,
      todayFlexibleGoalKcal: 0,
      goalStartsInFuture: true,
      nextGoalStartDate: startDate,
      futureGoalKcal: 1200,
    );

    expect(find.byKey(DiaryBalanceCardKeys.practiceDay), findsOneWidget);
    expect(find.textContaining('Practice day · counts from'), findsOneWidget);
  });

  testWidgets('keeps Burn Week live sync subscribed on non-live days', (
    tester,
  ) async {
    final selectedDay = normalizeDiaryDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    var syncWatchCount = 0;

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(selectedDay),
      ),
      onBurnWeekLiveSyncWatch: () {
        syncWatchCount += 1;
      },
    );

    expect(syncWatchCount, greaterThan(0));
  });

  testWidgets('hides weekly label on non-live days without counters', (
    tester,
  ) async {
    final selectedDay = normalizeDiaryDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: null,
      ),
    );

    expect(find.text('Day 1 of 7'), findsNothing);
    expect(find.byIcon(Icons.stars_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('renders dark over-goal state', (tester) async {
    final now = DateTime(2026, 4, 28, 12);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 2500],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(selectedDay),
      ),
      themeMode: ThemeMode.dark,
    );

    expect(find.text('2,500 eaten'), findsOneWidget);
    expect(find.text('OVER GOAL'), findsOneWidget);
    expect(find.text('LEFT TODAY'), findsNothing);
    expect(find.text('500'), findsOneWidget);
    expect(_findTextContaining('-500'), findsNothing);
  });

  testWidgets('decides future days from the clock provider', (tester) async {
    // With the real clock this day lies in the past and shows LEFT TODAY.
    final now = DateTime(2026, 4, 26, 12);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 0],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(selectedDay),
      ),
    );

    expect(find.text('PLANNED'), findsOneWidget);
    expect(find.text('LEFT TODAY'), findsNothing);
  });

  testWidgets('quiet future day shows the planned kcal of its goal', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 26, 12);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 0],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(selectedDay),
      ),
      showDetails: false,
    );

    expect(find.text('PLANNED'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('of 2,000'), findsOneWidget);
    expect(_findTextContaining('Base '), findsNothing);
  });

  testWidgets('future pause day shows the pause word instead of the goal', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 26, 12);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 600],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(selectedDay),
      ),
      isPauseDay: true,
      showDetails: false,
    );

    expect(find.text('PLANNED'), findsOneWidget);
    expect(find.text('600'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(DiaryBalanceCardKeys.kcalHeadTarget)).data,
      'Pause day',
    );
  });

  testWidgets('tomorrow closes the day before and offers undo', (tester) async {
    final now = DateTime(2026, 4, 26, 20);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay.subtract(const Duration(days: 3)),
      dayTotals: const [0, 0, 0, 0, 0, 0, 900],
      runState: const BurnWeekRunState.initial(),
      showDetails: false,
      previousDayCarryoverKcal: 218,
    );
    final repository = _closedDayRepository(tester);

    expect(find.text('Close Sunday'), findsOneWidget);
    expect(find.text('+218 kcal per day'), findsOneWidget);
    expect(find.byKey(DiaryBalanceCardKeys.previousDayClosed), findsNothing);

    await tester.tap(find.byKey(DiaryBalanceCardKeys.previousDayCloseButton));
    await tester.pumpAndSettle();

    expect(find.text('Sunday closed'), findsOneWidget);
    expect(repository.readClosedDay(), DateTime(2026, 4, 26));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(repository.readClosedDay(), isNull);
  });

  testWidgets('tomorrow reopens the closed day before', (tester) async {
    final now = DateTime(2026, 4, 26, 20);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay.subtract(const Duration(days: 3)),
      dayTotals: const [0, 0, 0, 0, 0, 0, 900],
      runState: const BurnWeekRunState.initial(),
      showDetails: false,
      todayFlexibleGoalKcal: 2218,
      previousDayCarryoverKcal: 218,
      isPreviousDayClosed: true,
    );
    final repository = _closedDayRepository(tester);
    await repository.saveClosedDay(DateTime(2026, 4, 26));

    expect(find.byKey(DiaryBalanceCardKeys.previousDayClosed), findsOneWidget);
    expect(find.text('Sunday closed'), findsOneWidget);

    await tester.tap(find.byKey(DiaryBalanceCardKeys.previousDayReopenButton));
    await tester.pumpAndSettle();

    expect(repository.readClosedDay(), isNull);
  });

  testWidgets('tomorrow counts like a started day once the day before is '
      'closed', (tester) async {
    final now = DateTime(2026, 4, 26, 20);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay.subtract(const Duration(days: 3)),
      dayTotals: const [0, 0, 0, 0, 0, 0, 900],
      runState: const BurnWeekRunState.initial(),
      todayFlexibleGoalKcal: 2218,
      previousDayCarryoverKcal: 218,
      isPreviousDayClosed: true,
    );

    String textOf(Key key) => tester.widget<Text>(find.byKey(key)).data!;
    expect(textOf(DiaryBalanceCardKeys.kcalHeadLabel), 'LEFT');
    expect(textOf(DiaryBalanceCardKeys.kcalHeadValue), '1,318');
    expect(find.byKey(DiaryBalanceCardKeys.kcalHeadTarget), findsNothing);
    // Its carryover comes from finished days, so the budget sheet explains it.
    expect(
      find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsButton),
      findsOneWidget,
    );
  });

  testWidgets('a closed tomorrow counts its plans until the chip is off', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 26, 20);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay.subtract(const Duration(days: 3)),
      dayTotals: const [0, 0, 0, 0, 0, 0, 900],
      runState: const BurnWeekRunState.initial(),
      todayFlexibleGoalKcal: 2218,
      previousDayCarryoverKcal: 218,
      isPreviousDayClosed: true,
      showDetails: false,
      plans: [
        CalorieEntry.create(
          id: 'plan-breakfast',
          userId: 'user-1',
          name: 'Brötchen',
          mealType: MealType.breakfast,
          consumedAmount: 100,
          consumedUnit: ConsumedUnit.grams,
          per100Kcal: 300,
          per100Protein: 10,
          per100Carbs: 50,
          per100Fat: 5,
          loggedAt: selectedDay.add(const Duration(hours: 8)),
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    String textOf(Key key) => tester.widget<Text>(find.byKey(key)).data!;
    expect(textOf(DiaryBalanceCardKeys.kcalHeadLabel), 'LEFT AFTER PLAN');
    expect(textOf(DiaryBalanceCardKeys.kcalHeadValue), '1,018');
    expect(
      textOf(DiaryBalanceCardKeys.kcalHeadWithoutPlan),
      '1,318 without plan',
    );

    await tester.tap(find.byKey(DiaryBalanceCardKeys.afterPlanChip));
    await tester.pumpAndSettle();

    expect(textOf(DiaryBalanceCardKeys.kcalHeadLabel), 'LEFT');
    expect(textOf(DiaryBalanceCardKeys.kcalHeadValue), '1,318');
    expect(find.byKey(DiaryBalanceCardKeys.kcalHeadWithoutPlan), findsNothing);
    // The chip does not open the details.
    expect(_findTextContaining(' eaten'), findsNothing);
  });

  testWidgets('a day without a previous-day carryover offers no close', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 26, 20);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 900],
      runState: const BurnWeekRunState.initial(),
    );

    expect(
      find.byKey(DiaryBalanceCardKeys.previousDayCloseButton),
      findsNothing,
    );
  });

  testWidgets('quiet card shows only what is left and toggles on tap', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 28, 12);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1200],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(selectedDay),
      ),
      showDetails: false,
    );

    // A past day says what was left without "today".
    expect(find.text('LEFT'), findsOneWidget);
    expect(_findTextContaining(' eaten'), findsNothing);
    expect(
      find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsButton),
      findsNothing,
    );

    await tester.tap(find.byKey(DiaryBalanceCardKeys.kcalHeadLabel));
    await tester.pumpAndSettle();

    expect(find.text('1,200 eaten'), findsOneWidget);
    expect(
      find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsButton),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DiaryBalanceCardKeys.kcalHeadLabel));
    await tester.pumpAndSettle();

    expect(_findTextContaining(' eaten'), findsNothing);
  });

  testWidgets('renders future non-live day snapshot', (tester) async {
    final selectedDay = normalizeDiaryDay(
      DateTime.now().add(const Duration(days: 1)),
    );
    final weekStartDate = selectedDay.subtract(const Duration(days: 6));

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: weekStartDate,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: null,
      ),
    );

    expect(find.text('PLANNED'), findsOneWidget);
    expect(find.text('1,000'), findsOneWidget);
    expect(find.text('of 2,000'), findsOneWidget);
    // No carryover on a future day, so nothing to explain.
    expect(_findTextContaining('Base '), findsNothing);
    expect(
      find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsButton),
      findsNothing,
    );
    expect(_findTextContaining(' eaten'), findsNothing);
    expect(find.text('LEFT TODAY'), findsNothing);
    expect(find.text('Day 7 of 7'), findsNothing);
    expect(find.byIcon(Icons.stars_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('keeps live and non-live balance cards the same height', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final nonLiveDay = today.subtract(const Duration(days: 1));

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: today,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(today),
        runWeekNumber: 2,
      ),
    );
    final liveHeight = tester.getSize(find.byType(DiaryBalanceCard)).height;
    expect(find.byIcon(Icons.stars_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await _pumpBalanceCard(
      tester,
      selectedDay: nonLiveDay,
      weekStartDate: nonLiveDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: null,
      ),
    );
    final nonLiveHeight = tester.getSize(find.byType(DiaryBalanceCard)).height;
    expect(find.byIcon(Icons.stars_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(liveHeight, nonLiveHeight);
  });

  testWidgets('shows full negative carryover instead of clamping left kcal', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 28, 12);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 0],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(selectedDay),
      ),
      todayFlexibleGoalKcal: -838,
    );

    expect(find.text('OVER GOAL'), findsOneWidget);
    expect(find.text('838'), findsOneWidget);
    expect(find.text('-838'), findsNothing);
  });

  testWidgets('shows retry content when week overview fails', (tester) async {
    final selectedDay = normalizeDiaryDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial(),
      weekOverviewThrows: true,
    );

    expect(find.text('Balance could not be loaded'), findsOneWidget);
    expect(find.byKey(DiaryBalanceCardKeys.retryButton), findsOneWidget);

    await tester.tap(find.byKey(DiaryBalanceCardKeys.retryButton));
    await tester.pump();

    expect(find.byKey(DiaryBalanceCardKeys.retryButton), findsOneWidget);
  });

  testWidgets('tapping budget details button opens budget details sheet', (
    tester,
  ) async {
    final selectedDay = normalizeDiaryDay(DateTime.now());

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 800],
      runState: const BurnWeekRunState.initial(),
    );

    expect(
      find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsButton),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsButton));
    await tester.pumpAndSettle();

    expect(
      find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsSheet),
      findsOneWidget,
    );
    expect(find.text('Daily budget details'), findsOneWidget);
  });

  testWidgets('renders daily balance subtitle segments with loop', (
    tester,
  ) async {
    final selectedDay = normalizeDiaryDay(DateTime.now());

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 800],
      runState: const BurnWeekRunState.initial(),
      baseGoalKcal: 2000,
    );

    expect(_findTextContaining('Base 2,000 kcal'), findsOneWidget);
  });
}

Future<void> _pumpBalanceCard(
  WidgetTester tester, {
  required DateTime selectedDay,
  required DateTime weekStartDate,
  required List<double> dayTotals,
  required BurnWeekRunState runState,
  VoidCallback? onBurnWeekLiveSyncWatch,
  VoidCallback? onWeekOverviewRead,
  FutureOr<CalorieWeekOverview> Function()? weekOverviewBuilder,
  List<ProviderObserver> observers = const <ProviderObserver>[],
  bool settle = true,
  double goalKcal = 2000,
  double? baseGoalKcal,
  double todayFlexibleGoalKcal = 2000,
  bool goalStartsInFuture = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
  ThemeMode themeMode = ThemeMode.light,
  bool isPauseDay = false,
  ValueChanged<DateTime>? onRestartRunFrom,
  bool weekOverviewThrows = false,
  bool showDetails = true,
  DateTime? now,
  double? previousDayCarryoverKcal,
  bool isPreviousDayClosed = false,
  List<CalorieEntry> plans = const <CalorieEntry>[],
}) async {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final weekOverview = _weekOverview(
    selectedDay: normalizedSelectedDay,
    weekStartDate: weekStartDate,
    dayTotals: dayTotals,
    goalKcal: goalKcal,
    baseGoalKcal: baseGoalKcal,
    todayFlexibleGoalKcal: todayFlexibleGoalKcal,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: futureGoalKcal,
    isPauseDay: isPauseDay,
    previousDayCarryoverKcal: previousDayCarryoverKcal,
    isPreviousDayClosed: isPreviousDayClosed,
  );
  final selectedDayOverview = weekOverview.days.last;
  final repository = FakeCalorieLogRepository();
  final auth = _MockFirebaseAuth();
  addTearDown(repository.dispose);
  when(() => auth.currentUser).thenReturn(null);

  final preferences = MemoryAppPreferences(
    initialStrings: showDetails
        ? const {'diary_balance_details_v1': 'shown'}
        : null,
  );
  await tester.pumpWidget(
    ProviderScope(
      observers: observers,
      overrides: [
        if (now != null) clockProvider.overrideWithValue(() => now),
        appPreferencesProvider.overrideWithValue(preferences),
        closedDayRepositoryProvider.overrideWithValue(
          ClosedDayRepository(preferences, 'user-1'),
        ),
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(null),
        ),
        firebaseAuthProvider.overrideWithValue(auth),
        calorieLogRepositoryProvider.overrideWithValue(repository),
        plannedEntryRepositoryProvider.overrideWithValue(
          FakePlannedEntryRepository(plans: plans),
        ),
        burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
        burnWeekLiveSyncProvider.overrideWith((ref) {
          onBurnWeekLiveSyncWatch?.call();
          return null;
        }),
        calorieWeekOverviewForWindowProvider(normalizedSelectedDay)
            .overrideWith((ref) {
              onWeekOverviewRead?.call();
              if (weekOverviewThrows) {
                throw StateError('week overview failed');
              }
              final builder = weekOverviewBuilder;
              if (builder != null) {
                return builder();
              }
              return weekOverview;
            }),
        calorieWeekDayOverviewForDateProvider(normalizedSelectedDay)
            .overrideWith((ref) => selectedDayOverview),
        burnWeekRunControllerProvider.overrideWith(
          () => _FakeBurnWeekRunController(
            runState,
            onRestartRunFrom: onRestartRunFrom,
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DiaryBalanceCard(selectedDay: normalizedSelectedDay),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _pumpDailyProgressBar(
  WidgetTester tester, {
  required double eatenKcal,
  required double targetKcal,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: DiaryKcalRuler(eatenKcal: eatenKcal, targetKcal: targetKcal),
          ),
        ),
      ),
    ),
  );
}

CalorieWeekOverview _weekOverview({
  required DateTime selectedDay,
  required DateTime weekStartDate,
  required List<double> dayTotals,
  double goalKcal = 2000,
  double? baseGoalKcal,
  double todayFlexibleGoalKcal = 2000,
  bool goalStartsInFuture = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
  bool isPauseDay = false,
  double? previousDayCarryoverKcal,
  bool isPreviousDayClosed = false,
}) {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: normalizedSelectedDay.subtract(Duration(days: offset)),
        totalKcal: dayTotals[6 - offset],
        goalKcal: goalKcal,
        baseGoalKcal: baseGoalKcal,
        entryCount: dayTotals[6 - offset] > 0 ? 1 : 0,
        isPauseDay: offset == 0 && isPauseDay,
      ),
  ];
  final totalConsumedKcal = days.fold<double>(
    0,
    (sum, day) => sum + day.totalKcal,
  );
  final totalGoalKcal = days.fold<double>(0, (sum, day) => sum + day.goalKcal);
  return CalorieWeekOverview(
    days: days,
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    remainingKcal: totalGoalKcal - totalConsumedKcal,
    balanceStartDate: normalizeDiaryDay(weekStartDate),
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: todayFlexibleGoalKcal,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: futureGoalKcal,
    previousDayCarryoverKcal: previousDayCarryoverKcal,
    isPreviousDayClosed: isPreviousDayClosed,
  );
}

class _FakeBurnWeekRunController extends BurnWeekRunController {
  new(this.initialState, {this.onRestartRunFrom});

  final BurnWeekRunState initialState;
  final ValueChanged<DateTime>? onRestartRunFrom;
  @override
  Future<BurnWeekRunState> build() async => initialState;

  @override
  Future<void> restartRunFrom({
    required DateTime weekStartDate,
    int? runWeekNumber,
  }) async {
    onRestartRunFrom?.call(weekStartDate);
  }
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

Finder _findTextContaining(String text) {
  return find.textContaining(text, findRichText: true);
}

ClosedDayRepository _closedDayRepository(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DiaryBalanceCard)))
        .read(closedDayRepositoryProvider);
