import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/application/inventory_shopping_suggestions.dart';
import 'package:yamt/features/inventory/domain/plan_shortage_reminders.dart';
import 'package:yamt/features/inventory/presentation/controllers/plan_shortage_reminder_controller.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';

import '../../../../helpers/fake_local_notifications.dart';
import '../../../../helpers/memory_app_preferences.dart';

class _AskingNotifications extends FakeLocalNotifications {
  final answer = Completer<bool>();

  @override
  Future<bool> requestPermission() {
    permissionRequests++;
    return answer.future;
  }
}

class _FailingRequestNotifications extends FakeLocalNotifications {
  @override
  Future<bool> requestPermission() async => throw StateError('no dialog');
}

class _CheckingNotifications extends FakeLocalNotifications {
  new(this._check);

  final Future<bool> Function() _check;

  @override
  Future<bool> areAllowed(String channelId) => _check();
}

class _FailingOncePreferences extends MemoryAppPreferences {
  bool _failed = false;

  @override
  Future<bool> setString(String key, String value) async {
    if (!_failed) {
      _failed = true;
      throw StateError('disk full');
    }
    return await super.setString(key, value);
  }
}

void main() {
  // The allowed check listens for the app returning to the foreground.
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 18, 12);
  final tomorrow = DateTime(2026, 10, 19);
  final texts = (
    channelName: 'Fehlende Zutaten',
    title: (int count) => '$count fehlen',
    body: 'Auf die Liste?',
  );

  ShoppingPlanNeedGroup group(DateTime day, List<String> names) => (
    day: day,
    mealType: MealType.dinner,
    needs: [
      for (final name in names)
        ShoppingPlanNeed(
          name: name,
          day: day,
          mealType: MealType.dinner,
          amount: null,
          inMilliliters: false,
          isPartial: false,
        ),
    ],
  );

  ProviderContainer containerWith({
    MemoryAppPreferences? preferences,
    List<ShoppingPlanNeedGroup> groups = const [],
    Error? groupsError,
    LocalNotifications? notifications,
  }) {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          preferences ?? MemoryAppPreferences(),
        ),
        clockProvider.overrideWithValue(() => now),
        inventoryShoppingPlanNeedGroupsProvider.overrideWith(
          (ref) async => groupsError == null ? groups : throw groupsError,
        ),
        localNotificationsProvider.overrideWithValue(
          notifications ?? FakeLocalNotifications(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts on at 17:00 and keeps the saved choices', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences: preferences);
    final controller = container.read(
      planShortageReminderControllerProvider.notifier,
    );

    expect(
      container.read(planShortageReminderControllerProvider).enabled,
      isTrue,
    );
    expect(
      container.read(planShortageReminderControllerProvider).minuteOfDay,
      17 * 60,
    );

    await controller.setEnabled(enabled: false);
    await controller.setMinuteOfDay(18 * 60 + 15);
    await controller.quietDay(DateTime(2026, 10, 17));
    await controller.quietDay(DateTime(2026, 10, 20, 9));

    final reread = containerWith(preferences: preferences)
        .read(planShortageReminderControllerProvider);
    expect(reread.enabled, isFalse);
    expect(reread.minuteOfDay, 18 * 60 + 15);
    // The past day is dropped with the next write.
    expect(reread.quietDays, {DateTime(2026, 10, 20)});
  });

  test('plans one reminder per plan day with missing ingredients', () async {
    final container = containerWith(
      groups: [
        group(tomorrow, ['Milch', 'Reis']),
        group(DateTime(2026, 10, 21), ['Ei']),
      ],
    );

    expect(await container.read(planShortageReminderPlanProvider.future), [
      (day: tomorrow, at: DateTime(2026, 10, 18, 17), count: 2),
      (day: DateTime(2026, 10, 21), at: DateTime(2026, 10, 20, 17), count: 1),
    ]);
  });

  test('plans none while the reminder is off', () async {
    final container = containerWith(
      preferences: MemoryAppPreferences(
        initialStrings: {'plan_shortage_reminder_off_v1': 'set'},
      ),
      groups: [
        group(tomorrow, ['Milch']),
      ],
    );

    expect(
      await container.read(planShortageReminderPlanProvider.future),
      isEmpty,
    );
  });

  test('sync schedules the reminders, cancels stale ones, asks once', () async {
    final notifications = FakeLocalNotifications();
    notifications.scheduled[planShortageNotificationId(
      DateTime(2026, 10, 25),
    )] = (
      at: DateTime(2026, 10, 24, 17),
      title: 'old',
      payload: 'old',
    );
    notifications.scheduled[7] = (at: now, title: 'other', payload: 'x');
    final container = containerWith(notifications: notifications);
    final controller = container.read(
      planShortageReminderControllerProvider.notifier,
    );
    final reminder = (day: tomorrow, at: DateTime(2026, 10, 18, 17), count: 2);

    await controller.sync([reminder], texts);
    await controller.sync([reminder], texts);

    expect(notifications.permissionRequests, 1);
    expect(
      notifications.scheduled.keys,
      unorderedEquals([7, planShortageNotificationId(tomorrow)]),
    );
    expect(notifications.scheduled[planShortageNotificationId(tomorrow)], (
      at: DateTime(2026, 10, 18, 17),
      title: '2 fehlen',
      payload: planShortageReminderPayload(tomorrow),
    ));
  });

  test('sync without reminders asks for no permission', () async {
    final notifications = FakeLocalNotifications();
    final container = containerWith(notifications: notifications);

    await container
        .read(planShortageReminderControllerProvider.notifier)
        .sync(const [], texts);

    expect(notifications.permissionRequests, 0);
    expect(
      container.read(planShortageReminderControllerProvider).permissionAsked,
      isFalse,
    );
  });

  test('turning the reminder on asks for the permission again', () async {
    final notifications = FakeLocalNotifications();
    final container = containerWith(notifications: notifications);
    final controller = container.read(
      planShortageReminderControllerProvider.notifier,
    );

    await controller.setEnabled(enabled: false);
    await controller.setEnabled(enabled: true);

    expect(notifications.permissionRequests, 1);
  });

  test('a failed sync does not stop the next one', () async {
    final notifications = FakeLocalNotifications();
    final container = containerWith(
      preferences: _FailingOncePreferences(),
      notifications: notifications,
    );
    final controller = container.read(
      planShortageReminderControllerProvider.notifier,
    );
    final reminder = (day: tomorrow, at: DateTime(2026, 10, 18, 17), count: 2);

    await controller.sync([reminder], texts);
    await controller.sync([reminder], texts);

    expect(notifications.scheduled.keys, [
      planShortageNotificationId(tomorrow),
    ]);
  });

  test('missingFor reports a failed read instead of nothing missing', () {
    final container = containerWith(groupsError: StateError('offline'));

    expect(
      container
          .read(planShortageReminderControllerProvider.notifier)
          .missingFor(tomorrow),
      throwsStateError,
    );
  });

  test('sync keeps a passed reminder that Android may still hold', () async {
    final notifications = FakeLocalNotifications();
    final id = planShortageNotificationId(tomorrow);
    notifications.scheduled[id] = (
      at: DateTime(2026, 10, 18, 11, 30),
      title: '2 fehlen',
      payload: 'kept',
    );
    final container = containerWith(notifications: notifications);

    await container.read(planShortageReminderControllerProvider.notifier).sync([
      (day: tomorrow, at: DateTime(2026, 10, 18, 11, 30), count: 3),
    ], texts);

    expect(notifications.scheduled[id]?.payload, 'kept');
  });

  test('missingFor lists the needs of one plan day', () async {
    final container = containerWith(
      groups: [
        group(DateTime(2026, 10, 19, 8), ['Milch']),
        group(DateTime(2026, 10, 19, 19), ['Reis']),
        group(DateTime(2026, 10, 20), ['Ei']),
      ],
    );

    final needs = await container
        .read(planShortageReminderControllerProvider.notifier)
        .missingFor(tomorrow);

    expect(needs.map((need) => need.name), ['Milch', 'Reis']);
  });

  const asked = {'plan_shortage_reminder_permission_asked_v1': 'set'};

  Future<bool> blocked({
    required LocalNotifications notifications,
    Map<String, String> strings = asked,
  }) async {
    final container = containerWith(
      preferences: MemoryAppPreferences(initialStrings: strings),
      notifications: notifications,
    );
    final subscription = container.listen(
      planShortageReminderBlockedProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await pumpEventQueue();
    return subscription.read();
  }

  test('the reminder is blocked once asked when the system says no', () async {
    expect(
      await blocked(notifications: FakeLocalNotifications()..allowed = false),
      isTrue,
    );
  });

  test('the reminder is not blocked while the system allows it', () async {
    expect(await blocked(notifications: FakeLocalNotifications()), isFalse);
  });

  test('the reminder is not blocked while it is off', () async {
    expect(
      await blocked(
        strings: {...asked, 'plan_shortage_reminder_off_v1': 'set'},
        notifications: FakeLocalNotifications()..allowed = false,
      ),
      isFalse,
    );
  });

  test('the reminder is not blocked before the app asked', () async {
    expect(
      await blocked(
        strings: const {},
        notifications: FakeLocalNotifications()..allowed = false,
      ),
      isFalse,
    );
  });

  test('the reminder is not blocked while the system checks', () async {
    expect(
      await blocked(
        notifications: _CheckingNotifications(() => Completer<bool>().future),
      ),
      isFalse,
    );
  });

  test('the reminder is not blocked when the check fails', () async {
    expect(
      await blocked(
        notifications: _CheckingNotifications(
          () async => throw StateError('no answer'),
        ),
      ),
      isFalse,
    );
  });

  test('the reminder keeps the last answer while it checks again', () async {
    var checks = 0;
    final container = containerWith(
      preferences: MemoryAppPreferences(initialStrings: asked),
      notifications: _CheckingNotifications(
        () => checks++ == 0 ? Future.value(false) : Completer<bool>().future,
      ),
    );
    final subscription = container.listen(
      planShortageReminderBlockedProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await pumpEventQueue();

    container.invalidate(localNotificationsAllowedProvider);
    await pumpEventQueue();

    expect(checks, 2);
    expect(subscription.read(), isTrue);
  });

  test('turning the reminder on waits for the answer and asks once', () async {
    final notifications = _AskingNotifications();
    final preferences = MemoryAppPreferences(
      initialStrings: {'plan_shortage_reminder_off_v1': 'set'},
    );
    final container = containerWith(
      preferences: preferences,
      notifications: notifications,
    );
    // Settings keep the reminder alive while the system asks.
    final subscription = container.listen(
      planShortageReminderControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      planShortageReminderControllerProvider.notifier,
    );

    final first = controller.setEnabled(enabled: true);
    await pumpEventQueue();
    // A second tap while the system asks.
    await controller.setEnabled(enabled: true);
    expect(
      container.read(planShortageReminderControllerProvider).enabled,
      isFalse,
    );

    notifications.answer.complete(false);
    await first;
    final settings = container.read(planShortageReminderControllerProvider);
    expect(notifications.permissionRequests, 1);
    expect(settings.enabled, isTrue);
    expect(settings.permissionAsked, isTrue);
    expect(preferences.getStringSync('plan_shortage_reminder_off_v1'), isNull);
  });

  test('a failed permission request does not count as asked', () async {
    final container = containerWith(
      notifications: _FailingRequestNotifications(),
    );

    await container
        .read(planShortageReminderControllerProvider.notifier)
        .setEnabled(enabled: true);

    expect(
      container.read(planShortageReminderControllerProvider).permissionAsked,
      isFalse,
    );
  });

  test('openSystemSettings tells whether the settings opened', () async {
    final notifications = FakeLocalNotifications();
    final controller = containerWith(notifications: notifications)
        .read(planShortageReminderControllerProvider.notifier);

    expect(await controller.openSystemSettings(), isTrue);
    notifications.canOpenSettings = false;
    expect(await controller.openSystemSettings(), isFalse);
  });
}
