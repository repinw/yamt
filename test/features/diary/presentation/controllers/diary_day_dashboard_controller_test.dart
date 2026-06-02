import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/data/diary_day_dashboard_cache_store.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';
import '../../../calories/support/fake_calories_repositories.dart';
import '../../support/diary_dashboard_test_support.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  const userId = 'user-1';
  final selectedDay = DateTime(2026, 5, 24);

  test(
    'reads cached dashboard synchronously then persists fresh data',
    () async {
      final preferences = MemoryAppPreferences();
      const cacheStore = DiaryDayDashboardCacheStore();
      final cachedData = diaryDashboardLoadedStateForTest(
        selectedDay: selectedDay,
      ).data!;
      await cacheStore.save(
        preferences: preferences,
        userId: userId,
        data: cachedData,
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: [_entry(selectedDay, name: 'Fresh oats')],
      );
      addTearDown(logRepository.dispose);

      final container = _dashboardContainer(
        preferences: preferences,
        logRepository: logRepository,
        selectedDay: selectedDay,
        weekOverview: diaryWeekOverviewForTest(
          selectedDay: selectedDay,
          dayTotals: const <double>[0, 0, 0, 0, 0, 0, 240],
          goalKcal: 2400,
        ),
      );
      addTearDown(container.dispose);

      final initial = container.read(
        diaryDayDashboardControllerProvider(selectedDay),
      );
      expect(initial.data, isNotNull);
      expect(initial.isFromCache, isTrue);
      expect(initial.isRefreshing, isTrue);

      final refreshed = await _waitForDashboardRefresh(container, selectedDay);
      final persisted = cacheStore.readSync(
        preferences: preferences,
        userId: userId,
        day: selectedDay,
      );

      expect(refreshed.isFromCache, isFalse);
      expect(refreshed.isRefreshing, isFalse);
      expect(refreshed.data?.selectedDayEntries.single.name, 'Fresh oats');
      expect(persisted?.selectedDayEntries.single.name, 'Fresh oats');
    },
  );

  test('keeps cached dashboard visible when refresh fails', () async {
    final preferences = MemoryAppPreferences();
    const cacheStore = DiaryDayDashboardCacheStore();
    final cachedData = diaryDashboardLoadedStateForTest(
      selectedDay: selectedDay,
    ).data!;
    await cacheStore.save(
      preferences: preferences,
      userId: userId,
      data: cachedData,
    );
    final logRepository = FakeCalorieLogRepository();
    addTearDown(logRepository.dispose);

    final container = _dashboardContainer(
      preferences: preferences,
      logRepository: logRepository,
      selectedDay: selectedDay,
      weekOverviewError: StateError('week failed'),
    );
    addTearDown(container.dispose);

    container.read(diaryDayDashboardControllerProvider(selectedDay));

    final failed = await _waitForDashboardRefresh(container, selectedDay);

    expect(failed.data, isNotNull);
    expect(failed.isFromCache, isTrue);
    expect(failed.isRefreshing, isFalse);
    expect(failed.error, isA<StateError>());
  });

  test(
    'refresh invalidates stale cached week overview before loading',
    () async {
      final preferences = MemoryAppPreferences();
      var weekOverview = _weekOverviewWithActivityBonus(
        selectedDay: selectedDay,
        activityBonusKcal: 0,
      );
      var weekOverviewReadCount = 0;
      final logRepository = FakeCalorieLogRepository();
      addTearDown(logRepository.dispose);

      final container = _dashboardContainer(
        preferences: preferences,
        logRepository: logRepository,
        selectedDay: selectedDay,
        weekOverviewBuilder: () {
          weekOverviewReadCount += 1;
          return weekOverview;
        },
      );
      addTearDown(container.dispose);

      await container.read(
        calorieWeekOverviewForWindowProvider(selectedDay).future,
      );
      weekOverview = _weekOverviewWithActivityBonus(
        selectedDay: selectedDay,
        activityBonusKcal: 674.25,
      );
      container.read(diaryDayDashboardControllerProvider(selectedDay));

      final refreshed = await _waitForDashboardRefresh(container, selectedDay);

      expect(weekOverviewReadCount, greaterThanOrEqualTo(2));
      expect(
        refreshed.data?.weekOverview.days.last.activityBonusKcal,
        674.25,
      );
    },
  );

  test(
    'queues one follow-up refresh when retry overlaps live refresh',
    () async {
      final preferences = MemoryAppPreferences();
      final logRepository = FakeCalorieLogRepository();
      final weekOverviewCompleter = Completer<CalorieWeekOverview>();
      final observer = _RecordingProviderObserver();
      var weekOverviewReadCount = 0;
      addTearDown(logRepository.dispose);

      final container = _dashboardContainer(
        preferences: preferences,
        logRepository: logRepository,
        selectedDay: selectedDay,
        observers: [observer],
        weekOverviewBuilder: () {
          weekOverviewReadCount += 1;
          return weekOverviewCompleter.future;
        },
      );
      addTearDown(container.dispose);

      final provider = diaryDayDashboardControllerProvider(selectedDay);
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      final retryFuture = container.read(provider.notifier).retry();
      await Future<void>.delayed(Duration.zero);

      expect(weekOverviewReadCount, 1);

      weekOverviewCompleter.complete(
        diaryWeekOverviewForTest(selectedDay: selectedDay),
      );
      await retryFuture;
      final refreshed = await _waitForDashboardRefresh(container, selectedDay);

      expect(refreshed.isRefreshing, isFalse);
      expect(refreshed.error, isNull);
      expect(observer.failures, isEmpty);
      expect(weekOverviewReadCount, 2);
    },
  );

  test('mutation refresh performs settled follow-up refresh', () async {
    final preferences = MemoryAppPreferences();
    final logRepository = FakeCalorieLogRepository();
    var entryReadCount = 0;
    logRepository.onReadEntriesForDay = (day) async {
      entryReadCount += 1;
      if (entryReadCount < 3) {
        return const <CalorieEntry>[];
      }
      return [_entry(selectedDay, name: 'Settled oats')];
    };
    addTearDown(logRepository.dispose);

    final container = _dashboardContainer(
      preferences: preferences,
      logRepository: logRepository,
      selectedDay: selectedDay,
    );
    addTearDown(container.dispose);

    final provider = diaryDayDashboardControllerProvider(selectedDay);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final initial = await _waitForDashboardRefresh(container, selectedDay);
    expect(initial.data?.selectedDayEntries, isEmpty);

    container.read(provider.notifier).refreshAfterMutation();
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final refreshed = container.read(provider);
    expect(entryReadCount, greaterThanOrEqualTo(3));
    expect(refreshed.data?.selectedDayEntries.single.name, 'Settled oats');
  });

  test('mutation refresh bypasses blocked initial refresh', () async {
    final preferences = MemoryAppPreferences();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: [_entry(selectedDay, name: 'Mutation oats')],
    );
    final initialWeekOverviewCompleter = Completer<CalorieWeekOverview>();
    var weekOverviewReadCount = 0;
    addTearDown(logRepository.dispose);

    final container = _dashboardContainer(
      preferences: preferences,
      logRepository: logRepository,
      selectedDay: selectedDay,
      weekOverviewBuilder: () {
        weekOverviewReadCount += 1;
        if (weekOverviewReadCount == 1) {
          return initialWeekOverviewCompleter.future;
        }
        return diaryWeekOverviewForTest(
          selectedDay: selectedDay,
          dayTotals: const <double>[0, 0, 0, 0, 0, 0, 240],
        );
      },
    );
    addTearDown(container.dispose);

    final provider = diaryDayDashboardControllerProvider(selectedDay);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(provider).isRefreshing, isTrue);
    expect(weekOverviewReadCount, 1);

    container.read(provider.notifier).refreshAfterMutation();
    final refreshed = await _waitForDashboardRefresh(container, selectedDay);

    expect(weekOverviewReadCount, 2);
    expect(refreshed.data?.selectedDayEntries.single.name, 'Mutation oats');

    initialWeekOverviewCompleter.complete(
      diaryWeekOverviewForTest(selectedDay: selectedDay),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(provider).data?.selectedDayEntries.single.name,
      'Mutation oats',
    );
  });
}

