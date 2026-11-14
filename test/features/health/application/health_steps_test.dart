import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/health/application/daily_steps_provider.dart';
import 'package:yamt/features/health/application/health_connection_controller.dart';
import 'package:yamt/features/health/application/health_steps_controller.dart';
import 'package:yamt/features/health/application/health_steps_goal_controller.dart';
import 'package:yamt/features/health/application/health_steps_goal_raise.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_steps_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../support/fake_health_steps_service.dart';

const String _key = healthStepsPreferenceKey;
final DateTime _now = DateTime(2026, 6, 15, 12);

const _ready = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

const _notGranted = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notApplicable,
);

class _FakeConnection implements HealthConnectionService {
  new(this.status, {this.statusAfterRequest});

  HealthConnectionStatus status;
  final HealthConnectionStatus? statusAfterRequest;
  int requests = 0;

  @override
  Future<HealthConnectionStatus> loadStatus() async => status;

  @override
  Future<HealthConnectionStatus> requestAuthorization() async {
    requests += 1;
    return status = statusAfterRequest ?? status;
  }

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async => status;

  @override
  Future<void> installHealthConnect() async {}

  @override
  Future<void> openHealthPermissionSettings() async {}

  @override
  Future<void> openHealthApp() async {}

  @override
  Future<void> openAppPermissionSettings() async {}

