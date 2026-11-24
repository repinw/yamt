// Technical tests of the free kcal notice (#971): tomorrow's target provider,
// sync while tomorrow or today loads, and the debug notice.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_shares_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notice_day_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notification_controller.dart';

import '../../../../helpers/auth_user_data_key_session.dart';
import '../../../../helpers/fake_local_notifications.dart';
import '../../../../helpers/memory_app_preferences.dart';

const _onKey = 'diary_pace_notification_on_v1';
const _markerKey = 'diary_pace_marker_v1';
const _tomorrowKey = 'diary_pace_notification_tomorrow_v1';
const _idBase = 300000000;
const int _tomorrowId = _idBase + 50;
const int _debugId = _idBase + 99;
final _today = DateTime(2026, 11, 12);
final _tomorrow = DateTime(2026, 11, 13);

int _id(MealType meal) => _idBase + MealType.sectionOrder.indexOf(meal);

class _RecordingNotifications extends FakeLocalNotifications {
  final bodies = <int, String>{};

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required NotificationChannel channel,
    required String title,
    required String body,
    required String payload,
    bool exact = false,
    AlarmStyle? alarm,
  }) {
    bodies[id] = body;
    return super.schedule(
      id: id,
      at: at,
      channel: channel,
      title: title,
      body: body,
      payload: payload,
      exact: exact,
      alarm: alarm,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // What the clock shows; a test moves it on.
  late DateTime now;
  setUp(() => now = DateTime(2026, 11, 12, 12));

  final texts = (
    channelName: 'Frei',
    title: (int kcal) => 'free $kcal',
    body: (DiaryPaceMacro? macro) => macro?.name ?? '',
  );

  DiaryPaceDay pace({
    double target = 2000,
    double eaten = 0,
    DiaryPaceMacro? macro,
    DateTime? day,
  }) => (
    day: day ?? _today,
    targetKcal: target,
    eatenKcal: eaten,
    times: DiaryMealTimes.standard,
    shares: DiaryMealShares.standard,
    macro: macro,
  );

  /// [budget] stands for what the week overview says about tomorrow: a
  /// value, null for a pause day, or no value while it loads.
  ProviderContainer containerWith({
    FakeLocalNotifications? notifications,
    MemoryAppPreferences? preferences,
    Future<double?>? budget,
    bool markerOn = true,
    bool noticesOn = true,
    UserDataKeySession Function()? session,
  }) {
    final container = ProviderContainer(
      overrides: [
        if (session == null)
          userDataCipherProvider.overrideWithValue(testUserDataCipher)
        else
          userDataKeySessionProvider.overrideWith(session),
        appPreferencesProvider.overrideWithValue(
          preferences ??
              MemoryAppPreferences(
                initialInts: {if (markerOn) _markerKey: 1},
                initialStrings: {if (noticesOn) _onKey: 'set'},
              ),
        ),
        clockProvider.overrideWithValue(() => now),
        localNotificationsProvider.overrideWithValue(
          notifications ?? FakeLocalNotifications(),
        ),
        diaryDayBudgetKcalProvider(_tomorrow)
            .overrideWith((ref) => budget ?? Completer<double?>().future),
      ],
    );
    addTearDown(container.dispose);
    // The switch's state lives in the controller; keep it alive.
    container.listen(diaryPaceNotificationControllerProvider, (_, _) {});
    return container;
  }

  DiaryPaceNotificationController controllerOf(ProviderContainer container) =>
      container.read(diaryPaceNotificationControllerProvider.notifier);

  /// Reads tomorrow's value once the budget future has settled.
  Future<AsyncValue<DiaryPaceTomorrow>> readTomorrow(
    ProviderContainer container, {
    bool awaitBudget = true,
  }) async {
    final subscription = container.listen(
      diaryPaceTomorrowTargetProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    try {
      if (awaitBudget) {
        await container.read(diaryDayBudgetKcalProvider(_tomorrow).future);
      }
    } on Object {
      // A failed budget stays loading, which the test asserts.
    }
    return subscription.read();
  }

  group('diaryPaceTomorrowTarget', () {
    test("is loading while tomorrow's budget loads", () {
      final container = containerWith();
      final value = container.listen(
        diaryPaceTomorrowTargetProvider,
        (_, _) {},
      );
      addTearDown(value.close);

      expect(value.read(), isA<AsyncLoading<DiaryPaceTomorrow>>());
      expect(value.read().hasValue, isFalse);
    });

    test('is an error when the budget failed to load', () async {
      final value = await readTomorrow(
        containerWith(budget: Future<double?>.error(StateError('offline'))),
      );

      expect(value, isA<AsyncError<DiaryPaceTomorrow>>());
      expect(value.hasValue, isFalse);
      expect(value.error, isA<StateError>());
    });

    test('is data without a target when nobody is signed in', () async {
      final container = containerWith(session: SignedOutUserDataKeySession.new);
      await container.read(userDataKeySessionProvider.future);

      final value = await readTomorrow(container, awaitBudget: false);

      expect(value, isA<AsyncData<DiaryPaceTomorrow>>());
      expect(value.value!.targetKcal, isNull);
    });

    test('is loading while the data key loads', () {
      final container = containerWith(session: LoadingUserDataKeySession.new);
      final value = container.listen(
        diaryPaceTomorrowTargetProvider,
        (_, _) {},
      );
      addTearDown(value.close);

      expect(value.read(), isA<AsyncLoading<DiaryPaceTomorrow>>());
    });

    test("has tomorrow's budget, carryover included", () async {
      // A target that differs from a plain daily goal: the carryover moved it.
      final value = await readTomorrow(
        containerWith(budget: Future<double?>.value(1743)),
      );

      expect(value, isA<AsyncData<DiaryPaceTomorrow>>());
      expect(value.value!.day, _tomorrow);
      expect(value.value!.targetKcal, 1743);
      expect(value.value!.times, DiaryMealTimes.standard);
      expect(value.value!.shares, DiaryMealShares.standard);
    });

    test('is data without a target on a pause day, not loading', () async {
      final value = await readTomorrow(
        containerWith(budget: Future<double?>.value()),
      );

      expect(value, isA<AsyncData<DiaryPaceTomorrow>>());
      expect(value.value!.targetKcal, isNull);
    });

    test('is data without a target while the notices are off, even while '
        'tomorrow loads', () {
      final container = containerWith(noticesOn: false);
      final value = container.listen(
        diaryPaceTomorrowTargetProvider,
        (_, _) {},
      );
      addTearDown(value.close);

      expect(value.read(), isA<AsyncData<DiaryPaceTomorrow>>());
      expect(value.read().value!.targetKcal, isNull);
    });

    test('is data without a target while the pace marker is off, even while '
        'tomorrow loads', () {
      final container = containerWith(markerOn: false);
      final value = container.listen(
        diaryPaceTomorrowTargetProvider,
        (_, _) {},
      );
      addTearDown(value.close);

      expect(value.read(), isA<AsyncData<DiaryPaceTomorrow>>());
      expect(value.read().value!.targetKcal, isNull);
    });

    test('hands out a new value when the meal shares change, also on a pause '
        'day', () async {
      final container = containerWith(budget: Future<double?>.value());
      final values = <DiaryPaceTomorrow>[];
      final subscription = container.listen(diaryPaceTomorrowTargetProvider, (
        _,
        next,
      ) {
        if (next.hasValue) values.add(next.value!);
      });
      addTearDown(subscription.close);
      await container.read(diaryDayBudgetKcalProvider(_tomorrow).future);
      await Future<void>.delayed(Duration.zero);
      values.clear();

      await container
          .read(diaryMealSharesControllerProvider.notifier)
          .select(const DiaryMealShares([30, 30, 30, 10]));
      await Future<void>.delayed(Duration.zero);

      expect(values.map((v) => v.shares), [
        const DiaryMealShares([30, 30, 30, 10]),
      ]);
      expect(values.single.targetKcal, isNull);
    });
  });

  group('sync while tomorrow loads', () {
    test(
      'a pending tomorrow notice stays pending and is not planned again',
      () async {
        final notifications = FakeLocalNotifications();
        final container = containerWith(notifications: notifications);
        final controller = container.read(
          diaryPaceNotificationControllerProvider.notifier,
        );
        await controller.sync(pace(), texts, tomorrowTargetKcal: 2000);
        final planned = notifications.scheduled[_tomorrowId]!;
        expect(planned.at, DateTime(2026, 11, 13, 6));
        // A mark that a second planning would overwrite.
        notifications.scheduled[_tomorrowId] = (
          at: planned.at,
          title: 'marked',
          payload: planned.payload,
        );

        await controller.sync(pace(), texts, tomorrowLoading: true);

        expect(notifications.scheduled[_tomorrowId]!.title, 'marked');
      },
    );

    test(
      'plans no tomorrow notice while it loads and none is pending',
      () async {
        final notifications = FakeLocalNotifications();
        final container = containerWith(notifications: notifications);

        await container
            .read(diaryPaceNotificationControllerProvider.notifier)
            .sync(pace(), texts, tomorrowLoading: true);

        expect(notifications.scheduled.containsKey(_tomorrowId), isFalse);
      },
    );

    test('the loading flag still cancels the stale notices of today', () async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      final controller = container.read(
        diaryPaceNotificationControllerProvider.notifier,
      );
      await controller.sync(pace(), texts, tomorrowTargetKcal: 2000);
      expect(notifications.scheduled.length, greaterThan(1));

      await controller.sync(null, texts, tomorrowLoading: true);

      expect(notifications.scheduled.keys, [_tomorrowId]);
    });

    test(
      'cancels the pending tomorrow notice when the notices are off',
      () async {
        final notifications = FakeLocalNotifications();
        final container = containerWith(
          notifications: notifications,
          noticesOn: false,
        );
        notifications.scheduled[_tomorrowId] = (
          at: DateTime(2026, 11, 13, 6),
          title: 'pending',
          payload: diaryPaceChannelId,
        );

        await container
            .read(diaryPaceNotificationControllerProvider.notifier)
            .sync(null, texts, tomorrowLoading: true);

        expect(notifications.scheduled, isEmpty);
      },
    );

    test(
      'cancels the pending tomorrow notice when the pace marker is off',
      () async {
        final notifications = FakeLocalNotifications();
        final container = containerWith(
          notifications: notifications,
          markerOn: false,
        );
        notifications.scheduled[_tomorrowId] = (
          at: DateTime(2026, 11, 13, 6),
          title: 'pending',
          payload: diaryPaceChannelId,
        );

        await container
            .read(diaryPaceNotificationControllerProvider.notifier)
            .sync(null, texts, tomorrowLoading: true);

        expect(notifications.scheduled, isEmpty);
      },
    );

    test('cancels the pending tomorrow notice for a pause day once it is '
        'known', () async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      notifications.scheduled[_tomorrowId] = (
        at: DateTime(2026, 11, 13, 6),
        title: 'pending',
        payload: diaryPaceChannelId,
      );

      await container
          .read(diaryPaceNotificationControllerProvider.notifier)
          .sync(pace(), texts);

      expect(notifications.scheduled.containsKey(_tomorrowId), isFalse);
    });
  });

  group('sync across midnight', () {
    // The clock after midnight; the notice planned yesterday for today is
    // still pending.
    final afterMidnight = DateTime(2026, 11, 13, 0, 30);

    Future<
      ({FakeLocalNotifications notifications, ProviderContainer container})
    >
    plannedYesterday() async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      await controllerOf(container)
          .sync(pace(), texts, tomorrowTargetKcal: 2000);
      expect(
        notifications.scheduled[_tomorrowId]!.at,
        DateTime(2026, 11, 13, 6),
      );
      now = afterMidnight;
      return (notifications: notifications, container: container);
    }

    List<int> idsAt(FakeLocalNotifications notifications, DateTime at) => [
      for (final e in notifications.scheduled.entries)
        if (e.value.at == at) e.key,
    ];

    test('the day-start notice of the new day stays once, while the budget '
        'of the day after loads', () async {
      final (:notifications, :container) = await plannedYesterday();

      await controllerOf(container)
          .sync(pace(day: _tomorrow), texts, tomorrowLoading: true);

      // Only +0 stays pending at 6:00: the notice of yesterday for this day
      // is gone, so the 6:00 notice does not come twice.
      expect(idsAt(notifications, DateTime(2026, 11, 13, 6)), [
        _id(MealType.breakfast),
      ]);
      expect(notifications.scheduled.containsKey(_tomorrowId), isFalse);
    });

    test('a day that is not tomorrow plans nothing', () async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);

      await controllerOf(container).sync(
        pace(),
        texts,
        tomorrowTargetKcal: 2000,
        tomorrowDay: DateTime(2026, 11, 14),
      );
      await controllerOf(container)
          .sync(pace(), texts, tomorrowTargetKcal: 2000, tomorrowDay: _today);

      expect(notifications.scheduled.containsKey(_tomorrowId), isFalse);
    });

    test('a day that is tomorrow plans its day start', () async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);

      await controllerOf(
        container,
      ).sync(pace(), texts, tomorrowTargetKcal: 2000, tomorrowDay: _tomorrow);

      expect(
        notifications.scheduled[_tomorrowId]!.at,
        DateTime(2026, 11, 13, 6),
      );
    });

    test(
      'a day that is not tomorrow keeps a pending notice for tomorrow',
      () async {
        final notifications = FakeLocalNotifications();
        final container = containerWith(notifications: notifications);
        final controller = controllerOf(container);
        await controller.sync(pace(), texts, tomorrowTargetKcal: 2000);

        await controller.sync(
          pace(),
          texts,
          tomorrowTargetKcal: 1500,
          tomorrowDay: DateTime(2026, 11, 14),
        );

        expect(notifications.scheduled[_tomorrowId]!.title, 'free 500');
      },
    );

    test('loading keeps a pending notice only when it is planned for '
        'tomorrow', () async {
      final notifications = FakeLocalNotifications();
      final preferences = MemoryAppPreferences(
        initialInts: {_markerKey: 1},
        initialStrings: {_onKey: 'set', _tomorrowKey: '2026-11-11'},
      );
      final container = containerWith(
        notifications: notifications,
        preferences: preferences,
      );
      notifications.scheduled[_tomorrowId] = (
        at: DateTime(2026, 11, 12, 6),
        title: 'stale',
        payload: diaryPaceChannelId,
      );

      await controllerOf(container).sync(pace(), texts, tomorrowLoading: true);

      expect(notifications.scheduled.containsKey(_tomorrowId), isFalse);
      expect(preferences.getStringSync(_tomorrowKey), isNull);
    });

    test(
      'loading keeps a pending notice that the stored day names tomorrow',
      () async {
        final notifications = FakeLocalNotifications();
        final preferences = MemoryAppPreferences(
          initialInts: {_markerKey: 1},
          initialStrings: {_onKey: 'set', _tomorrowKey: '2026-11-13'},
        );
        final container = containerWith(
          notifications: notifications,
          preferences: preferences,
        );
        notifications.scheduled[_tomorrowId] = (
          at: DateTime(2026, 11, 13, 6),
          title: 'pending',
          payload: diaryPaceChannelId,
        );

        await controllerOf(container)
            .sync(pace(), texts, tomorrowLoading: true);

        expect(notifications.scheduled[_tomorrowId]!.title, 'pending');
      },
    );
  });

  group('sync while today loads', () {
    // 0:30 on the day the +50 notice is for.
    final earlyToday = DateTime(2026, 11, 13, 0, 30);
    final tomorrowAt = DateTime(2026, 11, 13, 6);

    /// Today's notices are planned for the day [earlyToday] is on, and a
    /// +50 notice planned yesterday for today is pending.
    Future<
      ({FakeLocalNotifications notifications, ProviderContainer container})
    >
    held({bool noticesOn = true}) async {
      now = earlyToday;
      final notifications = FakeLocalNotifications();
      final preferences = MemoryAppPreferences(
        initialInts: {_markerKey: 1},
        initialStrings: {if (noticesOn) _onKey: 'set'},
      );
      final container = containerWith(
        notifications: notifications,
        preferences: preferences,
      );
      await controllerOf(container).sync(pace(day: _tomorrow), texts);
      notifications.scheduled[_tomorrowId] = (
        at: tomorrowAt,
        title: 'held',
        payload: diaryPaceChannelId,
      );
      await preferences.setString(_tomorrowKey, '2026-11-13');
      return (notifications: notifications, container: container);
    }

    Set<int> todays(FakeLocalNotifications notifications) => {
      for (final meal in MealType.sectionOrder)
        if (notifications.scheduled.containsKey(_id(meal))) _id(meal),
    };

    test(
      'keeps the +50 notice for today and the pending notices of today',
      () async {
        final (:notifications, :container) = await held();
        final before = todays(notifications);
        expect(before, isNotEmpty);

        await controllerOf(container).sync(
          null,
          texts,
          tomorrowTargetKcal: 1500,
          tomorrowDay: DateTime(2026, 11, 14),
          todayLoading: true,
        );

        expect(notifications.scheduled[_tomorrowId]!.title, 'held');
        expect(todays(notifications), before);
      },
    );

    test('keeps the pending notices of today and plans tomorrow anew when '
        'the +50 notice is for tomorrow', () async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      final controller = controllerOf(container);
      await controller.sync(pace(), texts, tomorrowTargetKcal: 2000);
      final before = todays(notifications);
      expect(before, isNotEmpty);

      await controller.sync(
        null,
        texts,
        tomorrowTargetKcal: 1200,
        todayLoading: true,
      );

      expect(todays(notifications), before);
      expect(notifications.scheduled[_tomorrowId]!.title, 'free 300');
    });

    test('cancels them all when the notices are off', () async {
      final (:notifications, :container) = await held();
      await controllerOf(container).setEnabled(enabled: false);

      await controllerOf(container).sync(null, texts, todayLoading: true);

      expect(notifications.scheduled, isEmpty);
    });

    test(
      'cancels the +50 notice and plans +0 once the pace is known',
      () async {
        final (:notifications, :container) = await held();
        notifications.scheduled.remove(_id(MealType.breakfast));

        await controllerOf(container).sync(pace(day: _tomorrow), texts);

        expect(notifications.scheduled.containsKey(_tomorrowId), isFalse);
        expect(
          notifications.scheduled[_id(MealType.breakfast)]!.at,
          tomorrowAt,
        );
      },
    );

    test('cancels the +50 notice for today on a pause day, and plans the '
        'one for the day after', () async {
      final (:notifications, :container) = await held();

      await controllerOf(container).sync(
        null,
        texts,
        tomorrowTargetKcal: 1500,
        tomorrowDay: DateTime(2026, 11, 14),
      );

      expect(todays(notifications), isEmpty);
      final notice = notifications.scheduled[_tomorrowId]!;
      expect(notice.at, DateTime(2026, 11, 14, 6));
      expect(notice.title, 'free 375');
    });

    test('cancels the +50 notice for today on a pause day', () async {
      final (:notifications, :container) = await held();

      await controllerOf(container).sync(null, texts);

      expect(notifications.scheduled, isEmpty);
    });
  });

  group('sync with a pace of another day', () {
    final yesterday = DateTime(2026, 11, 11);

    Future<
      ({FakeLocalNotifications notifications, ProviderContainer container})
    >
    planned({bool noticesOn = true}) async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(
        notifications: notifications,
        noticesOn: noticesOn,
      );
      await controllerOf(container)
          .sync(pace(), texts, tomorrowTargetKcal: 2000);
      return (notifications: notifications, container: container);
    }

    test('keeps the +50 notice and the pending notices of today', () async {
      final (:notifications, :container) = await planned();
      final before = Map.of(notifications.scheduled);
      expect(before.containsKey(_tomorrowId), isTrue);
      expect(before.length, greaterThan(1));

      await controllerOf(container)
          .sync(pace(day: yesterday), texts, tomorrowTargetKcal: 2000);

      expect(notifications.scheduled, before);
    });

    test('cancels them all while the notices are off', () async {
      final (:notifications, :container) = await planned();
      await controllerOf(container).setEnabled(enabled: false);

      await controllerOf(container).sync(pace(day: yesterday), texts);

      expect(notifications.scheduled, isEmpty);
    });

    test('cancels them all while the pace marker is off', () async {
      final notifications = FakeLocalNotifications();
      final preferences = MemoryAppPreferences(
        initialInts: {_markerKey: 1},
        initialStrings: {_onKey: 'set'},
      );
      final container = containerWith(
        notifications: notifications,
        preferences: preferences,
      );
      await controllerOf(container)
          .sync(pace(), texts, tomorrowTargetKcal: 2000);
      await container
          .read(diaryPaceMarkerControllerProvider.notifier)
          .show(visible: false);

      await controllerOf(container).sync(pace(day: yesterday), texts);

      expect(notifications.scheduled, isEmpty);
    });
  });

  group('debugShowSoon', () {
    Future<_RecordingNotifications> show(
      DiaryPaceDay day, {
      DateTime? at,
    }) async {
      final notifications = _RecordingNotifications();
      final clock = at ?? now;
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
          clockProvider.overrideWithValue(() => clock),
          localNotificationsProvider.overrideWithValue(notifications),
        ],
      );
      addTearDown(container.dispose);
      container.listen(diaryPaceNotificationControllerProvider, (_, _) {});
      await container
          .read(diaryPaceNotificationControllerProvider.notifier)
          .debugShowSoon(day, texts);
      return notifications;
    }

    test('shows in five seconds on its own id and channel, and asks for the '
        'permission', () async {
      final notifications = await show(pace());

      final notice = notifications.scheduled[_debugId]!;
      expect(notice.at, now.add(const Duration(seconds: 5)));
      expect(notice.payload, diaryPaceChannelId);
      expect(notifications.channelIds[_debugId], diaryPaceChannelId);
      expect(notifications.permissionRequests, 1);
      expect(notifications.scheduled.length, 1);
    });

    test('names what the marker stands ahead of the kcal eaten', () async {
      // 12:00 is in lunch's part: 60 % of 2000 are due.
      final nothingEaten = await show(pace());
      final someEaten = await show(pace(eaten: 500));

      expect(nothingEaten.scheduled[_debugId]!.title, 'free 1200');
      expect(someEaten.scheduled[_debugId]!.title, 'free 700');
    });

    test('rounds the kcal', () async {
      final notifications = await show(pace(target: 1999, eaten: 0.4));

      // 0.6 * 1999 - 0.4 = 1199.0
      expect(notifications.scheduled[_debugId]!.title, 'free 1199');
    });

    test('never goes below 0 kcal', () async {
      final notifications = await show(pace(eaten: 1500));

      expect(notifications.scheduled[_debugId]!.title, 'free 0');
    });

    test('is 0 kcal before the day starts', () async {
      final notifications = await show(pace(), at: DateTime(2026, 11, 12, 5));

      expect(notifications.scheduled[_debugId]!.title, 'free 0');
    });

    test('points at the macro only once something is eaten', () async {
      final eaten = await show(pace(eaten: 100, macro: DiaryPaceMacro.fat));
      final nothing = await show(pace(macro: DiaryPaceMacro.fat));

      expect(eaten.bodies[_debugId], 'fat');
      expect(nothing.bodies[_debugId], '');
    });
  });
}