ProviderContainer _dashboardContainer({
  required AppPreferences preferences,
  required FakeCalorieLogRepository logRepository,
  required DateTime selectedDay,
  CalorieWeekOverview? weekOverview,
  FutureOr<CalorieWeekOverview> Function()? weekOverviewBuilder,
  Error? weekOverviewError,
  List<ProviderObserver> observers = const <ProviderObserver>[],
}) {
  final auth = _MockFirebaseAuth();
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  when(() => auth.currentUser).thenReturn(user);

  return ProviderContainer(
    observers: observers,
    overrides: [
      appPreferencesProvider.overrideWithValue(preferences),
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
      firebaseAuthProvider.overrideWithValue(auth),
      burnWeekLiveSyncProvider.overrideWith((ref) => null),
      burnWeekRunControllerProvider.overrideWith(
        () => _FakeBurnWeekRunController(const BurnWeekRunState.initial()),
      ),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieWeekOverviewForWindowProvider(selectedDay).overrideWith((ref) {
        final error = weekOverviewError;
        if (error != null) {
          throw error;
        }
        final builder = weekOverviewBuilder;
        if (builder != null) {
          return builder();
        }
        return weekOverview ??
            diaryWeekOverviewForTest(selectedDay: selectedDay);
      }),
    ],
  );
}