  @override
  Future<HealthDisconnectResult> disconnect() async =>
      HealthDisconnectResult.disconnected;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith({
    required _FakeConnection connection,
    required FakeHealthStepsService steps,
    MemoryAppPreferences? preferences,
  }) {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          preferences ?? MemoryAppPreferences(),
        ),
        healthConnectionServiceProvider.overrideWithValue(connection),
        healthStepsServiceProvider.overrideWithValue(steps),
        clockProvider.overrideWithValue(() => _now),
      ],
    );
    addTearDown(container.dispose);
    // The menu switch keeps the controller alive in the app.
    container.listen(healthStepsControllerProvider, (_, _) {});
    return container;
  }

  group('HealthStepsController', () {
    test('is off by default', () {
      final container = containerWith(
        connection: _FakeConnection(_ready),
        steps: FakeHealthStepsService(),
      );

      expect(container.read(healthStepsControllerProvider), isFalse);
    });

    test('turning it on asks for the steps and saves the choice', () async {
      final preferences = MemoryAppPreferences();
      final steps = FakeHealthStepsService();
      final container = containerWith(
        connection: _FakeConnection(_ready),
        steps: steps,
        preferences: preferences,
      );

      final on = await container
          .read(healthStepsControllerProvider.notifier)
          .enable();

      expect(on, HealthStepsEnableResult.enabled);
      expect(steps.accessRequests, 1);
      expect(container.read(healthStepsControllerProvider), isTrue);
      expect(preferences.getIntSync(_key), 1);
    });

    test('connects Health first when it is not ready', () async {
      final connection = _FakeConnection(
        _notGranted,
        statusAfterRequest: _ready,
      );
      final container = containerWith(
        connection: connection,
        steps: FakeHealthStepsService(),
      );

      final on = await container
          .read(healthStepsControllerProvider.notifier)
          .enable();

      expect(connection.requests, 1);
      expect(on, HealthStepsEnableResult.enabled);
    });

    test('stays off when Health is not connected', () async {
      final steps = FakeHealthStepsService();
      final container = containerWith(
        connection: _FakeConnection(_notGranted),
        steps: steps,
      );

      final on = await container
          .read(healthStepsControllerProvider.notifier)
          .enable();

      expect(on, HealthStepsEnableResult.denied);
      expect(steps.accessRequests, 0);
      expect(container.read(healthStepsControllerProvider), isFalse);
    });

    test('a device without Health says so and stays off', () async {
      final steps = FakeHealthStepsService();
      final container = containerWith(
        connection: _FakeConnection(const HealthConnectionStatus.unsupported()),
        steps: steps,
      );

      final on = await container
          .read(healthStepsControllerProvider.notifier)
          .enable();

      expect(on, HealthStepsEnableResult.unsupported);
      expect(steps.accessRequests, 0);
    });

    test('stays off when the steps are declined', () async {
      final preferences = MemoryAppPreferences();
      final container = containerWith(
        connection: _FakeConnection(_ready),
        steps: FakeHealthStepsService(grant: false),
        preferences: preferences,
      );

      final on = await container
          .read(healthStepsControllerProvider.notifier)
          .enable();

      expect(on, HealthStepsEnableResult.denied);
      expect(container.read(healthStepsControllerProvider), isFalse);
      expect(preferences.getIntSync(_key), isNull);
    });

    test('turning it off removes the saved choice', () async {
      final preferences = MemoryAppPreferences(initialInts: {_key: 1});
      final container = containerWith(
        connection: _FakeConnection(_ready),
        steps: FakeHealthStepsService(),
        preferences: preferences,
      );

      await container.read(healthStepsControllerProvider.notifier).disable();

      expect(container.read(healthStepsControllerProvider), isFalse);
      expect(preferences.getIntSync(_key), isNull);
    });
  });

  group('dailyStepsProvider', () {
    final day = DateTime(2026, 6, 14);

    test('is null while steps are off', () async {
      final steps = FakeHealthStepsService();
      final container = containerWith(
        connection: _FakeConnection(_ready),
        steps: steps,
      );

      expect(await container.read(dailyStepsProvider(day).future), isNull);
      expect(steps.ranges, isEmpty);
    });

    test('is null while Health is not ready', () async {
      final container = containerWith(
        connection: _FakeConnection(_notGranted),
        steps: FakeHealthStepsService(),
        preferences: MemoryAppPreferences(initialInts: {_key: 1}),
      );

      expect(await container.read(dailyStepsProvider(day).future), isNull);
    });

    test('reads the steps of the whole calendar day', () async {
      final steps = FakeHealthStepsService();
      final container = containerWith(
        connection: _FakeConnection(_ready),
        steps: steps,
        preferences: MemoryAppPreferences(initialInts: {_key: 1}),
      );

      final value = await container.read(dailyStepsProvider(day).future);

      expect(value, 8432);
      expect(steps.ranges.single, (
        day,
        DateTime(day.year, day.month, day.day + 1),
      ));
    });

    test('is null for a day in the future', () async {
      final steps = FakeHealthStepsService();
      final container = containerWith(
        connection: _FakeConnection(_ready),
        steps: steps,
        preferences: MemoryAppPreferences(initialInts: {_key: 1}),
      );

      final tomorrow = DateTime(2026, 6, 16);
      expect(await container.read(dailyStepsProvider(tomorrow).future), isNull);
      expect(steps.ranges, isEmpty);
    });

    test('reads today up to midnight', () async {
      final steps = FakeHealthStepsService();
      final container = containerWith(
        connection: _FakeConnection(_ready),
        steps: steps,
        preferences: MemoryAppPreferences(initialInts: {_key: 1}),
      );

      final today = DateTime(2026, 6, 15);
      expect(await container.read(dailyStepsProvider(today).future), 8432);
      expect(steps.ranges.single, (today, DateTime(2026, 6, 16)));
    });
  });

  test('weekDailySteps lists the seven days from the week start', () async {
    final steps = FakeHealthStepsService();
    final container = containerWith(
      connection: _FakeConnection(_ready),
      steps: steps,
      preferences: MemoryAppPreferences(initialInts: {_key: 1}),
    );

    // The clock stands at noon of June 15, so June 16 and 17 lie ahead.
    final week = await container.read(
      weekDailyStepsProvider(DateTime(2026, 6, 11)).future,
    );

    expect(week, [8432, 8432, 8432, 8432, 8432, null, null]);
    expect(steps.ranges.map((range) => range.$1).toSet(), {
      for (var day = 11; day <= 15; day++) DateTime(2026, 6, day),
    });
  });

  test('weekDailySteps keeps the week when a day fails', () async {
    final container = containerWith(
      connection: _FakeConnection(_ready),
      steps: FakeHealthStepsService(
        stepsOf: (day) => day.day == 10 ? throw StateError('read') : 100,
      ),
      preferences: MemoryAppPreferences(initialInts: {_key: 1}),
    );

    final week = await container.read(
      weekDailyStepsProvider(DateTime(2026, 6, 8)).future,
    );

    expect(week, [100, 100, null, 100, 100, 100, 100]);
  });

  testWidgets('today is read again after five minutes, until nobody listens', (
    tester,
  ) async {
    final steps = FakeHealthStepsService();
    final container = containerWith(
      connection: _FakeConnection(_ready),
      steps: steps,
      preferences: MemoryAppPreferences(initialInts: {_key: 1}),
    );
    final subscription = container.listen(
      dailyStepsProvider(DateTime(2026, 6, 15)),
      (_, _) {},
    );
    await tester.pump();
    expect(steps.ranges, hasLength(1));

    await tester.pump(dailyStepsTodayRefresh);
    await tester.pump();
    expect(steps.ranges, hasLength(2));

    subscription.close();
    await tester.pump(dailyStepsTodayRefresh * 3);
    expect(steps.ranges, hasLength(2));
  });

  group('HealthStepsGoalController', () {
    ProviderContainer goalContainer(MemoryAppPreferences preferences) {
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      container.listen(healthStepsGoalControllerProvider, (_, _) {});
      return container;
    }

    test('has no goal by default', () {
      final container = goalContainer(MemoryAppPreferences());

      expect(container.read(healthStepsGoalControllerProvider), isNull);
    });

    test('saves a goal for the next start and caps it', () async {
      final preferences = MemoryAppPreferences();
      final container = goalContainer(preferences);
      final goal = container.read(healthStepsGoalControllerProvider.notifier);

      await goal.save(8000);
      expect(container.read(healthStepsGoalControllerProvider), 8000);
      expect(
        goalContainer(preferences).read(healthStepsGoalControllerProvider),
        8000,
      );

      await goal.save(5000000);
      expect(
        container.read(healthStepsGoalControllerProvider),
        healthStepsGoalMax,
      );
    });

    test('null or zero removes the goal', () async {
      final preferences = MemoryAppPreferences();
      final container = goalContainer(preferences);
      final goal = container.read(healthStepsGoalControllerProvider.notifier);
      await goal.save(8000);

      await goal.save(0);

      expect(container.read(healthStepsGoalControllerProvider), isNull);
      expect(
        goalContainer(preferences).read(healthStepsGoalControllerProvider),
        isNull,
      );
    });
  });

  group('healthStepsGoalRaiseOffer', () {
    // The week from June 11 follows the week from June 4 to 10.
    final weekStart = DateTime(2026, 6, 11);
    const goalKey = 'health_steps_goal_v1';
    const sinceKey = 'health_steps_goal_since_v1';
    // A goal that stood before the week of the offer began.
    const since = 20260601;

    ProviderContainer offerContainer({
      required int? Function(DateTime day) stepsOf,
      MemoryAppPreferences? preferences,
    }) => containerWith(
      connection: _FakeConnection(_ready),
      steps: FakeHealthStepsService(stepsOf: stepsOf),
      preferences:
          preferences ??
          MemoryAppPreferences(
            initialInts: {_key: 1, goalKey: 5000, sinceKey: since},
          ),
    );

    test('a week that met the goal on average offers 100 more', () async {
      // Two lazy days, made up for by the others: 35 000 steps in the week.
      final container = offerContainer(
        stepsOf: (day) => day.day == 6 || day.day == 7 ? 1000 : 6600,
      );

      expect(
        await container.read(
          healthStepsGoalRaiseOfferProvider(weekStart).future,
        ),
        5100,
      );
    });

    test('a goal set in the running week offers nothing yet', () async {
      final container = offerContainer(
        stepsOf: (_) => 9000,
        preferences: MemoryAppPreferences(
          initialInts: {_key: 1, goalKey: 5000, sinceKey: 20260612},
        ),
      );

      expect(
        await container.read(
          healthStepsGoalRaiseOfferProvider(weekStart).future,
        ),
        isNull,
      );
    });

    test('saving a goal remembers the day it was set', () async {
      final preferences = MemoryAppPreferences(initialInts: {_key: 1});
      final container = offerContainer(
        stepsOf: (_) => 9000,
        preferences: preferences,
      )..listen(healthStepsGoalControllerProvider, (_, _) {});

      await container
          .read(healthStepsGoalControllerProvider.notifier)
          .save(5000);
      expect(preferences.getIntSync(sinceKey), 20260615);

      await container
          .read(healthStepsGoalControllerProvider.notifier)
          .save(null);
      expect(preferences.getIntSync(sinceKey), isNull);
    });

    test('saving the goal it already has keeps the day it was set', () async {
      final preferences = MemoryAppPreferences(
        initialInts: {_key: 1, goalKey: 5000, sinceKey: since},
      );
      final container = offerContainer(
        stepsOf: (_) => 9000,
        preferences: preferences,
      )..listen(healthStepsGoalControllerProvider, (_, _) {});

      await container
          .read(healthStepsGoalControllerProvider.notifier)
          .save(5000);

      expect(preferences.getIntSync(sinceKey), since);
    });

    test('a goal set inside the week before is measured on that whole '
        'week', () async {
      final container = offerContainer(
        stepsOf: (_) => 9000,
        preferences: MemoryAppPreferences(
          initialInts: {_key: 1, goalKey: 5000, sinceKey: 20260608},
        ),
      );

      expect(
        await container.read(
          healthStepsGoalRaiseOfferProvider(weekStart).future,
        ),
        5100,
      );
    });

    test('a week under the goal offers nothing', () async {
      final container = offerContainer(stepsOf: (_) => 4999);

      expect(
        await container.read(
          healthStepsGoalRaiseOfferProvider(weekStart).future,
        ),
        isNull,
      );
    });

    test('without a goal there is no offer', () async {
      final container = offerContainer(
        stepsOf: (_) => 9000,
        preferences: MemoryAppPreferences(initialInts: {_key: 1}),
      );

      expect(
        await container.read(
          healthStepsGoalRaiseOfferProvider(weekStart).future,
        ),
        isNull,
      );
    });

    test('yes raises the goal and ends the offer of that week', () async {
      final preferences = MemoryAppPreferences(
        initialInts: {_key: 1, goalKey: 5000, sinceKey: since},
      );
      final container =
          offerContainer(stepsOf: (_) => 9000, preferences: preferences)
            ..listen(healthStepsGoalRaiseAnswerProvider, (_, _) {})
            ..listen(healthStepsGoalControllerProvider, (_, _) {});

      await container
          .read(healthStepsGoalRaiseAnswerProvider.notifier)
          .answer(weekStart, raise: true);

      expect(preferences.getIntSync(goalKey), 5100);
      expect(
        await container.read(
          healthStepsGoalRaiseOfferProvider(weekStart).future,
        ),
        isNull,
      );
      // The next met week asks again, from the new goal.
      expect(
        await container.read(
          healthStepsGoalRaiseOfferProvider(DateTime(2026, 6, 18)).future,
        ),
        5200,
      );
    });

    test('a second yes for the same week raises the goal only once', () async {
      final preferences = MemoryAppPreferences(
        initialInts: {_key: 1, goalKey: 5000, sinceKey: since},
      );
      final container =
          offerContainer(stepsOf: (_) => 9000, preferences: preferences)
            ..listen(healthStepsGoalRaiseAnswerProvider, (_, _) {})
            ..listen(healthStepsGoalControllerProvider, (_, _) {});
      final answers = container.read(
        healthStepsGoalRaiseAnswerProvider.notifier,
      );

      await Future.wait([
        answers.answer(weekStart, raise: true),
        answers.answer(weekStart, raise: true),
      ]);

      expect(preferences.getIntSync(goalKey), 5100);
    });

    test('a yes whose goal cannot be saved keeps the offer', () async {
      final preferences = _FailingKeyPreferences(
        failingKey: goalKey,
        initialInts: {_key: 1, goalKey: 5000, sinceKey: since},
      );
      final container =
          offerContainer(stepsOf: (_) => 9000, preferences: preferences)
            ..listen(healthStepsGoalRaiseAnswerProvider, (_, _) {})
            ..listen(healthStepsGoalControllerProvider, (_, _) {});

      await expectLater(
        container
            .read(healthStepsGoalRaiseAnswerProvider.notifier)
            .answer(weekStart, raise: true),
        throwsStateError,
      );

      expect(container.read(healthStepsGoalControllerProvider), 5000);
      expect(
        preferences.getIntSync('health_steps_goal_raise_answered_v1'),
        isNull,
      );
      expect(
        await container.read(
          healthStepsGoalRaiseOfferProvider(weekStart).future,
        ),
        5100,
      );
    });

    test('no keeps the goal and ends the offer of that week', () async {
      final preferences = MemoryAppPreferences(
        initialInts: {_key: 1, goalKey: 5000, sinceKey: since},
      );
      final container = offerContainer(
        stepsOf: (_) => 9000,
        preferences: preferences,
      )..listen(healthStepsGoalRaiseAnswerProvider, (_, _) {});

      await container
          .read(healthStepsGoalRaiseAnswerProvider.notifier)
          .answer(weekStart, raise: false);

      expect(preferences.getIntSync(goalKey), 5000);
      expect(
        await container.read(
          healthStepsGoalRaiseOfferProvider(weekStart).future,
        ),
        isNull,
      );
    });
  });

  test('disconnecting Health turns the steps off', () async {
    final preferences = MemoryAppPreferences(initialInts: {_key: 1});
    final container = containerWith(
      connection: _FakeConnection(_ready),
      steps: FakeHealthStepsService(),
      preferences: preferences,
    );
    expect(container.read(healthStepsControllerProvider), isTrue);
    container.listen(healthConnectionControllerProvider, (_, _) {});
    await container.read(healthConnectionControllerProvider.future);

    await container
        .read(healthConnectionControllerProvider.notifier)
        .disconnect();

    expect(preferences.getIntSync(_key), isNull);
    expect(container.read(healthStepsControllerProvider), isFalse);
  });
}

/// Preferences whose write of [failingKey] fails.
class _FailingKeyPreferences extends MemoryAppPreferences {
  new({required this.failingKey, super.initialInts});

  final String failingKey;

  @override
  Future<bool> setInt(String key, int value) {
    if (key == failingKey) {
      throw StateError('write failed');
    }
    return super.setInt(key, value);
  }
}
