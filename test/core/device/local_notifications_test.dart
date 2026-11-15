import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/android_alarm_clock.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/device/plugin_local_notifications.dart';

/// Keeps the alarms in memory instead of the device's alarm clock.
class _FakeAlarmClock implements AndroidAlarmClock {
  final armed = <int, DateTime>{};
  final sets = <Map<String, Object>>[];

  @override
  Future<void> set({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required String stopLabel,
    required Duration ringLimit,
  }) async {
    armed[id] = at;
    sets.add({
      'id': id,
      'at': at,
      'title': title,
      'body': body,
      'payload': payload,
      'stopLabel': stopLabel,
      'ringLimit': ringLimit,
    });
  }

  @override
  Future<void> stop(int id) async => armed.remove(id);

  @override
  Future<Map<int, DateTime>> alarms() async => {...armed};
}

const AlarmStyle _alarm = (
  stopLabel: 'Stopp',
  countdown: (id: 'cook_timer_countdown', name: 'Laufende Timer'),
  countdownTitle: 'Nudeln läuft',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var enabled = false;
  var channels = <Map<String, Object?>>[];
  bool? settingsOpened = true;
  var exactRefused = false;
  var exactAllowed = true;
  var active = <Map<String, Object?>>[];
  late _FakeAlarmClock clock;
  PluginLocalNotifications notificationsUnderTest() =>
      PluginLocalNotifications(alarmClock: clock);

  setUp(() {
    clock = _FakeAlarmClock();
    calls.clear();
    enabled = false;
    channels = [];
    settingsOpened = true;
    exactRefused = false;
    exactAllowed = true;
    active = [];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'zonedSchedule' && exactRefused) {
            final mode =
                ((call.arguments as Map)['platformSpecifics']!
                    as Map)['scheduleMode'];
            if (mode == 'exactAllowWhileIdle') {
              throw PlatformException(code: 'exact_armednot_permitted');
            }
          }
          return switch (call.method) {
            'initialize' => true,
            'areNotificationsEnabled' => enabled,
            'getNotificationChannels' => channels,
            'openAppNotificationSettings' => settingsOpened,
            'canScheduleExactNotifications' => exactAllowed,
            'requestExactAlarmsPermission' => exactAllowed,
            'getActiveNotifications' => active,
            'pendingNotificationRequests' => [
              {'id': 7, 'title': 't', 'body': 'b', 'payload': 'p'},
            ],
            'getNotificationAppLaunchDetails' => {
              'notificationLaunchedApp': true,
              'notificationResponse': {
                'notificationResponseType': 0,
                'payload': 'plan-day',
              },
            },
            _ => null,
          };
        });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
  });

  test('schedule sends the instant in UTC on its channel, inexact', () async {
    final notifications = notificationsUnderTest();
    final at = DateTime(2099, 1, 1, 17);

    await notifications.schedule(
      id: 7,
      at: at,
      channel: (id: 'plan_shortage', name: 'Fehlende Zutaten'),
      title: 'Für morgen fehlen 2 Zutaten',
      body: 'Auf die Einkaufsliste?',
      payload: 'plan-day',
    );

    expect(calls.first.method, 'initialize');
    final args = (calls.last.arguments as Map).cast<String, Object?>();
    final specifics = (args['platformSpecifics']! as Map)
        .cast<String, Object?>();
    expect(calls.last.method, 'zonedSchedule');
    expect(args['id'], 7);
    expect(args['payload'], 'plan-day');
    expect(args['timeZoneName'], 'Etc/UTC');
    expect(DateTime.parse('${args['scheduledDateTimeISO8601']}'), at.toUtc());
    expect(specifics['channelId'], 'plan_shortage');
    expect(specifics['channelName'], 'Fehlende Zutaten');
    expect(specifics['scheduleMode'], 'inexactAllowWhileIdle');
  });

  Future<void> scheduleOne(
    PluginLocalNotifications notifications, {
    bool exact = false,
    AlarmStyle? alarm,
  }) => notifications.schedule(
    id: 7,
    at: DateTime(2099, 1, 1, 17),
    channel: (id: 'cook_timer', name: 'Timer'),
    title: 't',
    body: 'b',
    payload: 'p',
    exact: exact,
    alarm: alarm,
  );

  List<MethodCall> scheduleCalls() =>
      calls.where((call) => call.method == 'zonedSchedule').toList();

  String? modeOf(MethodCall call) =>
      ((call.arguments as Map)['platformSpecifics']! as Map)['scheduleMode']
          as String?;

  Map<String, Object?> specificsOf(MethodCall call) =>
      ((call.arguments as Map)['platformSpecifics']! as Map)
          .cast<String, Object?>();

  test('an alarm on Android rings through the alarm clock and counts down '
      'silently in the tray', () async {
    final at = DateTime.now().add(const Duration(minutes: 5));
    await notificationsUnderTest().schedule(
      id: 7,
      at: at,
      channel: (id: 'cook_timer', name: 'Timer'),
      title: 't',
      body: 'b',
      payload: 'p',
      alarm: _alarm,
    );

    expect(scheduleCalls(), isEmpty);
    expect(clock.sets.single, {
      'id': 7,
      'at': at,
      'title': 't',
      'body': 'b',
      'payload': 'p',
      'stopLabel': 'Stopp',
      'ringLimit': alarmRingLimit,
    });
    expect(alarmRingLimit, const Duration(minutes: 10));
    final show = calls.singleWhere((call) => call.method == 'show');
    final args = (show.arguments as Map).cast<String, Object?>();
    expect(args['id'], 7 + (1 << 30));
    expect(args['payload'], 'p');
    final specifics = specificsOf(show);
    expect(specifics['channelId'], 'cook_timer_countdown');
    expect(specifics['channelName'], 'Laufende Timer');
    expect(specifics['importance'], Importance.low.value);
    expect(specifics['silent'], isTrue);
    expect(specifics['ongoing'], isTrue);
    expect(specifics['usesChronometer'], isTrue);
    expect(specifics['chronometerCountDown'], isTrue);
    expect(specifics['when'], at.millisecondsSinceEpoch);
    expect(specifics['timeoutAfter'], isA<int>());
  });

  test('an alarm that is due shows no countdown', () async {
    await notificationsUnderTest().schedule(
      id: 8,
      at: DateTime.now().subtract(const Duration(seconds: 1)),
      channel: (id: 'cook_timer', name: 'Timer'),
      title: 't',
      body: 'b',
      payload: 'p',
      alarm: _alarm,
    );

    expect(clock.sets.single['id'], 8);
    expect(calls.where((call) => call.method == 'show'), isEmpty);
  });

  test('alarms ahead are pending, due ones ring and show as active; cancel '
      'stops the alarm and its countdown', () async {
    final notifications = notificationsUnderTest();
    clock.armed[200000001] = DateTime.now().add(const Duration(hours: 1));
    clock.armed[200000002] = DateTime.now().subtract(
      const Duration(minutes: 1),
    );

    expect(await notifications.pendingIds(), [7, 200000001]);
    expect(await notifications.activeIds(), [200000002]);

    await notifications.cancel(200000002);

    expect(clock.armed.keys, [200000001]);
    final cancelled = [
      for (final call in calls)
        if (call.method == 'cancel') (call.arguments as Map)['id'],
    ];
    expect(cancelled, [200000002, 200000002 + (1 << 30)]);
  });

  test('a schedule without alarm sends the ordinary notification', () async {
    await scheduleOne(notificationsUnderTest());

    final specifics = specificsOf(scheduleCalls().single);
    expect(specifics['importance'], Importance.defaultImportance.value);
    expect(specifics['audioAttributesUsage'], isNot(4));
    expect(specifics['category'], isNull);
    expect(specifics['sound'], isNull);
    expect(specifics['additionalFlags'], anyOf(isNull, isEmpty));
    expect(specifics['vibrationPattern'], isNull);
    expect(specifics['timeoutAfter'], isNull);
  });

  test('an alarm sounds on iOS with the app open', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();

    await scheduleOne(notificationsUnderTest(), alarm: _alarm);

    final darwin =
        ((scheduleCalls().single.arguments as Map)['platformSpecifics'] as Map)
            .cast<String, Object?>();
    expect(darwin['presentSound'], isTrue);
    expect(darwin['presentBanner'], isTrue);
    expect(darwin['presentList'], isTrue);
  });

  test('without alarm iOS keeps the default presentation', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();

    await scheduleOne(notificationsUnderTest());

    final darwin =
        ((scheduleCalls().single.arguments as Map)['platformSpecifics'] as Map)
            .cast<String, Object?>();
    expect(darwin['presentSound'], isNot(false));
    expect(darwin['interruptionLevel'], isNull);
  });

  test('activeIds lists the shown notifications and drops null ids', () async {
    active = [
      {'id': 200000001, 'channelId': 'cook_timer_alarm'},
      {'id': null, 'channelId': 'x'},
      {'id': 5, 'channelId': 'x'},
    ];

    expect(await notificationsUnderTest().activeIds(), [200000001, 5]);
    expect(calls.last.method, 'getActiveNotifications');
  });

  test('an exact schedule uses the exact alarm mode', () async {
    await scheduleOne(notificationsUnderTest(), exact: true);

    expect(scheduleCalls().map(modeOf), ['exactAllowWhileIdle']);
  });

  test('a refused exact alarm is scheduled again inexact', () async {
    exactRefused = true;

    await scheduleOne(notificationsUnderTest(), exact: true);

    expect(scheduleCalls().map(modeOf), [
      'exactAllowWhileIdle',
      'inexactAllowWhileIdle',
    ]);
  });

  test('an inexact schedule passes the exception on', () async {
    final notifications = notificationsUnderTest();
    // Inexact never asks for the exact mode; fail it by hand instead.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'zonedSchedule') {
            throw PlatformException(code: 'boom');
          }
          return call.method == 'initialize' ? true : null;
        });

    await expectLater(
      scheduleOne(notifications),
      throwsA(isA<PlatformException>()),
    );
  });

  test(
    'canScheduleExact and requestExactAlarms return the plugin answer',
    () async {
      final notifications = notificationsUnderTest();

      expect(await notifications.canScheduleExact(), isTrue);
      exactAllowed = false;
      expect(await notifications.canScheduleExact(), isFalse);
      expect(await notifications.requestExactAlarms(), isFalse);
      expect(calls.last.method, 'requestExactAlarmsPermission');
    },
  );

  test('pendingIds and cancel use the plugin ids', () async {
    final notifications = notificationsUnderTest();

    expect(await notifications.pendingIds(), [7]);
    await notifications.cancel(7);

    final cancel = calls.firstWhere((call) => call.method == 'cancel');
    expect((cancel.arguments as Map)['id'], 7);
  });

  test('taps start with the notification that launched the app', () async {
    final notifications = notificationsUnderTest();

    expect(await notifications.taps.first, 'plan-day');
  });

  test('areAllowed reads the app switch and the channel', () async {
    final notifications = notificationsUnderTest();
    Map<String, Object?> channel(int importance) => {
      'id': 'plan_shortage',
      'name': 'Fehlende Zutaten',
      'importance': importance,
      'showBadge': true,
      'bypassDnd': false,
      'playSound': true,
      'enableLights': false,
      'enableVibration': true,
      'ledColor': 0,
    };

    expect(await notifications.areAllowed('plan_shortage'), isFalse);
    enabled = true;
    // Not created yet: nothing scheduled on it so far.
    expect(await notifications.areAllowed('plan_shortage'), isTrue);
    channels = [channel(Importance.defaultImportance.value)];
    expect(await notifications.areAllowed('plan_shortage'), isTrue);
    channels = [channel(Importance.none.value)];
    expect(await notifications.areAllowed('plan_shortage'), isFalse);
    expect(await notifications.areAllowed('other'), isTrue);
  });

  test('openSettings opens them and throws when it cannot', () async {
    final notifications = notificationsUnderTest();

    await notifications.openSettings();
    expect(calls.last.method, 'openAppNotificationSettings');

    settingsOpened = false;
    await expectLater(notifications.openSettings(), throwsStateError);
  });
}
