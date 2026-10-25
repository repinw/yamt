import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/burn_week_run_controller.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  new(this.state);

  BurnWeekRunState state;
  bool saveThrows = false;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    if (saveThrows) {
      throw StateError('offline');
    }
    state = nextState;
    return true;
  }
}

void main() {
  ProviderContainer buildContainer(_FakeBurnWeekRunStateRepository repository) {
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
    String? lastActiveDayKey,
    bool starBrokeThisWeek = false,
    bool missedTrackingThisWeek = false,
  }) {
    return BurnWeekRunState(
      currentWeekStartDayKey: currentWeekStartDayKey,
      lastActiveDayKey: lastActiveDayKey,
      runWeekNumber: runWeekNumber,
      starCount: starCount,
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

  test('syncForWeek stops safely when the advance cap is reached', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      buildState(
        currentWeekStartDayKey: '2026-4-1',
        runWeekNumber: 1,
        starCount: 0,
      ),
    );
    final container = buildContainer(repository);
    final cappedWeekStartDate = DateTime(
      2026,
      4,
    ).add(const Duration(days: burnWeekDaysPerWeek * 1001));

    await syncWeek(
      container,
      currentDay: cappedWeekStartDate,
      weekStartDate: cappedWeekStartDate,
      missedTrackingThisWeek: false,
      missedTrackingForClosedWeeks: List<bool>.filled(1001, false),
    );

    expect(
      repository.state.currentWeekStartDayKey,
      localDayKey(cappedWeekStartDate),
    );
    expect(repository.state.lastActiveDayKey, localDayKey(cappedWeekStartDate));
    expect(repository.state.runWeekNumber, 1001);
  });

  test('bootstrapRunFrom seeds a fresh onboarding position', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    );
    final container = buildContainer(repository);

    await container.read(burnWeekRunControllerProvider.future);
    await container
        .read(burnWeekRunControllerProvider.notifier)
        .bootstrapRunFrom(weekStartDate: DateTime(2026, 4, 21));

    expect(repository.state.currentWeekStartDayKey, '2026-4-21');
    expect(repository.state.runWeekNumber, burnWeekLearningRunWeekNumber);
    expect(repository.state.starCount, 0);
  });

  test('bootstrapRunFrom can seed a custom run week position', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    );
    final container = buildContainer(repository);

    await container.read(burnWeekRunControllerProvider.future);
    await container
        .read(burnWeekRunControllerProvider.notifier)
        .bootstrapRunFrom(
          weekStartDate: DateTime(2026, 4, 21),
          runWeekNumber: 2,
        );

    expect(repository.state.currentWeekStartDayKey, '2026-4-21');
    expect(repository.state.runWeekNumber, 2);
  });

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
      final state = await syncClosingWeek(missedTrackingForClosedWeek: false);

      expect(state.currentWeekStartDayKey, '2026-4-21');
      expect(state.lastActiveDayKey, '2026-4-21');
      expect(state.runWeekNumber, 2);
      expect(state.starCount, 1);
    },
  );

  test('syncForWeek honors a missed closed week from diary data', () async {
    final state = await syncClosingWeek(missedTrackingForClosedWeek: true);

    expect(state.currentWeekStartDayKey, '2026-4-21');
    expect(state.lastActiveDayKey, '2026-4-21');
    expect(state.runWeekNumber, 2);
    expect(state.starCount, 0);
  });

  test('restartRunFrom keeps first fresh run in learning week', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    );
    final container = buildContainer(repository);

    await container.read(burnWeekRunControllerProvider.future);
    await container
        .read(burnWeekRunControllerProvider.notifier)
        .restartRunFrom(weekStartDate: DateTime(2026, 4, 21));

    expect(repository.state.currentWeekStartDayKey, '2026-4-21');
    expect(repository.state.runWeekNumber, burnWeekLearningRunWeekNumber);
  });

  test('syncForWeek earns no star for a broken week', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      buildState(
        currentWeekStartDayKey: '2026-4-14',
        runWeekNumber: 2,
        starCount: 1,
        starBrokeThisWeek: true,
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
    expect(repository.state.runWeekNumber, 3);
    expect(repository.state.starCount, 1);
    expect(repository.state.starBrokeThisWeek, isFalse);
  });

  test('restartRunFrom resets progress into first run week', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState(
        currentWeekStartDayKey: '2026-4-15',
        runWeekNumber: 3,
        starCount: 2,
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
    expect(repository.state.runWeekNumber, burnWeekLearningRunWeekNumber);
    expect(repository.state.starCount, 0);
  });

  test('a throwing save puts the previous run back (#710)', () async {
    const previous = BurnWeekRunState(
      currentWeekStartDayKey: '2026-4-15',
      runWeekNumber: 3,
      starCount: 2,
      starBrokeThisWeek: false,
      missedTrackingThisWeek: false,
    );
    final repository = _FakeBurnWeekRunStateRepository(previous)
      ..saveThrows = true;
    final container = buildContainer(repository);
    await container.read(burnWeekRunControllerProvider.future);

    await expectLater(
      container
          .read(burnWeekRunControllerProvider.notifier)
          .restartRunFrom(weekStartDate: DateTime(2026, 4, 21)),
      throwsStateError,
    );

    final state = container.read(burnWeekRunControllerProvider).value;
    expect(state?.currentWeekStartDayKey, '2026-4-15');
    expect(state?.runWeekNumber, 3);
  });

  test('tryRestartRunFrom reports a throwing save as false (#710)', () async {
    final repository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    )..saveThrows = true;
    final container = buildContainer(repository);
    await container.read(burnWeekRunControllerProvider.future);

    final restarted = await container
        .read(burnWeekRunControllerProvider.notifier)
        .tryRestartRunFrom(weekStartDate: DateTime(2026, 4, 21));

    expect(restarted, isFalse);
    expect(
      container.read(burnWeekRunControllerProvider).value,
      const BurnWeekRunState.initial(),
    );
  });
}
