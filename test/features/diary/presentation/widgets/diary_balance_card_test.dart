import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_balance_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../calories/support/fake_calories_repositories.dart';

void main() {
  testWidgets('renders progress bar at resolved Burn Week ratios', (
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
    final safeZoneRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.safeZone),
    );
    final targetRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.targetMarker),
    );
    final consumedRect = tester.getRect(
      find.byKey(DiaryBalanceCardKeys.consumedMarker),
    );

    expect(find.text('EATEN'), findsOneWidget);
    expect(find.text('LEFT'), findsOneWidget);
    expect(targetRect.center.dxRatioWithin(trackRect), closeTo(1 / 7, 0.035));
    expect(
      consumedRect.center.dxRatioWithin(trackRect),
      closeTo(1 / 14, 0.035),
    );
    expect(safeZoneRect.width / trackRect.width, closeTo(2 / 7, 0.04));
  });

  testWidgets('opens below-zone dialog for under-target live metrics', (
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

    expect(find.text('Too far below target'), findsOneWidget);
  });

  testWidgets('opens above-zone dialog for over-target live metrics', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final weekStartDate = today.subtract(const Duration(days: 6));

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: weekStartDate,
      dayTotals: const [5000, 5000, 5000, 5000, 5000, 5000, 5000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(weekStartDate),
      ),
    );

    expect(find.text('Use heart?'), findsOneWidget);
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
    expect(find.text('LEFT'), findsNothing);
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

    expect(find.text('Week 1 day 1'), findsOneWidget);
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
    expect(find.text('LEFT'), findsOneWidget);
    expect(find.text('-500 kcal'), findsOneWidget);
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

    expect(find.text('Week 1 day 7'), findsOneWidget);
    expect(find.byIcon(Icons.stars_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('opens and cancels use-heart dialog from live counter', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: today,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(today),
      ),
      hasAutoOpeningWeeklyCheckIn: true,
    );

    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Use heart?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Use heart?'), findsNothing);
  });

  testWidgets('applies add and remove heart dialog actions', (tester) async {
    final today = normalizeDiaryDay(DateTime.now());
    var positiveHeartUseCount = 0;
    var negativeHeartUseCount = 0;

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: today,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(today),
      ),
      hasAutoOpeningWeeklyCheckIn: true,
      onUsePositiveHeart: (_) {
        positiveHeartUseCount += 1;
      },
      onUseNegativeHeart: (_) {
        negativeHeartUseCount += 1;
      },
    );

    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+1 day kcal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('-1 day kcal'));
    await tester.pumpAndSettle();

    expect(positiveHeartUseCount, 1);
    expect(negativeHeartUseCount, 1);
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
      ),
      hasAutoOpeningWeeklyCheckIn: true,
    );
    final liveHeight = tester.getSize(find.byType(DiaryBalanceCard)).height;
    expect(find.byIcon(Icons.stars_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

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
  bool hasAutoOpeningWeeklyCheckIn = false,
  bool settle = true,
  double goalKcal = 2000,
  double todayFlexibleGoalKcal = 2000,
  bool goalStartsInFuture = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
  ThemeMode themeMode = ThemeMode.light,
  ValueChanged<double>? onUsePositiveHeart,
  ValueChanged<double>? onUseNegativeHeart,
}) async {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final weekOverview = _weekOverview(
    selectedDay: normalizedSelectedDay,
    weekStartDate: weekStartDate,
    dayTotals: dayTotals,
    goalKcal: goalKcal,
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
        if (tickerPeriod != null)
          diaryBalanceTickerPeriodProvider.overrideWithValue(tickerPeriod),
        if (onBalanceTickerTick != null)
          diaryBalanceTickerObserverProvider.overrideWithValue(
            onBalanceTickerTick,
          ),
        calorieWeekOverviewForWindowProvider(
          normalizedSelectedDay,
        ).overrideWith((ref) => weekOverview),
        calorieWeekDayOverviewForDateProvider(
          normalizedSelectedDay,
        ).overrideWith((ref) => selectedDayOverview),
        burnWeekRunControllerProvider.overrideWith(
          () => _FakeBurnWeekRunController(
            runState,
            onUsePositiveHeart: onUsePositiveHeart,
            onUseNegativeHeart: onUseNegativeHeart,
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
              hasAutoOpeningWeeklyCheckIn: hasAutoOpeningWeeklyCheckIn,
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

CalorieWeekOverview _weekOverview({
  required DateTime selectedDay,
  required DateTime weekStartDate,
  required List<double> dayTotals,
  double goalKcal = 2000,
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
    this.onUseNegativeHeart,
  });

  final BurnWeekRunState initialState;
  final ValueChanged<double>? onUsePositiveHeart;
  final ValueChanged<double>? onUseNegativeHeart;

  @override
  Future<BurnWeekRunState> build() async => initialState;

  @override
  Future<void> usePositiveHeart(double dailyGoalKcal) async {
    onUsePositiveHeart?.call(dailyGoalKcal);
  }

  @override
  Future<void> useNegativeHeart(double dailyGoalKcal) async {
    onUseNegativeHeart?.call(dailyGoalKcal);
  }
}

extension on Offset {
  double dxRatioWithin(Rect rect) {
    return (dx - rect.left) / rect.width;
  }
}
