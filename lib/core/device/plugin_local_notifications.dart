import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:yamt/core/device/alarm_countdown.dart';
import 'package:yamt/core/device/android_alarm_clock.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/utils/log_failure.dart';

const _logName = 'LocalNotifications';

// Android's Notification.FLAG_INSISTENT: sound and vibration repeat until the
// notification goes away.
const _flagInsistent = 4;

// How an alarm shakes: three long pushes and a pause, off first in each pair.
// [_flagInsistent] repeats it as long as it rings.
final _alarmVibration = Int64List.fromList(const [
  0,
  800,
  400,
  800,
  400,
  800,
  1000,
]);

// The device's alarm tone, which Android resolves when it rings.
const _alarmTone = UriAndroidNotificationSound(
  'content://settings/system/alarm_alert',
);

/// Android and iOS, through flutter_local_notifications; alarms on Android
/// through [AndroidAlarmClock].
class PluginLocalNotifications implements LocalNotifications {
  /// Creates the notifications; [plugin] and [alarmClock] are replaced in
  /// tests.
  new({FlutterLocalNotificationsPlugin? plugin, AndroidAlarmClock? alarmClock})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
      _alarmClockOverride = alarmClock;

  final FlutterLocalNotificationsPlugin _plugin;
  final AndroidAlarmClock? _alarmClockOverride;
  late final AndroidAlarmClock _alarmClock =
      _alarmClockOverride ?? AndroidAlarmClock();

  bool get _onAndroid => defaultTargetPlatform == TargetPlatform.android;
  final _taps = StreamController<String>.broadcast();
  late final Future<void> _ready = _initialize();
  late final Future<String?> _launchTap = _ready.then((_) async {
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    return (launch?.didNotificationLaunchApp ?? false) ? payload : null;
  });

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _initialize() async {
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: darwin,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) _taps.add(payload);
      },
    );
  }

  @override
  Future<bool> requestPermission() async {
    await _ready;
    final granted = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _android?.requestNotificationsPermission(),
      TargetPlatform.iOS =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true),
      _ => false,
    };
    return granted ?? false;
  }

  @override
  Future<bool> areAllowed(String channelId) async {
    await _ready;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _android;
        if (android == null) return true;
        if (await android.areNotificationsEnabled() == false) return false;
        // The channel is missing until its first notification shows.
        final channels = await android.getNotificationChannels() ?? const [];
        return channels.every(
          (channel) =>
              channel.id != channelId || channel.importance != Importance.none,
        );
      case TargetPlatform.iOS:
        final permissions = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        return permissions?.isEnabled ?? true;
      case _:
        return true;
    }
  }

  @override
  Future<void> openSettings() async {
    await _ready;
    if (await _plugin.openAppNotificationSettings() == false) {
      throw StateError('No notification settings screen opened.');
    }
  }

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
  }) async {
    await _ready;
    if (alarm != null && _onAndroid) {
      await _alarmClock.set(
        id: id,
        at: at,
        title: title,
        body: body,
        payload: payload,
        stopLabel: alarm.stopLabel,
        ringLimit: alarmRingLimit,
      );
      try {
        final countdown = alarmCountdownDetails(
          alarm.countdown,
          at,
          DateTime.now(),
        );
        if (countdown != null) {
          await _plugin.show(
            id: alarmCountdownId(id),
            title: alarm.countdownTitle,
            body: body,
            notificationDetails: NotificationDetails(android: countdown),
            payload: payload,
          );
        }
      } on Object catch (error, stackTrace) {
        // The alarm rings without it.
        logFailure('No countdown shown.', _logName, error, stackTrace);
      }
      return;
    }
    Future<void> scheduleIn(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      // A fixed instant needs no time zone database: the local DateTime
      // already knows its offset, also across a clock change.
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        android: alarm != null
            ? AndroidNotificationDetails(
                channel.id,
                channel.name,
                importance: Importance.max,
                priority: Priority.high,
                category: AndroidNotificationCategory.alarm,
                audioAttributesUsage: AudioAttributesUsage.alarm,
                sound: _alarmTone,
                vibrationPattern: _alarmVibration,
                additionalFlags: Int32List.fromList(const [_flagInsistent]),
                timeoutAfter: alarmRingLimit.inMilliseconds,
              )
            : AndroidNotificationDetails(channel.id, channel.name),
        iOS: alarm != null
            ? const DarwinNotificationDetails(
                presentSound: true,
                presentBanner: true,
                presentList: true,
              )
            : const DarwinNotificationDetails(),
      ),
      androidScheduleMode: mode,
      payload: payload,
    );
    try {
      await scheduleIn(
        exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on PlatformException catch (error, stackTrace) {
      if (!exact) rethrow;
      // The user can revoke exact alarms any time: late beats never.
      log(
        'Exact alarm refused, scheduling an inexact one.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      await scheduleIn(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  @override
  Future<bool> canScheduleExact() async {
    await _ready;
    // Null on iOS, where every notification is on time.
    return await _android?.canScheduleExactNotifications() ?? true;
  }

  @override
  Future<bool> requestExactAlarms() async {
    await _ready;
    return await _android?.requestExactAlarmsPermission() ?? true;
  }

  @override
  Future<void> cancel(int id) async {
    await _ready;
    await _plugin.cancel(id: id);
    if (!_onAndroid) return;
    await _plugin.cancel(id: alarmCountdownId(id));
    await _alarmClock.stop(id);
  }

  @override
  Future<List<int>> pendingIds() async {
    await _ready;
    final pending = await _plugin.pendingNotificationRequests();
    return [for (final request in pending) request.id, ...await _alarms()];
  }

  @override
  Future<List<int>> activeIds() async {
    await _ready;
    final active = await _plugin.getActiveNotifications();
    // An alarm whose time passed rings until it is stopped.
    return [
      for (final notification in active) ?notification.id,
      ...await _alarms(due: true),
    ];
  }

  // The Android alarms ahead, or the [due] ones.
  Future<Iterable<int>> _alarms({bool due = false}) async {
    if (!_onAndroid) return const [];
    final now = DateTime.now();
    return [
      for (final MapEntry(key: id, value: at)
          in (await _alarmClock.alarms()).entries)
        if (at.isAfter(now) != due) id,
    ];
  }

  @override
  Stream<String> get taps async* {
    final launch = await _launchTap;
    // Every listener gets it: each feature picks its own payloads.
    if (launch != null && launch.isNotEmpty) yield launch;
    yield* _taps.stream;
  }
}
