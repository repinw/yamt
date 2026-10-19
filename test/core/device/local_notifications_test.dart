import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/local_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var enabled = false;
  var channels = <Map<String, Object?>>[];
  bool? settingsOpened = true;

  setUp(() {
    calls.clear();
    enabled = false;
    channels = [];
    settingsOpened = true;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'initialize' => true,
            'areNotificationsEnabled' => enabled,
            'getNotificationChannels' => channels,
            'openAppNotificationSettings' => settingsOpened,
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
    final notifications = PluginLocalNotifications();
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

  test('pendingIds and cancel use the plugin ids', () async {
    final notifications = PluginLocalNotifications();

    expect(await notifications.pendingIds(), [7]);
    await notifications.cancel(7);

    expect(calls.last.method, 'cancel');
    expect((calls.last.arguments as Map)['id'], 7);
  });

  test('taps start with the notification that launched the app', () async {
    final notifications = PluginLocalNotifications();

    expect(await notifications.taps.first, 'plan-day');
  });

  test('areAllowed reads the app switch and the channel', () async {
    final notifications = PluginLocalNotifications();
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
    final notifications = PluginLocalNotifications();

    await notifications.openSettings();
    expect(calls.last.method, 'openAppNotificationSettings');

    settingsOpened = false;
    await expectLater(notifications.openSettings(), throwsStateError);
  });
}
