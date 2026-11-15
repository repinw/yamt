import 'dart:async';

import 'package:alarm/alarm.dart';

/// Rings alarms on Android the way an alarm clock does: the system's alarm
/// clock arms the alarm, and when it is due a service plays the device's
/// alarm tone on the alarm stream itself, with a notification to stop it.
/// Unlike a notification's own sound, this also rings on a phone set to
/// vibrate or silent and while a paired watch mutes the app's notifications
/// on the phone.
class AndroidAlarmClock {
  /// Creates the alarm clock.
  new();

  late final Future<void> _ready = _initialize();
  final _limited = <int>{};
  Duration _ringLimit = const Duration(minutes: 10);

  Future<void> _initialize() async {
    await Alarm.init();
    Alarm.ringing.listen((ringing) {
      for (final alarm in ringing.alarms) {
        if (!_limited.add(alarm.id)) continue;
        // Nobody may be in the kitchen: stop after the limit, as a
        // notification's timeout did.
        unawaited(Future<void>.delayed(_ringLimit, () => Alarm.stop(alarm.id)));
      }
    });
  }

  /// Arms the alarm [id] for [at]; replaces one with the same id. It rings
  /// until [stopLabel] is tapped, [stop] is called or [ringLimit] passes.
  Future<void> set({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required String stopLabel,
    required Duration ringLimit,
  }) async {
    await _ready;
    _ringLimit = ringLimit;
    // Setting it again stops it first, and the new one may never arm: an
    // alarm armed for this second stays as it is.
    final current = await Alarm.getAlarm(id);
    if (current != null &&
        current.dateTime.millisecondsSinceEpoch ~/ 1000 ==
            at.millisecondsSinceEpoch ~/ 1000) {
      return;
    }
    _limited.remove(id);
    final armed = await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: at,
        // Without an audio path it plays the device's alarm tone.
        volumeSettings: const VolumeSettings.fixed(),
        notificationSettings: NotificationSettings(
          title: title,
          body: body,
          stopButton: stopLabel,
          icon: 'ic_notification',
        ),
        warningNotificationOnKill: false,
        // A cook timer is no alarm clock app: no screen over the lock.
        androidFullScreenIntent: false,
        allowAlarmOverlap: true,
        // A swiped-away app still rings its timers.
        androidStopAlarmOnTermination: false,
        payload: payload,
      ),
    );
    if (!armed) throw StateError('The alarm $id was not set.');
  }

  /// Stops the alarm [id], set or ringing.
  Future<void> stop(int id) async {
    await _ready;
    _limited.remove(id);
    await Alarm.stop(id);
  }

  /// The alarms set, by id, with when they ring: ahead, or ringing once it
  /// passed. An alarm that was stopped or rang to its end is gone.
  Future<Map<int, DateTime>> alarms() async {
    await _ready;
    return {
      for (final alarm in await Alarm.getAlarms()) alarm.id: alarm.dateTime,
    };
  }
}