final class _RecordingProviderObserver extends ProviderObserver {
  final failures = <Object>[];

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    failures.add(error);
  }
}

CalorieWeekOverview _weekOverviewWithActivityBonus({
  required DateTime selectedDay,
  required double activityBonusKcal,
}) {
  final normalizedDay = normalizeDiaryDay(selectedDay);
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: normalizedDay.subtract(Duration(days: offset)),
        totalKcal: 0,
        goalKcal: offset == 0 ? 2000 + activityBonusKcal : 2000,
        baseGoalKcal: 2000,
        activityBonusKcal: offset == 0 ? activityBonusKcal : 0,
        entryCount: 0,
      ),
  ];
  return CalorieWeekOverview(
    days: days,
    totalConsumedKcal: 0,
    totalGoalKcal: days.fold<double>(0, (sum, day) => sum + day.goalKcal),
    remainingKcal: days.fold<double>(0, (sum, day) => sum + day.goalKcal),
    balanceStartDate: normalizedDay.subtract(const Duration(days: 6)),
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: 2000 + activityBonusKcal,
    goalStartsInFuture: false,
    nextGoalStartDate: null,
    futureGoalKcal: null,
  );
}

Future<DiaryDayDashboardState> _waitForDashboardRefresh(
  ProviderContainer container,
  DateTime selectedDay,
) async {
  final provider = diaryDayDashboardControllerProvider(selectedDay);
  final current = container.read(provider);
  if (!current.isRefreshing) {
    return current;
  }

  final completer = Completer<DiaryDayDashboardState>();
  final subscription = container.listen(provider, (previous, next) {
    if (!next.isRefreshing && !completer.isCompleted) {
      completer.complete(next);
    }
  });
  try {
    return await completer.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => container.read(provider),
    );
  } finally {
    subscription.close();
  }
}

CalorieEntry _entry(DateTime selectedDay, {required String name}) {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: name,
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 240,
    per100Protein: 12,
    per100Carbs: 36,
    per100Fat: 8,
    loggedAt: selectedDay.add(const Duration(hours: 8)),
    createdAt: selectedDay.add(const Duration(hours: 8)),
    updatedAt: selectedDay.add(const Duration(hours: 8)),
  );
}

class _FakeBurnWeekRunController extends BurnWeekRunController {
  _FakeBurnWeekRunController(this.initialState);

  final BurnWeekRunState initialState;

  @override
  Future<BurnWeekRunState> build() async => initialState;
}
