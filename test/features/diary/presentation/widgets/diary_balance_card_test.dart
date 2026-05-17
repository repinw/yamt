import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_loading.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_progress.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_daily_goal_progress_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../calories/support/fake_calories_repositories.dart';

void main() {
  testWidgets('loading skeleton reserves daily and weekly balance cards', (
    tester,
  ) async {
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

    expect(find.byType(DiaryBalanceShell), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders weekly pacing without removed safe-zone or flame', (
    tester,
  ) async {
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: '2026-4-27',
      ),
    );

    final trackRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.progressTrack),
    );
    final targetRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.targetMarker),
    );

    expect(find.text('EATEN'), findsOneWidget);
    expect(find.text('LEFT TODAY'), findsOneWidget);
    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('Day 1 of 7'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('diary-balance-safe-zone')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('diary-balance-consumed-marker')),
      findsNothing,
    );
    expect(targetRect.center.dxRatioWithin(trackRect), closeTo(1 / 7, 0.035));
    expect(_findTextContaining('1,000 kcal'), findsWidgets);
    expect(_findTextContaining('14,000 kcal'), findsOneWidget);
  });

  testWidgets('weekly progress handles unbounded horizontal constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DiaryBalanceProgressBar(
              actualConsumedKcal: 3100,
              targetKcal: 4915,
              weeklyGoalKcal: 17204,
              totalDays: 7,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(DiaryBalanceCardKeys.progressTrack)).width,
      diaryBalanceProgressFallbackWidth,
    );
  });

  testWidgets('weekly progress animates fill and target marker', (
    tester,
  ) async {
    await _pumpWeeklyProgressBar(
      tester,
      actualConsumedKcal: 0,
      targetKcal: 0,
    );

    await _pumpWeeklyProgressBar(
      tester,
      actualConsumedKcal: 500,
      targetKcal: 700,
    );
    await tester.pump(const Duration(milliseconds: 500));

    final midTrackRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.progressTrack),
    );
    final midFillRect = tester.getRect(_weeklyProgressFillFinder());
    final midTargetRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.targetMarker),
    );

    expect(midFillRect.width, greaterThan(0));
    expect(midFillRect.width, lessThan(midTrackRect.width * 0.5));
    expect(midTargetRect.center.dxRatioWithin(midTrackRect), greaterThan(0));
    expect(
      midTargetRect.center.dxRatioWithin(midTrackRect),
      lessThan(0.7),
    );

    await tester.pumpAndSettle();

    final settledTrackRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.progressTrack),
    );
    final settledFillRect = tester.getRect(_weeklyProgressFillFinder());
    final settledTargetRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.targetMarker),
    );

    expect(
      settledFillRect.width / settledTrackRect.width,
      closeTo(0.5, 0.02),
    );
    expect(
      settledTargetRect.center.dxRatioWithin(settledTrackRect),
      closeTo(0.7, 0.02),
    );
  });

  testWidgets('daily progress shows activity as an end extension', (
    tester,
  ) async {
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: '2026-4-27',
      ),
      activityBonusKcal: 200,
    );

    final trackRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.dailyProgressTrack),
    );
    final eatenRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.dailyProgressEatenFill),
    );
    final activityRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.dailyProgressActivityFill),
    );
    final targetLabelRect = tester.getRect(find.text('2,200 kcal'));

    expect(eatenRect.width / trackRect.width, closeTo(1000 / 2200, 0.02));
    expect(activityRect.width / trackRect.width, closeTo(200 / 2200, 0.02));
    expect(activityRect.right, closeTo(trackRect.right, 0.5));
    expect(targetLabelRect.right, closeTo(trackRect.right, 0.5));
    expect(find.text('+200 kcal'), findsOneWidget);
    expect(find.text('2,200 kcal'), findsOneWidget);
  });

  testWidgets('daily progress animates eaten and activity segments', (
    tester,
  ) async {
    await _pumpDailyProgressBar(
      tester,
      eatenKcal: 0,
      targetKcal: 1200,
      activitySegmentKcal: 0,
    );

    await _pumpDailyProgressBar(
      tester,
      eatenKcal: 600,
      targetKcal: 1200,
      activitySegmentKcal: 300,
    );
    await tester.pump(const Duration(milliseconds: 500));

    final midTrackRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.dailyProgressTrack),
    );
    final midEatenRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.dailyProgressEatenFill),
    );
    final midActivityRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.dailyProgressActivityFill),
    );

    expect(midEatenRect.width, greaterThan(0));
    expect(midEatenRect.width, lessThan(midTrackRect.width * 0.5));
    expect(midActivityRect.width, greaterThan(0));
    expect(midActivityRect.width, lessThan(midTrackRect.width * 0.25));

    await tester.pumpAndSettle();

    final settledTrackRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.dailyProgressTrack),
    );
    final settledEatenRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.dailyProgressEatenFill),
    );
    final settledActivityRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.dailyProgressActivityFill),
    );

    expect(
      settledEatenRect.width / settledTrackRect.width,
      closeTo(0.5, 0.02),
    );
    expect(
      settledActivityRect.width / settledTrackRect.width,
      closeTo(0.25, 0.02),
    );
  });

  testWidgets(
    'heart credit adjusts daily balance while weekly actual stays real',
    (
      tester,
    ) async {
      final selectedDay = normalizeDiaryDay(DateTime.now());

      await _pumpBalanceCard(
        tester,
        selectedDay: selectedDay,
        weekStartDate: selectedDay,
        dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
        runState: const BurnWeekRunState.initial().copyWith(
          currentWeekStartDayKey: diaryDayKey(selectedDay),
          heartCreditKcal: 2000,
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('diary-balance-consumed-marker')),
        findsNothing,
      );
      expect(find.text('3,000 kcal', findRichText: true), findsOneWidget);
      expect(find.text('-1,000 kcal', findRichText: true), findsOneWidget);
      expect(find.text('1,000 kcal', findRichText: true), findsOneWidget);
      expect(
        find.text(
          'Real 1,000 kcal · Heart -2,000 kcal',
          findRichText: true,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('live onboarding buffer appears in eaten tile', (tester) async {
    final today = normalizeDiaryDay(DateTime.now());

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: today,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(today),
        heartCreditKcal: 2000,
      ),
    );

    expect(_findTextContaining('3,000 kcal'), findsOneWidget);
    expect(
      find.text('Real 1,000 kcal · Buffer +2,000 kcal'),
      findsOneWidget,
    );
    expect(find.text('Buffer +2,000 kcal'), findsOneWidget);
    expect(_findTextContaining('-1,000 kcal'), findsOneWidget);
  });

  testWidgets('under-target live metrics do not open automatic heart dialogs', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final weekStartDate = today.subtract(const Duration(days: 6));
    var positiveHeartUseCount = 0;
    DateTime? restartedFrom;
    var continuedRun = false;

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: weekStartDate,
      dayTotals: const [0, 0, 0, 0, 0, 0, 0],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(weekStartDate),
        runWeekNumber: 2,
      ),
      onUsePositiveHeart: (_) {
        positiveHeartUseCount += 1;
      },
      onRestartRunFrom: (weekStartDate) {
        restartedFrom = normalizeDiaryDay(weekStartDate);
      },
      onContinueRunAfterLimitWarning: () {
        continuedRun = true;
      },
    );

    expect(find.text('Too far below target'), findsNothing);
    expect(find.text('Run cannot finish perfectly'), findsNothing);
    expect(find.text('Use heart'), findsNothing);
    expect(positiveHeartUseCount, 0);
    expect(restartedFrom, isNull);
    expect(continuedRun, isFalse);
  });

  testWidgets(
    'over-target live metrics do not open automatic warning dialogs',
    (
      tester,
    ) async {
      final today = normalizeDiaryDay(DateTime.now());
      final weekStartDate = today.subtract(const Duration(days: 6));
      var positiveHeartUseCount = 0;

      await _pumpBalanceCard(
        tester,
        selectedDay: today,
        weekStartDate: weekStartDate,
        dayTotals: const [20000, 20000, 20000, 20000, 20000, 20000, 20000],
        runState: const BurnWeekRunState.initial().copyWith(
          currentWeekStartDayKey: diaryDayKey(weekStartDate),
          runWeekNumber: 2,
        ),
        onUsePositiveHeart: (_) {
          positiveHeartUseCount += 1;
        },
      );

      expect(find.text('Use heart day?'), findsNothing);
      expect(find.text('Out of safe zone'), findsNothing);
      expect(find.text('Run cannot finish perfectly'), findsNothing);
      expect(positiveHeartUseCount, 0);
    },
  );

  testWidgets('heart day shows special balance and suppresses zone dialog', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    DateTime? revertedDay;

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: today,
      dayTotals: const [0, 0, 0, 0, 0, 0, 20000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(today),
        runWeekNumber: 2,
        heartDayKeys: <String>[diaryDayKey(today)],
      ),
      onUnmarkHeartDay: (day) {
        revertedDay = day;
      },
    );

    expect(find.text('Heart day'), findsOneWidget);
    expect(find.text('Ignored for learning'), findsOneWidget);
    expect(find.text('Revert heart day'), findsOneWidget);
    expect(find.text('Use heart day?'), findsNothing);

    await tester.tap(find.text('Revert heart day'));
    await tester.pumpAndSettle();

    expect(revertedDay, today);
  });

  testWidgets('passed-week heart day hides revert action', (tester) async {
    final today = normalizeDiaryDay(DateTime.now());
    final passedWeekDay = today.subtract(const Duration(days: 7));
    DateTime? revertedDay;

    await _pumpBalanceCard(
      tester,
      selectedDay: passedWeekDay,
      weekStartDate: passedWeekDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 20000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(today),
        runWeekNumber: 3,
        heartDayKeys: <String>[diaryDayKey(passedWeekDay)],
      ),
      onUnmarkHeartDay: (day) {
        revertedDay = day;
      },
    );

    expect(find.text('Heart day'), findsOneWidget);
    expect(find.text('Revert heart day'), findsNothing);
    expect(revertedDay, isNull);
  });

  testWidgets('recoverable over-target state keeps card quiet', (
    tester,
  ) async {
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

  testWidgets('shows practice day card before a future goal start', (
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
    expect(find.text('Practice day'), findsOneWidget);
    expect(find.textContaining('Burn Week starts on'), findsOneWidget);
    expect(find.text('Goal: 1,200 kcal'), findsOneWidget);
    expect(find.text('LEFT TODAY'), findsNothing);
  });

  testWidgets('shows practice day card for past day before goal start', (
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
    expect(find.text('Practice day'), findsOneWidget);
    expect(find.textContaining('Burn Week starts on'), findsOneWidget);
    expect(find.text('LEFT TODAY'), findsNothing);
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

  testWidgets('shows Burn Week label on non-live days without counters', (
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

    expect(find.text('Day 1 of 7'), findsOneWidget);
    expect(find.byIcon(Icons.stars_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('renders dark over-goal state', (tester) async {
    final selectedDay = normalizeDiaryDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 2500],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(selectedDay),
      ),
      themeMode: ThemeMode.dark,
    );

    expect(find.text('EATEN'), findsOneWidget);
    expect(find.text('LEFT TODAY'), findsOneWidget);
    expect(_findTextContaining('-500 kcal'), findsOneWidget);
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

    expect(find.text('Day 7 of 7'), findsOneWidget);
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
    final selectedDay = normalizeDiaryDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 0],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(selectedDay),
      ),
      todayFlexibleGoalKcal: -838,
    );

    expect(_findTextContaining('-838 kcal'), findsOneWidget);
  });

  testWidgets('pauses and resumes ticker with app lifecycle', (tester) async {
    final selectedDay = normalizeDiaryDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    var tickerTickCount = 0;

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(selectedDay),
      ),
      tickerPeriod: const Duration(milliseconds: 30),
      settle: false,
      onBalanceTickerTick: () {
        tickerTickCount += 1;
      },
    );
    await tester.pump();
    final initialTickCount = tickerTickCount;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 120));
    expect(tickerTickCount, initialTickCount);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 40));
    expect(tickerTickCount, greaterThan(initialTickCount));
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
}

