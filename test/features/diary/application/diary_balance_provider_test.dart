import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';

void main() {
  test(
    'resolve returns scheduled restart for live day with future run start',
    () async {
      final selectedDay = DateTime(2026, 4, 27);
      final restartDate = addDiaryDays(selectedDay, 1);

      final data = await _resolveBalanceData(
        selectedDay: selectedDay,
        now: selectedDay.add(const Duration(hours: 12)),
        runState: const BurnWeekRunState.initial().copyWith(
          currentWeekStartDayKey: diaryDayKey(restartDate),
        ),
        weekOverview: _weekOverview(selectedDay: selectedDay),
      );

      expect(data.scheduledRestartDate, restartDate);
      expect(data.practiceDay, isNull);
      expect(data.loadedMetrics, isNull);
    },
  );

  test('resolve returns practice day before future goal start', () async {
    final selectedDay = DateTime(2026, 4, 27);
    final startDate = addDiaryDays(selectedDay, 2);

    final data = await _resolveBalanceData(
      selectedDay: selectedDay,
      now: selectedDay.add(const Duration(hours: 12)),
      runState: const BurnWeekRunState.initial(),
      weekOverview: _weekOverview(
        selectedDay: selectedDay,
        goalStartsInFuture: true,
        nextGoalStartDate: startDate,
        futureGoalKcal: 2150,
      ),
    );

    expect(data.scheduledRestartDate, isNull);
    expect(data.practiceDay?.startDate, startDate);
    expect(data.practiceDay?.futureGoalKcal, 2150);
    expect(data.loadedMetrics, isNull);
  });

  test(
    'resolve returns loaded metrics when no pre-start state applies',
    () async {
      final selectedDay = DateTime(2026, 4, 27);
      final data = await _resolveBalanceData(
        selectedDay: selectedDay,
        now: selectedDay.add(const Duration(hours: 12)),
        runState: const BurnWeekRunState.initial().copyWith(
          currentWeekStartDayKey: diaryDayKey(selectedDay),
          runWeekNumber: 2,
        ),
        weekOverview: _weekOverview(
          selectedDay: selectedDay,
          dayTotals: const <double>[0, 0, 0, 0, 0, 0, 800],
        ),
        entries: <CalorieEntry>[
          _entry(
            id: 'breakfast',
            day: selectedDay,
            mealType: MealType.breakfast,
            totalKcal: 800,
          ),
        ],
      );

      expect(data.scheduledRestartDate, isNull);
      expect(data.practiceDay, isNull);
      expect(data.loadedMetrics?.selectedDay, selectedDay);
      expect(data.loadedMetrics?.daily.realEatenKcal, 800);
      expect(data.loadedMetrics?.weekly.progressDay, 1);
      expect(data.loadedMetrics?.state.runWeekNumber, 2);
    },
  );

  test(
    'source waits for run state instead of falling back to initial',
    () async {
      final selectedDay = DateTime(2026, 4, 27);
      final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
      final runStateCompleter = Completer<BurnWeekRunState>();
      final container = ProviderContainer(
        overrides: [
          burnWeekLiveSyncProvider.overrideWith((ref) => null),
          calorieWeekOverviewForWindowProvider(
            normalizedSelectedDay,
          ).overrideWith((ref) => _weekOverview(selectedDay: selectedDay)),
          diaryEntriesForDayProvider(
            normalizedSelectedDay,
          ).overrideWith((ref) async => const <CalorieEntry>[]),
          burnWeekRunControllerProvider.overrideWith(
            () => _DelayedBurnWeekRunController(runStateCompleter),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sourceFuture = container.read(
        diaryBalanceSourceProvider(normalizedSelectedDay).future,
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(diaryBalanceSourceProvider(normalizedSelectedDay)),
        isA<AsyncLoading<DiaryBalanceSource>>(),
      );

      runStateCompleter.complete(
        const BurnWeekRunState.initial().copyWith(
          currentWeekStartDayKey: diaryDayKey(selectedDay),
          runWeekNumber: 7,
        ),
      );
      final source = await sourceFuture;
      final data = source.resolve(
        now: selectedDay.add(const Duration(hours: 8)),
      );

      expect(data.loadedMetrics?.state.runWeekNumber, 7);
    },
  );
}

Future<DiaryBalanceCardData> _resolveBalanceData({
  required DateTime selectedDay,
  required DateTime now,
  required BurnWeekRunState runState,
  required CalorieWeekOverview weekOverview,
  List<CalorieEntry> entries = const <CalorieEntry>[],
}) async {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final container = ProviderContainer(
    overrides: [
      burnWeekLiveSyncProvider.overrideWith((ref) => null),
      calorieWeekOverviewForWindowProvider(
        normalizedSelectedDay,
      ).overrideWith((ref) => weekOverview),
      diaryEntriesForDayProvider(
        normalizedSelectedDay,
      ).overrideWith((ref) async => entries),
      burnWeekRunControllerProvider.overrideWith(
        () => _FakeBurnWeekRunController(runState),
      ),
    ],
  );
  addTearDown(container.dispose);

  await container.read(burnWeekRunControllerProvider.future);
  final source = await container.read(
    diaryBalanceSourceProvider(normalizedSelectedDay).future,
  );
  return source.resolve(now: now);
}

CalorieWeekOverview _weekOverview({
  required DateTime selectedDay,
  List<double> dayTotals = const <double>[0, 0, 0, 0, 0, 0, 0],
  double goalKcal = 2000,
  bool goalStartsInFuture = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
}) {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: addDiaryDays(normalizedSelectedDay, -offset),
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
    balanceStartDate: addDiaryDays(normalizedSelectedDay, -6),
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: goalKcal,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: futureGoalKcal,
  );
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required MealType mealType,
  required double totalKcal,
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    id: id,
    userId: 'user-1',
    name: id,
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: totalKcal,
    per100Protein: 0,
    per100Carbs: 0,
    per100Fat: 0,
    totalKcal: totalKcal,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

class _FakeBurnWeekRunController extends BurnWeekRunController {
  _FakeBurnWeekRunController(this.initialState);

  final BurnWeekRunState initialState;

  @override
  Future<BurnWeekRunState> build() async => initialState;
}

class _DelayedBurnWeekRunController extends BurnWeekRunController {
  _DelayedBurnWeekRunController(this.completer);

  final Completer<BurnWeekRunState> completer;

  @override
  Future<BurnWeekRunState> build() => completer.future;
}
