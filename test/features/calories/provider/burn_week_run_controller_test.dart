import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  _FakeBurnWeekRunStateRepository(this.state);

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    state = nextState;
    return true;
  }
}

class _DelayedBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  _DelayedBurnWeekRunStateRepository(
    this.state, {
    required this.saveDelay,
  });

  BurnWeekRunState state;
  final Duration saveDelay;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    await Future<void>.delayed(saveDelay);
    state = nextState;
    return true;
  }
}

void main() {
  ProviderContainer buildContainer(
    _FakeBurnWeekRunStateRepository repository,
  ) {
    final container = ProviderContainer(
      overrides: [
        burnWeekRunStateRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> syncWeek(
    ProviderContainer container, {
    required DateTime currentDay,
    required DateTime weekStartDate,
    required bool missedTrackingThisWeek,
    List<bool>? missedTrackingForClosedWeeks,
  }) async {
    await container.read(burnWeekRunControllerProvider.future);
    await container
        .read(burnWeekRunControllerProvider.notifier)
        .syncForWeek(
          currentDay: currentDay,
          weekStartDate: weekStartDate,
          missedTrackingThisWeek: missedTrackingThisWeek,
          missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
        );
  }

  BurnWeekRunState buildState({
    required String? currentWeekStartDayKey,
    required int runWeekNumber,
    required int starCount,
    required int heartCount,
    String? lastActiveDayKey,
    double heartCreditKcal = 0,
    bool starBrokeThisWeek = false,
    bool missedTrackingThisWeek = false,
  }) {
    return BurnWeekRunState(
      currentWeekStartDayKey: currentWeekStartDayKey,
      lastActiveDayKey: lastActiveDayKey,
      runWeekNumber: runWeekNumber,
      starCount: starCount,
      heartCount: heartCount,
      heartCreditKcal: heartCreditKcal,
      starBrokeThisWeek: starBrokeThisWeek,
      missedTrackingThisWeek: missedTrackingThisWeek,
    );
  }

  Future<BurnWeekRunState> syncAcrossThreeClosedWeeks({
    required List<bool> missedTrackingForClosedWeeks,
  }) async {
    final repository = _FakeBurnWeekRunStateRepository(
      buildState(
        currentWeekStartDayKey: '2026-4-1',
        runWeekNumber: 1,
        starCount: 0,
        heartCount: 3,
      ),
    );
    final container = buildContainer(repository);

    await syncWeek(
      container,
      currentDay: DateTime(2026, 4, 22),
      weekStartDate: DateTime(2026, 4, 22),
      missedTrackingThisWeek: false,
      missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
    );
    return repository.state;
  }

  Future<BurnWeekRunState> syncClosingWeek({
    required bool missedTrackingForClosedWeek,
  }) async {
    final repository = _FakeBurnWeekRunStateRepository(
      buildState(
        currentWeekStartDayKey: '2026-4-14',
        lastActiveDayKey: '2026-4-13',
        runWeekNumber: 1,
        starCount: 0,
        heartCount: 3,
      ),
    );
    final container = buildContainer(repository);

    await syncWeek(
      container,
      currentDay: DateTime(2026, 4, 21),
      weekStartDate: DateTime(2026, 4, 21),
      missedTrackingThisWeek: false,
      missedTrackingForClosedWeeks: <bool>[missedTrackingForClosedWeek],
    );
    return repository.state;
  }

  test('syncForWeek initializes first week key', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    );
    final container = buildContainer(repository);

    await syncWeek(
      container,
      currentDay: DateTime(2026, 4, 21),
      weekStartDate: DateTime(2026, 4, 21),
      missedTrackingThisWeek: false,
    );

    expect(repository.state.currentWeekStartDayKey, '2026-4-21');
    expect(repository.state.lastActiveDayKey, '2026-4-21');
    expect(repository.state.starCount, 0);
    expect(repository.state.heartCount, 3);
    expect(repository.state.runWeekNumber, 1);
  });

  test(
    'syncForWeek bootstraps closed weeks when initial state is stale',
    () async {
      final repository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      final container = buildContainer(repository);

      await syncWeek(
        container,
        currentDay: DateTime(2026, 4, 26),
        weekStartDate: DateTime(2026, 4, 22),
        missedTrackingThisWeek: false,
        missedTrackingForClosedWeeks: const <bool>[false, false],
      );

      expect(repository.state.currentWeekStartDayKey, '2026-4-22');
      expect(repository.state.lastActiveDayKey, '2026-4-26');
      expect(repository.state.runWeekNumber, 3);
      expect(repository.state.starCount, 2);
    },
  );

  test(
    'syncForWeek repairs current-week state that skipped closed weeks',
    () async {
      final repository = _FakeBurnWeekRunStateRepository(
        buildState(
          currentWeekStartDayKey: '2026-4-22',
          lastActiveDayKey: '2026-4-26',
          runWeekNumber: 1,
          starCount: 0,
          heartCount: 3,
        ),
      );
      final container = buildContainer(repository);

      await syncWeek(
        container,
        currentDay: DateTime(2026, 4, 26),
        weekStartDate: DateTime(2026, 4, 22),
        missedTrackingThisWeek: false,
        missedTrackingForClosedWeeks: const <bool>[false, false],
      );

      expect(repository.state.currentWeekStartDayKey, '2026-4-22');
      expect(repository.state.lastActiveDayKey, '2026-4-26');
      expect(repository.state.runWeekNumber, 3);
      expect(repository.state.starCount, 2);
    },
  );

  test(
    'syncForWeek advances week and awards star after perfect week',
    () async {
      final repository = _FakeBurnWeekRunStateRepository(
        buildState(
          currentWeekStartDayKey: '2026-04-14',
          lastActiveDayKey: '2026-04-20',
          runWeekNumber: 1,
          starCount: 0,
          heartCount: 2,
          heartCreditKcal: 300,
        ),
      );
      final container = buildContainer(repository);

      await syncWeek(
        container,
        currentDay: DateTime(2026, 4, 21),
        weekStartDate: DateTime(2026, 4, 21),
        missedTrackingThisWeek: false,
        missedTrackingForClosedWeeks: const <bool>[false],
      );

      expect(repository.state.currentWeekStartDayKey, '2026-4-21');
      expect(repository.state.runWeekNumber, 2);
      expect(repository.state.starCount, 1);
      expect(repository.state.heartCreditKcal, 0);
      expect(repository.state.missedTrackingThisWeek, isFalse);
    },
  );

  test(
    'syncForWeek normalizes padded stored week keys without advancing',
    () async {
      final repository = _FakeBurnWeekRunStateRepository(
        buildState(
          currentWeekStartDayKey: '2026-04-21',
          lastActiveDayKey: '2026-04-21',
          runWeekNumber: 2,
          starCount: 1,
          heartCount: 3,
        ),
      );
      final container = buildContainer(repository);

      await syncWeek(
        container,
        currentDay: DateTime(2026, 4, 21),
        weekStartDate: DateTime(2026, 4, 21),
        missedTrackingThisWeek: false,
        missedTrackingForClosedWeeks: const <bool>[false],
      );

      expect(repository.state.currentWeekStartDayKey, '2026-4-21');
      expect(repository.state.lastActiveDayKey, '2026-4-21');
      expect(repository.state.runWeekNumber, 2);
      expect(repository.state.starCount, 1);
    },
  );

  test(
    'syncForWeek snaps backward week targets without looping forever',
    () async {
      final repository = _FakeBurnWeekRunStateRepository(
        buildState(
          currentWeekStartDayKey: '2026-4-21',
          lastActiveDayKey: '2026-4-21',
          runWeekNumber: 2,
          starCount: 1,
          heartCount: 3,
        ),
      );
      final container = buildContainer(repository);

      await syncWeek(
        container,
        currentDay: DateTime(2026, 4, 21),
        weekStartDate: DateTime(2026, 4, 14),
        missedTrackingThisWeek: false,
        missedTrackingForClosedWeeks: const <bool>[false],
      );

      expect(repository.state.currentWeekStartDayKey, '2026-4-14');
      expect(repository.state.lastActiveDayKey, '2026-4-21');
      expect(repository.state.runWeekNumber, 2);
      expect(repository.state.starCount, 1);
    },
  );

  test(
    'syncForWeek stops safely when the advance cap is reached',
    () async {
      final repository = _FakeBurnWeekRunStateRepository(
        buildState(
          currentWeekStartDayKey: '2026-4-1',
          runWeekNumber: 1,
          starCount: 0,
          heartCount: 3,
        ),
      );
      final container = buildContainer(repository);
      final cappedWeekStartDate =
          DateTime(
            2026,
            4,
          ).add(
            const Duration(days: burnWeekDaysPerWeek * 1001),
          );

      await syncWeek(
        container,
        currentDay: cappedWeekStartDate,
        weekStartDate: cappedWeekStartDate,
        missedTrackingThisWeek: false,
        missedTrackingForClosedWeeks: List<bool>.filled(1001, false),
      );

      expect(
        repository.state.currentWeekStartDayKey,
        diaryDayKey(cappedWeekStartDate),
      );
      expect(
        repository.state.lastActiveDayKey,
        diaryDayKey(cappedWeekStartDate),
      );
      expect(repository.state.runWeekNumber, 1001);
    },
  );

  test('usePositiveHeart spends heart and adds heart credit', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      buildState(
        currentWeekStartDayKey: '2026-04-21',
        runWeekNumber: 2,
        starCount: 0,
        heartCount: 3,
      ),
    );
    final container = buildContainer(repository);

    await container.read(burnWeekRunControllerProvider.future);
    await container
        .read(burnWeekRunControllerProvider.notifier)
        .usePositiveHeart(500);

    expect(repository.state.heartCount, 2);
    expect(repository.state.heartCreditKcal, 500);
  });

  test('usePositiveHeart with zero hearts keeps the state unchanged', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState(
        currentWeekStartDayKey: '2026-4-21',
        lastActiveDayKey: '2026-4-21',
        runWeekNumber: 4,
        starCount: 2,
        heartCount: 0,
        heartCreditKcal: 150,
        starBrokeThisWeek: true,
        missedTrackingThisWeek: false,
      ),
    );
    final container = buildContainer(repository);

    await container.read(burnWeekRunControllerProvider.future);
    await container
        .read(burnWeekRunControllerProvider.notifier)
        .usePositiveHeart(500);

    expect(repository.state.currentWeekStartDayKey, '2026-4-21');
    expect(repository.state.lastActiveDayKey, '2026-4-21');
    expect(repository.state.runWeekNumber, 4);
    expect(repository.state.starCount, 2);
    expect(repository.state.heartCount, 0);
    expect(repository.state.heartCreditKcal, 150);
    expect(repository.state.starBrokeThisWeek, isTrue);
  });

  test('bootstrapRunFrom seeds a fresh onboarding position', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    );
    final container = buildContainer(repository);

    await container.read(burnWeekRunControllerProvider.future);
    await container
        .read(burnWeekRunControllerProvider.notifier)
        .bootstrapRunFrom(
          weekStartDate: DateTime(2026, 4, 21),
          heartCreditKcal: 875,
        );

    expect(repository.state.currentWeekStartDayKey, '2026-4-21');
    expect(repository.state.runWeekNumber, 1);
    expect(repository.state.starCount, 0);
    expect(repository.state.heartCount, 3);
    expect(repository.state.heartCreditKcal, 875);
  });

  test(
    'syncForWeek keeps optimistic heart change during in-flight save',
    () async {
      final repository = _DelayedBurnWeekRunStateRepository(
        const BurnWeekRunState(
          currentWeekStartDayKey: '2026-4-21',
          lastActiveDayKey: '2026-4-21',
          runWeekNumber: 2,
          starCount: 0,
          heartCount: 3,
          heartCreditKcal: 0,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
        saveDelay: const Duration(milliseconds: 20),
      );
      final container = ProviderContainer(
        overrides: [
          burnWeekRunStateRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(burnWeekRunControllerProvider.future);

      final consumeFuture = container
          .read(burnWeekRunControllerProvider.notifier)
          .usePositiveHeart(500);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(burnWeekRunControllerProvider.notifier)
          .syncForWeek(
            currentDay: DateTime(2026, 4, 21),
            weekStartDate: DateTime(2026, 4, 21),
            missedTrackingThisWeek: false,
            missedTrackingForClosedWeeks: const <bool>[false],
          );
      await consumeFuture;

      expect(repository.state.heartCount, 2);
      expect(repository.state.heartCreditKcal, 500);
      expect(repository.state.lastActiveDayKey, '2026-4-21');
    },
  );

  test('using last heart breaks star and restores hearts', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState(
        currentWeekStartDayKey: '2026-04-21',
        runWeekNumber: 3,
        starCount: 2,
        heartCount: 1,
        heartCreditKcal: 0,
        starBrokeThisWeek: false,
        missedTrackingThisWeek: false,
      ),
    );
    final container = buildContainer(repository);

    await container.read(burnWeekRunControllerProvider.future);
    await container
        .read(burnWeekRunControllerProvider.notifier)
        .useNegativeHeart(700);

    expect(repository.state.starCount, 1);
    expect(repository.state.heartCount, 3);
    expect(repository.state.heartCreditKcal, -700);
    expect(repository.state.starBrokeThisWeek, isTrue);
  });

  test(
    'breaking a star restores hearts to the next difficulty minimum',
    () async {
      final repository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState(
          currentWeekStartDayKey: '2026-4-21',
          runWeekNumber: 7,
          starCount: 5,
          heartCount: 1,
          heartCreditKcal: 0,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
      );
      final container = buildContainer(repository);

      await container.read(burnWeekRunControllerProvider.future);
      await container
          .read(burnWeekRunControllerProvider.notifier)
          .usePositiveHeart(500);

      expect(repository.state.starCount, 4);
      expect(repository.state.heartCount, 2);
      expect(repository.state.heartCreditKcal, 500);
      expect(repository.state.starBrokeThisWeek, isTrue);
    },
  );

  test(
    'using last heart with no stars applies credit and keeps run alive',
    () async {
      const expectedWeekStartKey = '2026-04-21';
      final repository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState(
          currentWeekStartDayKey: '2026-04-21',
          runWeekNumber: 5,
          starCount: 0,
          heartCount: 1,
          heartCreditKcal: 200,
          starBrokeThisWeek: true,
          missedTrackingThisWeek: true,
        ),
      );
      final container = buildContainer(repository);

      await container.read(burnWeekRunControllerProvider.future);
      await container
          .read(burnWeekRunControllerProvider.notifier)
          .usePositiveHeart(500);

      expect(
        repository.state.currentWeekStartDayKey,
        expectedWeekStartKey,
      );
      expect(repository.state.runWeekNumber, 5);
      expect(repository.state.starCount, 0);
      expect(repository.state.heartCount, 0);
      expect(repository.state.heartCreditKcal, 700);
      expect(repository.state.starBrokeThisWeek, isTrue);
    },
  );

  test('syncForWeek catches up across multiple missed weeks', () async {
    final state = await syncAcrossThreeClosedWeeks(
      missedTrackingForClosedWeeks: const <bool>[true, true, true],
    );

    expect(state.currentWeekStartDayKey, '2026-4-22');
    expect(state.runWeekNumber, 4);
    expect(state.starCount, 0);
  });

  test('syncForWeek scores multiple fully tracked closed weeks', () async {
    final state = await syncAcrossThreeClosedWeeks(
      missedTrackingForClosedWeeks: const <bool>[false, false, false],
    );

    expect(state.currentWeekStartDayKey, '2026-4-22');
    expect(state.runWeekNumber, 4);
    expect(state.starCount, 3);
  });

  test(
    'syncForWeek scores the closing week from missed-tracking state',
    () async {
      final state = await syncClosingWeek(
        missedTrackingForClosedWeek: false,
      );

      expect(state.currentWeekStartDayKey, '2026-4-21');
      expect(state.lastActiveDayKey, '2026-4-21');
      expect(state.runWeekNumber, 2);
      expect(state.starCount, 1);
    },
  );

  test('syncForWeek honors a missed closed week from diary data', () async {
    final state = await syncClosingWeek(
      missedTrackingForClosedWeek: true,
    );

    expect(state.currentWeekStartDayKey, '2026-4-21');
    expect(state.lastActiveDayKey, '2026-4-21');
    expect(state.runWeekNumber, 2);
    expect(state.starCount, 0);
  });

  test('restartRunFrom resets progress and anchors new week start', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState(
        currentWeekStartDayKey: '2026-4-15',
        runWeekNumber: 3,
        starCount: 2,
        heartCount: 1,
        heartCreditKcal: -500,
        starBrokeThisWeek: true,
        missedTrackingThisWeek: true,
      ),
    );
    final container = buildContainer(repository);

    await container.read(burnWeekRunControllerProvider.future);
    await container
        .read(burnWeekRunControllerProvider.notifier)
        .restartRunFrom(weekStartDate: DateTime(2026, 4, 21));

    expect(repository.state.currentWeekStartDayKey, '2026-4-21');
    expect(repository.state.runWeekNumber, 1);
    expect(repository.state.starCount, 0);
    expect(repository.state.heartCount, 3);
    expect(repository.state.heartCreditKcal, 0);
  });
}