Future<void> _pumpBalanceCard(
  WidgetTester tester, {
  required DateTime selectedDay,
  required DateTime weekStartDate,
  required List<double> dayTotals,
  required BurnWeekRunState runState,
  VoidCallback? onBurnWeekLiveSyncWatch,
  VoidCallback? onBalanceTickerTick,
  Duration? tickerPeriod,
  bool settle = true,
  double goalKcal = 2000,
  double? baseGoalKcal,
  double activityBonusKcal = 0,
  double todayFlexibleGoalKcal = 2000,
  bool goalStartsInFuture = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
  ThemeMode themeMode = ThemeMode.light,
  ValueChanged<double>? onUsePositiveHeart,
  ValueChanged<DateTime>? onUnmarkHeartDay,
  ValueChanged<DateTime>? onRestartRunFrom,
  VoidCallback? onContinueRunAfterLimitWarning,
  bool weekOverviewThrows = false,
}) async {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final weekOverview = _weekOverview(
    selectedDay: normalizedSelectedDay,
    weekStartDate: weekStartDate,
    dayTotals: dayTotals,
    goalKcal: goalKcal,
    baseGoalKcal: baseGoalKcal,
    activityBonusKcal: activityBonusKcal,
    todayFlexibleGoalKcal: todayFlexibleGoalKcal,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: futureGoalKcal,
  );
  final selectedDayOverview = weekOverview.days.last;
  final repository = FakeCalorieLogRepository();
  addTearDown(repository.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
        burnWeekLiveSyncProvider.overrideWith((ref) {
          onBurnWeekLiveSyncWatch?.call();
          return null;
        }),
        diaryNutritionBarsDataProvider(
          normalizedSelectedDay,
        ).overrideWith(
          (ref) async => const DiaryNutritionBarsData(
            carbs: 36,
            protein: 89,
            fat: 81,
            goals: DiaryMacroTargets(
              carbs: 285,
              protein: 159,
              fat: 85,
            ),
          ),
        ),
        if (tickerPeriod != null)
          diaryBalanceTickerDurationProvider.overrideWithValue(tickerPeriod),
        if (onBalanceTickerTick != null)
          diaryBalanceTickerObserverProvider.overrideWithValue(
            onBalanceTickerTick,
          ),
        calorieWeekOverviewForWindowProvider(
          normalizedSelectedDay,
        ).overrideWith((ref) {
          if (weekOverviewThrows) {
            throw StateError('week overview failed');
          }
          return weekOverview;
        }),
        calorieWeekDayOverviewForDateProvider(
          normalizedSelectedDay,
        ).overrideWith((ref) => selectedDayOverview),
        burnWeekRunControllerProvider.overrideWith(
          () => _FakeBurnWeekRunController(
            runState,
            onUsePositiveHeart: onUsePositiveHeart,
            onUnmarkHeartDay: onUnmarkHeartDay,
            onRestartRunFrom: onRestartRunFrom,
            onContinueRunAfterLimitWarning: onContinueRunAfterLimitWarning,
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DiaryBalanceCard(
              selectedDay: normalizedSelectedDay,
            ),
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

Future<void> _pumpWeeklyProgressBar(
  WidgetTester tester, {
  required double actualConsumedKcal,
  required double targetKcal,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: DiaryBalanceProgressBar(
              actualConsumedKcal: actualConsumedKcal,
              targetKcal: targetKcal,
              weeklyGoalKcal: 1000,
              totalDays: 7,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpDailyProgressBar(
  WidgetTester tester, {
  required double eatenKcal,
  required double targetKcal,
  required double activitySegmentKcal,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: DiaryDailyGoalProgressBar(
              eatenKcal: eatenKcal,
              targetKcal: targetKcal,
              activitySegmentKcal: activitySegmentKcal,
              numberFormat: NumberFormat.decimalPattern('en'),
              unit: 'kcal',
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _weeklyProgressFillFinder() {
  return find
      .descendant(
        of: find.byKey(DiaryBalanceCardKeys.progressTrack),
        matching: find.byType(DecoratedBox),
      )
      .first;
}

CalorieWeekOverview _weekOverview({
  required DateTime selectedDay,
  required DateTime weekStartDate,
  required List<double> dayTotals,
  double goalKcal = 2000,
  double? baseGoalKcal,
  double activityBonusKcal = 0,
  double todayFlexibleGoalKcal = 2000,
  bool goalStartsInFuture = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
}) {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: normalizedSelectedDay.subtract(Duration(days: offset)),
        totalKcal: dayTotals[6 - offset],
        goalKcal: goalKcal,
        baseGoalKcal: baseGoalKcal,
        activityBonusKcal: offset == 0 ? activityBonusKcal : 0,
        entryCount: dayTotals[6 - offset] > 0 ? 1 : 0,
      ),
  ];
  final totalConsumedKcal = days.fold<double>(
    0,
    (sum, day) => sum + day.totalKcal,
  );
  final totalGoalKcal = days.fold<double>(
    0,
    (sum, day) => sum + day.goalKcal,
  );
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
  );
}

class _FakeBurnWeekRunController extends BurnWeekRunController {
  _FakeBurnWeekRunController(
    this.initialState, {
    this.onUsePositiveHeart,
    this.onUnmarkHeartDay,
    this.onRestartRunFrom,
    this.onContinueRunAfterLimitWarning,
  });

  final BurnWeekRunState initialState;
  final ValueChanged<double>? onUsePositiveHeart;
  final ValueChanged<DateTime>? onUnmarkHeartDay;
  final ValueChanged<DateTime>? onRestartRunFrom;
  final VoidCallback? onContinueRunAfterLimitWarning;

  @override
  Future<BurnWeekRunState> build() async => initialState;

  @override
  Future<void> usePositiveHeart(double dailyGoalKcal) async {
    onUsePositiveHeart?.call(dailyGoalKcal);
  }

  @override
  Future<void> unmarkHeartDay(DateTime day) async {
    onUnmarkHeartDay?.call(day);
  }

  @override
  Future<void> restartRunFrom({
    required DateTime weekStartDate,
    int? runWeekNumber,
  }) async {
    onRestartRunFrom?.call(weekStartDate);
  }

  @override
  Future<void> continueRunAfterLimitWarning() async {
    onContinueRunAfterLimitWarning?.call();
  }
}

extension on Offset {
  double dxRatioWithin(Rect rect) {
    return (dx - rect.left) / rect.width;
  }
}

Finder _findTextContaining(String text) {
  return find.textContaining(text, findRichText: true);
}
