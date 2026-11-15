import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yamt/core/device/local_notifications.dart';

/// The id of the countdown to the alarm [id]: its own, so cancelling it
/// never touches the notification the alarm rings with.
int alarmCountdownId(int id) => id + (1 << 30);

/// A silent notification on [channel] that counts down to [at] and leaves
/// when the alarm rings; the user cannot swipe it away. Null once [at] is
/// not after [now].
AndroidNotificationDetails? alarmCountdownDetails(
  NotificationChannel channel,
  DateTime at,
  DateTime now,
) {
  final left = at.difference(now);
  if (left <= Duration.zero) return null;
  return AndroidNotificationDetails(
    channel.id,
    channel.name,
    importance: Importance.low,
    priority: Priority.low,
    silent: true,
    ongoing: true,
    when: at.millisecondsSinceEpoch,
    usesChronometer: true,
    chronometerCountDown: true,
    timeoutAfter: left.inMilliseconds,
  );
}
